package com.scrapsquad.fire

import com.badlogic.gdx.ApplicationAdapter
import com.badlogic.gdx.Gdx
import com.badlogic.gdx.InputAdapter
import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.GL20
import com.badlogic.gdx.graphics.OrthographicCamera
import com.badlogic.gdx.graphics.Texture
import com.badlogic.gdx.graphics.g2d.SpriteBatch
import com.badlogic.gdx.graphics.g2d.TextureRegion
import com.badlogic.gdx.graphics.g2d.BitmapFont
import com.badlogic.gdx.graphics.glutils.ShapeRenderer
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.*

class BattleRenderer(private val repository: GameRepository, private val mode: String, private val seed: String, private val zone: Int, private val challenge: String?, private val recover: Boolean = false, private val retreatRecovered: Boolean = false, private val recoveryProgress: (Int) -> Unit = {}, private val recoveryError: (Throwable) -> Unit = {}, private val hud: (JSONObject) -> Unit) : ApplicationAdapter() {
    private lateinit var batch: SpriteBatch
    private lateinit var shapes: ShapeRenderer
    private lateinit var atlas: Texture
    private lateinit var audio: Audio
    private lateinit var font: BitmapFont
    private val camera = OrthographicCamera()
    private var battle = JSONObject()
    @Volatile private var ready = false
    @Volatile private var disposed = false
    val recovering get() = recover && !ready && !disposed
    private val worker = java.util.concurrent.Executors.newSingleThreadExecutor()
    private var restoration: java.util.concurrent.Future<*>? = null
    private val metrics = RenderMetrics()
    @Volatile var paused = false
    private var drag = -1
    private var originX = 0f; private var originY = 0f
    private var moveX = 0.0; private var moveY = 0.0
    private var width = 1f; private var height = 1f
    private var lastHud = -1.0; private var previousKills = 0; private var previousWave = 1
    private var lastHudState = ""
    private var audioPaused = false
    private var lastStrideSequence = -1
    private var lastShotSoundAt = -1.0
    private var lastRunState = "fighting"
    private val seenEffects = mutableSetOf<Int>()
    private data class Print(val x: Double, val y: Double, val born: Double, val rotation: Float)
    private val footprints = ArrayDeque<Print>()
    private val order = listOf("bolt", "tank", "zip", "patch", "nova", "boomer", "glitch", "magnet")
    private val reducedMotion get() = repository.profile.optJSONObject("preferences")?.optBoolean("reducedMotion") ?: false
    override fun create() {
        batch = SpriteBatch(); shapes = ShapeRenderer(); atlas = Texture(Gdx.files.internal("generated/RobotAtlas.png"))
        font = BitmapFont()
        atlas.setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear)
        audio = Audio(repository.profile.optJSONObject("preferences") ?: JSONObject())
        val args = mutableListOf<Pair<String, Any>>("mode" to mode, "seed" to seed, "zone" to zone)
        if (challenge != null) args.add("challenge" to challenge)
        if (recover) {
            restoration = worker.submit {
                try {
                    var restored = repository.restoreBattle(recoveryProgress)
                    if (Thread.currentThread().isInterrupted) return@submit
                    if (retreatRecovered) restored = repository.battleCommand("retreat")
                    Gdx.app.postRunnable { if (!disposed) { battle = restored.getJSONObject("battle"); ready = true; audio.music("battle") } }
                } catch (e: Exception) { if (!Thread.currentThread().isInterrupted && !disposed) recoveryError(e) }
            }
        } else {
            try { battle = repository.beginBattle(*args.toTypedArray()).getJSONObject("battle"); ready = true; audio.music("battle") }
            catch (e: Exception) { recoveryError(e) }
        }
        Gdx.input.inputProcessor = object : InputAdapter() {
            override fun touchDown(x: Int, y: Int, pointer: Int, button: Int): Boolean {
                if (drag != -1) return false
                drag = pointer; originX = x.toFloat(); originY = y.toFloat(); return true
            }
            override fun touchDragged(x: Int, y: Int, pointer: Int): Boolean {
                if (pointer != drag) return false
                val dx = x - originX; val dy = originY - y
                val length = sqrt(dx * dx + dy * dy)
                moveX = if (length > 4) dx / length.toDouble() else 0.0
                moveY = if (length > 4) dy / length.toDouble() else 0.0
                return true
            }
            override fun touchUp(x: Int, y: Int, pointer: Int, button: Int): Boolean {
                if (pointer == drag) { drag = -1; moveX = 0.0; moveY = 0.0 }; return true
            }
            override fun touchCancelled(x: Int, y: Int, pointer: Int, button: Int): Boolean = touchUp(x, y, pointer, button)
        }
    }
    fun action(op: String, id: String? = null) {
        Gdx.app.postRunnable {
            if (!ready || disposed) return@postRunnable
            val values = mutableListOf<Pair<String, Any>>()
            if (id != null) values.add("id" to id)
            if (op == "dash") { values.add("x" to moveX); values.add("y" to moveY) }
            battle = repository.battleCommand(op, *values.toTypedArray()).getJSONObject("battle")
            if (op == "ability" || op == "overdrive") audio.cue(if (op == "overdrive") "overdrive" else "ability")
            lastHud = -1.0
        }
    }
    override fun resize(w: Int, h: Int) {
        // SpriteKit uses logical points. Use Android logical pixels as well so
        // robot and projectile sizes do not shrink on high-density tablets.
        val density = Gdx.graphics.density.coerceAtLeast(1f)
        width = w / density; height = h / density
        camera.setToOrtho(false, width, height)
    }
    private val scale get() = min(width, height) * 1.4f
    private val unit get() = max(.4f, min(1f, scale / 600f))
    private fun x(value: Double) = width / 2 + ((value - battle.getJSONArray("player").getDouble(0)) * scale).toFloat()
    private fun y(value: Double) = height / 2 + ((value - battle.getJSONArray("player").getDouble(1)) * scale).toFloat()
    private fun JSONArray.objects(block: (JSONObject) -> Unit) { for (i in 0 until length()) block(getJSONObject(i)) }
    private fun position(obj: JSONObject) = obj.getJSONArray("position")
    override fun render() {
        val renderStarted = System.nanoTime()
        if (!ready || battle.length() == 0) { Gdx.gl.glClearColor(.063f, .145f, .176f, 1f); Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT); return }
        if (!paused && battle.getString("state") == "fighting") battle = repository.battleCommand("step", "dt" to Gdx.graphics.deltaTime.toDouble(), "x" to moveX, "y" to moveY).getJSONObject("battle")
        val elapsed = battle.getDouble("elapsed")
        val biome = repository.content.getJSONArray("biomes").getJSONObject(battle.getInt("zone"))
        val background = Color.valueOf(biome.getJSONArray("palette").getString(0))
        Gdx.gl.glClearColor(background.r, background.g, background.b, 1f); Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT)
        Gdx.gl.glEnable(GL20.GL_BLEND); Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)
        shapes.projectionMatrix = camera.combined; batch.projectionMatrix = camera.combined
        shapes.begin(ShapeRenderer.ShapeType.Filled)
        shapes.color = Color(1f, 1f, 1f, .04f)
        for (i in -20..40) { val p = i * .1; shapes.rectLine(x(p), y(-2.0), x(p), y(4.0), 1f); shapes.rectLine(x(-2.0), y(p), x(4.0), y(p), 1f) }
        val p = battle.getJSONArray("player"); val px = p.getDouble(0); val py = p.getDouble(1)
        if (lastStrideSequence != battle.getInt("strideSequence")) {
            lastStrideSequence = battle.getInt("strideSequence")
            battle.getJSONArray("footsteps").objects { step ->
                val at = step.getJSONArray("position"); val direction = step.getJSONArray("direction"); val dx = direction.getDouble(0); val dy = direction.getDouble(1); val side = step.getDouble("side")
                footprints.addLast(Print(at.getDouble(0) - dx * .012 - dy * side * .008, at.getDouble(1) - dy * .012 + dx * side * .008, elapsed, ((atan2(dy, dx) - PI / 2) * 180 / PI).toFloat()))
                if (footprints.size > 96) footprints.removeFirst()
            }
        }
        while (footprints.isNotEmpty() && elapsed - footprints.first().born >= 3) footprints.removeFirst()
        footprints.forEach { shapes.color = Color.valueOf(biome.getJSONArray("palette").getString(2)).apply { a = ((1 - (elapsed - it.born) / 3) * .5).toFloat() }; shapes.rect(x(it.x) - 3.5f * unit, y(it.y) - 5.5f * unit, 3.5f * unit, 5.5f * unit, 7 * unit, 11 * unit, 1f, 1f, it.rotation) }
        battle.getJSONArray("warnings").objects { warning -> drawArea(warning.getJSONObject("area"), Color(1f, .25f, .2f, .18f + .2f * (1 - warning.getDouble("remaining") / warning.getDouble("duration")).toFloat())) }
        battle.getJSONArray("strikes").objects { drawArea(it.getJSONObject("area"), Color(.74f, .61f, 1f, .3f)) }
        battle.getJSONArray("enemies").objects { enemy ->
            val point = position(enemy); val ex = x(point.getDouble(0)); var ey = y(point.getDouble(1)); val kind = enemy.getString("kind")
            if (kind == "flying" && !reducedMotion) ey += sin(elapsed * 5).toFloat() * 4
            val radius = (if (kind == "boss") 46 else if (kind == "miniboss") 30 else if (kind == "tank" || kind == "elite") 21 else 13) * unit
            shapes.color = Color.valueOf(if (kind == "repair") "8CAD8A" else if (kind == "shield") "839CC1" else if (kind == "boss") biome.getJSONArray("palette").getString(1) else if (kind == "treasure") "F5B942" else "8B7572")
            if (kind == "burrower") shapes.color.a = if (elapsed.toInt() % 5 < 2) .25f else 1f
            shapes.rect(ex - radius, ey - radius * .9f, radius * 2, radius * 1.8f)
            shapes.color = Color.valueOf("374A4D"); shapes.rect(ex - radius * 1.2f, ey - radius, radius * .65f, radius * .6f); shapes.rect(ex + radius * .55f, ey - radius, radius * .65f, radius * .6f)
            shapes.color = Color.valueOf("FFC88C"); shapes.rect(ex - radius / 2, ey, radius, 4 * unit)
            shapes.color = Color.ORANGE; shapes.rect(ex - radius, ey + radius + 5, radius * 2 * (enemy.getDouble("health") / enemy.getDouble("maxHealth")).toFloat(), 3 * unit)
        }
        battle.getJSONArray("projectiles").objects { val at = position(it); shapes.color = Color.valueOf("FFB66C"); shapes.rect(x(at.getDouble(0)), y(at.getDouble(1)), 14 * unit, 5 * unit) }
        battle.getJSONArray("drones").let { drones -> for (i in 0 until drones.length()) { val at = drones.getJSONArray(i); shapes.color = Color.valueOf("F5B942"); shapes.rect(x(at.getDouble(0)) - 9 * unit, y(at.getDouble(1)) - 6 * unit, 18 * unit, 12 * unit) } }
        battle.getJSONArray("effects").objects { effect ->
            val from = effect.getJSONArray("from"); val to = effect.getJSONArray("to")
            shapes.color = Color.valueOf(if (effect.getString("style") == "arc") "83EAFF" else if (effect.getString("style") == "beam") "BC9BFF" else biome.getJSONArray("palette").getString(2))
            shapes.color.a = min(1f, effect.getDouble("remaining").toFloat() * 3)
            shapes.rectLine(x(from.getDouble(0)), y(from.getDouble(1)), x(to.getDouble(0)), y(to.getDouble(1)), 3 * unit)
            shapes.circle(x(to.getDouble(0)), y(to.getDouble(1)), 7 * unit, 12)
        }
        shapes.end()
        batch.begin()
        val squad = battle.getJSONArray("squad")
        for (i in 0 until squad.length()) {
            val index = order.indexOf(squad.getString(i)).coerceAtLeast(0)
            val region = TextureRegion(atlas, index % 4 * atlas.width / 4, index / 4 * atlas.height / 2, atlas.width / 4, atlas.height / 2)
            val angle = i * PI * 2 / squad.length()
            val rx = x(px + if (i == 0) 0.0 else cos(angle) * .055); val ry = y(py + if (i == 0) 0.0 else sin(angle) * .055)
            val stride = battle.getJSONArray("strides").getJSONObject(i)
            val animated = stride.getBoolean("moving") && !reducedMotion
            val phase = stride.getDouble("distance") / .05 * PI * 2
            val bob = if (animated) abs(sin(phase)).toFloat() * 4 else 0f
            val rotation = if (animated) (sin(phase) * .07 - stride.getJSONArray("direction").getDouble(0) * .08) * 180 / PI else 0.0
            val squash = if (animated) 1 - abs(sin(phase)).toFloat() * .04f else 1f
            val dimension = (if (squad.getString(i) in listOf("tank", "boomer")) 60 else 48) * unit
            batch.draw(region, rx - dimension / 2, ry - dimension / 2 + bob, dimension / 2, dimension / 2, dimension, dimension, 1f, squash, rotation.toFloat())
        }
        val activeEffects = mutableSetOf<Int>()
        battle.getJSONArray("effects").objects { effect ->
            val id = effect.getInt("id"); activeEffects.add(id)
            if (seenEffects.add(id) && effect.getDouble("damage") > 0 && elapsed - lastShotSoundAt >= .09) { audio.cue("weapon"); lastShotSoundAt = elapsed }
            if (effect.getDouble("damage") > 0 && repository.profile.getJSONObject("preferences").getBoolean("damageNumbers")) {
                val to = effect.getJSONArray("to"); font.color = if (effect.getBoolean("critical")) Color.YELLOW else Color.WHITE
                font.color.a = (effect.getDouble("remaining") * 3).toFloat().coerceIn(0f, 1f)
                font.draw(batch, effect.getDouble("damage").toInt().toString(), x(to.getDouble(0)), y(to.getDouble(1)) + 18 * unit)
            }
        }
        seenEffects.retainAll(activeEffects)
        batch.end()
        val enemies = battle.getJSONArray("enemies")
        val bossPresent = (0 until enemies.length()).any { enemies.getJSONObject(it).getString("kind") == "boss" }
        audio.music(if (bossPresent) "boss" else "battle")
        if (paused != audioPaused) { if (paused) audio.pause() else audio.resume(); audioPaused = paused }
        if (battle.getInt("kills") > previousKills) { audio.cue("explosion"); previousKills = battle.getInt("kills") }
        if (battle.getInt("wave") != previousWave) { audio.cue("combo"); previousWave = battle.getInt("wave") }
        val state = battle.getString("state")
        if (state != lastRunState) { if (state == "victory") audio.cue("victory"); lastRunState = state }
        if (lastHud < 0 || elapsed - lastHud >= .1 || state != lastHudState) { lastHud = elapsed; lastHudState = state; hud(JSONObject(battle.toString())) }
        if (!paused && state == "fighting" && elapsed > 2) metrics.record(Gdx.graphics.deltaTime.toDouble(), (System.nanoTime() - renderStarted) / 1000000.0)
    }
    private fun drawArea(area: JSONObject, color: Color) {
        val from = area.getJSONArray("from"); val to = area.getJSONArray("to"); val radius = area.getDouble("radius").toFloat() * scale
        shapes.color = color
        when (area.getString("shape")) {
            "line" -> { shapes.rectLine(x(from.getDouble(0)), y(from.getDouble(1)), x(to.getDouble(0)), y(to.getDouble(1)), radius * 2); shapes.circle(x(from.getDouble(0)), y(from.getDouble(1)), radius, 24); shapes.circle(x(to.getDouble(0)), y(to.getDouble(1)), radius, 24) }
            "ring" -> { val cx = x(to.getDouble(0)); val cy = y(to.getDouble(1)); for (i in 0..63) { val a = i * PI / 32; val b = (i + 1) * PI / 32; shapes.rectLine(cx + cos(a).toFloat() * radius, cy + sin(a).toFloat() * radius, cx + cos(b).toFloat() * radius, cy + sin(b).toFloat() * radius, area.getDouble("thickness").toFloat() * scale * 2) } }
            else -> shapes.circle(x(to.getDouble(0)), y(to.getDouble(1)), radius, 40)
        }
    }
    override fun pause() {
        paused = true; moveX = 0.0; moveY = 0.0; drag = -1
        if (::audio.isInitialized) { audio.pause(); audioPaused = true }
        if (ready && repository.battleJournal.pending()) {
            try { repository.battleCommand("background"); repository.battleJournal.checkpoint() } catch (e: Exception) { recoveryError(e) }
        }
    }
    override fun resume() { if (::audio.isInitialized && !paused) { audio.resume(); audioPaused = false } }
    fun stopRecovery() { restoration?.cancel(true) }
    override fun dispose() { disposed = true; stopRecovery(); worker.shutdownNow(); repository.battleJournal.close(); android.util.Log.i("ScrapRender", metrics.report().toString()); batch.dispose(); shapes.dispose(); atlas.dispose(); audio.dispose(); font.dispose() }
}
