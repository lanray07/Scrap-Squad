package com.scrapsquad.fire

import com.badlogic.gdx.ApplicationAdapter
import com.badlogic.gdx.Gdx
import com.badlogic.gdx.InputAdapter
import com.badlogic.gdx.graphics.Color
import com.badlogic.gdx.graphics.GL20
import com.badlogic.gdx.graphics.OrthographicCamera
import com.badlogic.gdx.graphics.Texture
import com.badlogic.gdx.graphics.Pixmap
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
    private var lastComboTier = 1
    private var lastSynergyCount = 0
    private var lastEvolution = ""
    private var lastEvent = ""
    private var lastPerfectDodges = 0
    private var lastCompletedEvents = 0
    private var shakeAt = -1.0
    private lateinit var strings: Strings
    private var announcement: Triple<String, Color, Double>? = null
    private val seenEffects = mutableSetOf<Int>()
    private val presentation = CombatPresentation()
    private var cosmeticState = JSONObject()
    private val signatureTextures = mutableMapOf<String, List<TextureRegion>>()
    private var baseFontHeight = 15f
    private data class Print(val x: Double, val y: Double, val born: Double, val rotation: Float)
    private val footprints = ArrayDeque<Print>()
    private val order = listOf("bolt", "tank", "zip", "patch", "nova", "boomer", "glitch", "magnet")
    private val reducedMotion get() = repository.profile.optJSONObject("preferences")?.optBoolean("reducedMotion") ?: false
    override fun create() {
        batch = SpriteBatch(); shapes = ShapeRenderer(); atlas = Texture(Gdx.files.internal("generated/RobotAtlas.png"))
        font = BitmapFont()
        baseFontHeight = font.capHeight
        atlas.setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear)
        audio = Audio(repository.profile.optJSONObject("preferences") ?: JSONObject())
        strings = Strings(Gdx.app as android.content.Context).apply { language = repository.profile.getJSONObject("preferences").getString("locale") }
        cosmeticState = CosmeticRepository(Gdx.app as android.content.Context).state()
        cosmeticState.getJSONObject("finishes").keys().forEach { robot ->
            val skin = cosmeticState.getJSONObject("finishes").getJSONObject(robot).optString("skin")
            if (skin.isNotEmpty() && skin !in signatureTextures) signatureTextures[skin] = (0..3).map { frame ->
                val bitmap = android.graphics.Bitmap.createScaledBitmap(SignatureRobotArt.image(skin, frame), 128, 128, true)
                val bytes = java.io.ByteArrayOutputStream().also { bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }.toByteArray()
                bitmap.recycle()
                val pixmap = Pixmap(bytes, 0, bytes.size)
                val texture = Texture(pixmap); pixmap.dispose()
                texture.setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear)
                TextureRegion(texture)
            }
        }
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
            try { battle = repository.battleCommand(op, *values.toTypedArray()).getJSONObject("battle") }
            catch (error: Exception) { stopWithError(error); return@postRunnable }
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
    private fun stopWithError(error: Exception) {
        ready = false; paused = true
        if (::audio.isInitialized) audio.pause()
        recoveryError(error)
    }
    override fun render() {
        val renderStarted = System.nanoTime()
        if (!ready || battle.length() == 0) { Gdx.gl.glClearColor(.063f, .145f, .176f, 1f); Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT); return }
        if (!paused && battle.getString("state") == "fighting") try {
            battle = repository.battleCommand("step", "dt" to Gdx.graphics.deltaTime.toDouble(), "x" to moveX, "y" to moveY).getJSONObject("battle")
        } catch (error: Exception) { stopWithError(error); return }
        val elapsed = battle.getDouble("elapsed")
        val preferences = repository.profile.getJSONObject("preferences")
        if (battle.getInt("kills") > previousKills && preferences.getBoolean("screenShake") && !reducedMotion) shakeAt = elapsed
        val shakeAge = elapsed - shakeAt
        camera.position.x = width / 2 - if (shakeAt >= 0 && shakeAge < .08) (if (shakeAge < .04) shakeAge / .04 * 2 else (1 - (shakeAge - .04) / .04) * 2).toFloat() else 0f
        camera.update()
        fun announce(text: String, color: String) { announcement = Triple(text, Color.valueOf(color), elapsed) }
        if (battle.getInt("wave") > previousWave) announce("${strings.text("momentum.wave")} ${battle.getInt("wave")}", "F5B942")
        val tier = 1 + min(4, battle.getInt("combo") / 8)
        if (tier > lastComboTier) { announce("×$tier ${strings.text("momentum.combo")}", "79D9BA"); audio.cue("combo") }; lastComboTier = tier
        val synergies = battle.getJSONArray("synergies").length()
        if (synergies > lastSynergyCount) announce(strings.text("synergy.activated"), "BA9DEB"); lastSynergyCount = synergies
        val evolution = battle.getString("evolution")
        if (evolution != lastEvolution && evolution.isNotEmpty()) announce(strings.text("evolution.$evolution"), battle.getString("evolutionColor")); lastEvolution = evolution
        if (battle.getInt("perfectDodges") > lastPerfectDodges) announce(strings.text("battle.perfectDodge"), "83EAFF"); lastPerfectDodges = battle.getInt("perfectDodges")
        val event = battle.getString("event")
        if (event != lastEvent && event.isNotEmpty()) announce(strings.text("event.$event"), "F5B942"); lastEvent = event
        if (battle.getInt("completedWaveEvents") > lastCompletedEvents) announce(strings.text("event.complete"), "79D9BA"); lastCompletedEvents = battle.getInt("completedWaveEvents")
        presentation.update(elapsed, battle.getJSONArray("effects"))
        val biome = repository.content.getJSONArray("biomes").getJSONObject(battle.getInt("zone"))
        val background = Color.valueOf(biome.getJSONArray("palette").getString(0))
        Gdx.gl.glClearColor(background.r, background.g, background.b, 1f); Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT)
        Gdx.gl.glEnable(GL20.GL_BLEND); Gdx.gl.glBlendFunc(GL20.GL_SRC_ALPHA, GL20.GL_ONE_MINUS_SRC_ALPHA)
        shapes.projectionMatrix = camera.combined; batch.projectionMatrix = camera.combined
        shapes.begin(ShapeRenderer.ShapeType.Filled)
        shapes.color = Color(1f, 1f, 1f, .04f)
        for (i in -20..40) { val p = i * 60.0 / scale; shapes.rectLine(x(p), y(-1200.0 / scale), x(p), y(2400.0 / scale), 1f); shapes.rectLine(x(-1200.0 / scale), y(p), x(2400.0 / scale), y(p), 1f) }
        shapes.color = Color.valueOf("79D9BA").apply { a = .2f }
        listOf(doubleArrayOf(.07, .07, .93, .07), doubleArrayOf(.93, .07, .93, .93), doubleArrayOf(.93, .93, .07, .93), doubleArrayOf(.07, .93, .07, .07)).forEach { shapes.rectLine(x(it[0]), y(it[1]), x(it[2]), y(it[3]), 2f) }
        shapes.color = Color.valueOf(biome.getJSONArray("palette").getString(1)).apply { a = .18f }
        for (i in 0 until 22) { val w = (14 + i % 4 * 5).toFloat(); shapes.rect(x((i * 137 % 570).toDouble() / scale) - w / 2, y((i * 193 % 780).toDouble() / scale) - 4.5f, w / 2, 4.5f, w, 9f, 1f, 1f, (i * .7 * 180 / PI).toFloat()) }
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
        footprints.forEach { shapes.color = Color.valueOf(if (cosmeticState.getJSONObject("selection").getBoolean("goldenTrails")) "FFD878" else biome.getJSONArray("palette").getString(2)).apply { a = ((1 - (elapsed - it.born) / 3) * .5).toFloat() }; shapes.rect(x(it.x) - 3.5f * unit, y(it.y) - 5.5f * unit, 3.5f * unit, 5.5f * unit, 7 * unit, 11 * unit, 1f, 1f, it.rotation) }
        battle.getJSONArray("warnings").objects { warning ->
            val area = warning.getJSONObject("area"); val alpha = (.4 + .6 * (1 - warning.getDouble("remaining") / warning.getDouble("duration"))).toFloat()
            val border = Color.valueOf(if (warning.getBoolean("boss")) "FF806E" else "FF9500").apply { a = alpha }
            if (area.getString("shape") == "ring") drawArea(area, border)
            else { drawArea(area, Color(1f, .5f, 0f, .16f * alpha)); outlineArea(area, border) }
        }
        battle.getJSONArray("strikes").objects { drawArea(it.getJSONObject("area"), Color(.74f, .61f, 1f, .3f)) }
        battle.getJSONArray("evolutionAreas").objects { drawArea(it, Color.valueOf(battle.getString("evolutionColor")).apply { a = if (it.getString("shape") == "ring") .55f else .0825f }) }
        if (battle.getDouble("overdrive") > 0) ring(x(px), y(py), 42 * unit, 3 * unit, Color.valueOf("79D9BA"))
        if (battle.getDouble("dashRemaining") > 0 || battle.getDouble("perfectDodgeBoost") > 0) ring(x(px), y(py), 34 * unit, 3 * unit, Color.valueOf("83EAFF"))
        battle.getJSONArray("enemies").objects { enemy ->
            val point = position(enemy); val ex = x(point.getDouble(0)); var ey = y(point.getDouble(1)); val kind = enemy.getString("kind")
            if (kind == "flying" && !reducedMotion) ey += sin(elapsed * 5).toFloat() * 4
            val radius = (if (kind == "boss") 46 else if (kind == "miniboss") 30 else if (kind == "tank" || kind == "elite") 21 else 13) * unit
            val alpha = if (kind == "burrower" && elapsed.toInt() % 5 < 2) .25f else 1f
            if (enemy.getInt("id") in battle.getJSONArray("eventIDs").let { ids -> (0 until ids.length()).map { ids.getInt(it) } }) ring(ex, ey, (if (kind == "boss") 54 else 26) * unit, 2 * unit, Color.YELLOW)
            if (kind == "treasure") {
                rounded(ex - 16 * unit, ey - 13 * unit, 32 * unit, 26 * unit, 6 * unit, Color.WHITE)
                rounded(ex - 15 * unit, ey - 12 * unit, 30 * unit, 24 * unit, 5 * unit, Color.valueOf("F5B942"))
                shapes.color = Color.WHITE; shapes.rect(ex - 6 * unit, ey - unit, 12 * unit, 2 * unit); shapes.rect(ex - unit, ey - 6 * unit, 2 * unit, 12 * unit)
            } else {
                for (side in listOf(-1, 1)) rounded(ex + side * radius * .85f - radius * .325f, ey - radius * .9f, radius * .65f, radius * .6f, 3 * unit, Color.valueOf("374A4D").apply { a = alpha })
                if (kind == "boss") {
                    val pattern = battle.getInt("bossPatternIndex"); val count = 2 + pattern % 4
                    for (module in 0 until count) {
                        val angle = module * PI * 2 / count + pattern * .3; val mx = ex + cos(angle).toFloat() * radius; val my = ey + sin(angle).toFloat() * radius
                        shapes.color = Color.valueOf("10252D"); shapes.rect(mx - 9 * unit, my - 12 * unit, 9 * unit, 12 * unit, 18 * unit, 24 * unit, 1f, 1f, (angle * 180 / PI).toFloat())
                        shapes.color = Color.valueOf(biome.getJSONArray("palette").getString(2)); shapes.rect(mx - 8 * unit, my - 11 * unit, 8 * unit, 11 * unit, 16 * unit, 22 * unit, 1f, 1f, (angle * 180 / PI).toFloat())
                    }
                }
                val fill = Color.valueOf(if (kind == "repair") "8CAD8A" else if (kind == "shield") "839CC1" else if (kind == "boss") biome.getJSONArray("palette").getString(1) else "8B7572").apply { a = alpha }
                val border = Color.valueOf(if (kind == "boss") if (enemy.getDouble("health") < enemy.getDouble("maxHealth") / 2) "FF3B30" else biome.getJSONArray("palette").getString(2) else "E4B1A0").apply { a = alpha }
                val stroke = (if (kind == "boss") 4 else 2) * unit
                if (kind == "boss" && battle.getString("bossPattern") in listOf("shockRing", "bombardment", "collapse")) { shapes.color = border; shapes.circle(ex, ey, radius + stroke / 2, 40); shapes.color = fill; shapes.circle(ex, ey, radius - stroke / 2, 40) }
                else { val corner = if (kind == "swarmer") 4 * unit else radius * .5f; rounded(ex - radius - stroke / 2, ey - radius * .9f - stroke / 2, radius * 2 + stroke, radius * 1.8f + stroke, corner, border); rounded(ex - radius + stroke / 2, ey - radius * .9f + stroke / 2, radius * 2 - stroke, radius * 1.8f - stroke, corner, fill) }
                rounded(ex - radius / 2, ey - 2 * unit, radius, 4 * unit, 2 * unit, Color.valueOf("FFC88C").apply { a = alpha })
            }
            shapes.color = Color.ORANGE; shapes.rect(ex - radius, ey + radius + 5 * unit, radius * 2 * (enemy.getDouble("health") / enemy.getDouble("maxHealth")).toFloat(), 3 * unit)
        }
        battle.getJSONArray("projectiles").objects { projectile ->
            val at = position(projectile); val cx = x(at.getDouble(0)); val cy = y(at.getDouble(1))
            val target = battle.getJSONArray("enemies").objects().firstOrNull { it.getInt("id") == projectile.getInt("target") }?.getJSONArray("position")
            val angle = if (target == null) 0f else (atan2(target.getDouble(1) - at.getDouble(1), target.getDouble(0) - at.getDouble(0)) * 180 / PI).toFloat()
            shapes.color = Color.WHITE; shapes.rect(cx - 7.5f * unit, cy - 3 * unit, 7.5f * unit, 3 * unit, 15 * unit, 6 * unit, 1f, 1f, angle)
            shapes.color = Color.valueOf(if (cosmeticState.getJSONObject("selection").optString("weaponEffectID") == "prism") "A3FFED" else if (cosmeticState.getJSONObject("selection").getBoolean("goldenTrails")) "FFD878" else "FFB66C")
            shapes.rect(cx - 7 * unit, cy - 2.5f * unit, 7 * unit, 2.5f * unit, 14 * unit, 5 * unit, 1f, 1f, angle)
        }
        battle.getJSONArray("drones").let { drones -> for (i in 0 until drones.length()) { val at = drones.getJSONArray(i); val cx = x(at.getDouble(0)); val cy = y(at.getDouble(1)); rounded(cx - 9.75f * unit, cy - 6.75f * unit, 19.5f * unit, 13.5f * unit, 4 * unit, Color.WHITE); rounded(cx - 9 * unit, cy - 6 * unit, 18 * unit, 12 * unit, 4 * unit, Color.valueOf("F5B942")); shapes.color = Color.valueOf("79D9BA"); shapes.rect(cx - 14 * unit, cy + 7.5f * unit, 28 * unit, 3 * unit) } }
        presentation.effects.forEach { rendered ->
            val effect = rendered.data; val age = elapsed - rendered.born
            val from = effect.getJSONArray("from"); val to = effect.getJSONArray("to")
            val prism = cosmeticState.getJSONObject("selection").optString("weaponEffectID") == "prism"
            shapes.color = Color.valueOf(if (prism) if (effect.getString("style") in listOf("arc", "beam")) "E7A8FF" else "A3FFED" else if (cosmeticState.getJSONObject("selection").getBoolean("goldenTrails")) "FFD878" else if (effect.getString("style") == "arc") "83EAFF" else if (effect.getString("style") == "beam") "BC9BFF" else biome.getJSONArray("palette").getString(2))
            shapes.color.a = (1 - age / .18).toFloat().coerceIn(0f, 1f)
            val style = effect.getString("style"); val fx = x(from.getDouble(0)); val fy = y(from.getDouble(1)); val tx = x(to.getDouble(0)); val ty = y(to.getDouble(1))
            if (effect.getDouble("damage") <= 0) {
                val fixed = effect.getDouble("damage") == -1.0
                val radius = if (fixed) width * .14f else 30 * if (reducedMotion) 1f else (1 + 2 * age / rendered.duration.coerceAtLeast(.001)).toFloat()
                shapes.color = Color(1f, .5f, 0f, .1f); shapes.circle(tx, ty, radius, 48)
                ring(tx, ty, radius, 3f, Color.ORANGE)
                return@forEach
            }
            if (style == "arc") {
                val dx = tx - fx; val dy = ty - fy; val length = hypot(dx, dy).coerceAtLeast(1f); var lastX = fx; var lastY = fy
                for (segment in 1..6) { val t = segment / 6f; val jag = if (segment == 6) 0f else (if (segment % 2 == 0) 7 else -7) * unit; val nextX = fx + dx * t - dy / length * jag; val nextY = fy + dy * t + dx / length * jag; shapes.rectLine(lastX, lastY, nextX, nextY, 2 * unit); lastX = nextX; lastY = nextY }
            } else shapes.rectLine(if (style == "orbital") tx else fx, if (style == "orbital") ty + scale * .35f else fy, tx, ty, (if (style == "beam" || style == "orbital") 6 else if (effect.getBoolean("critical")) 4 else 2) * unit)
            if (age < .3 && (style == "missile" || style == "orbital")) ring(tx, ty, scale * if (style == "orbital") .16f else .08f, 3f, shapes.color.cpy().apply { a = (1 - age / .3).toFloat() })
            if (age < .2 && !reducedMotion) {
                val count = (repository.profile.getJSONObject("preferences").getDouble("particleIntensity") * 6).toInt()
                shapes.color.a = (1 - age / .2).toFloat()
                for (spark in 0 until count) { val angle = spark * PI * 2 / count; shapes.circle(tx + cos(angle).toFloat() * 17 * (age / .2).toFloat(), ty + sin(angle).toFloat() * 17 * (age / .2).toFloat(), 2f, 8) }
            }
        }
        val squadForShadows = battle.getJSONArray("squad")
        for (i in 0 until squadForShadows.length()) { val angle = i * PI * 2 / squadForShadows.length(); val rx = x(px + if (i == 0) 0.0 else cos(angle) * .055); val ry = y(py + if (i == 0) 0.0 else sin(angle) * .055); shapes.color = Color(0f, 0f, 0f, .25f); shapes.ellipse(rx - 17.5f * unit, ry - 25 * unit, 35 * unit, 12 * unit, 24) }
        shapes.end()
        batch.begin()
        val squad = battle.getJSONArray("squad")
        for (i in 0 until squad.length()) {
            val index = order.indexOf(squad.getString(i)).coerceAtLeast(0)
            var region = TextureRegion(atlas, index % 4 * atlas.width / 4, index / 4 * atlas.height / 2, atlas.width / 4, atlas.height / 2)
            val angle = i * PI * 2 / squad.length()
            val rx = x(px + if (i == 0) 0.0 else cos(angle) * .055); val ry = y(py + if (i == 0) 0.0 else sin(angle) * .055)
            val stride = battle.getJSONArray("strides").getJSONObject(i)
            val animated = stride.getBoolean("moving") && !reducedMotion
            val phase = stride.getDouble("distance") / .05 * PI * 2
            val finish = cosmeticState.getJSONObject("finishes").optJSONObject(squad.getString(i))
            val skin = finish?.optString("skin").orEmpty()
            if (skin.isNotEmpty()) region = signatureTextures.getValue(skin)[if (animated) floor(stride.getDouble("distance") / .05 * 4).toInt().mod(4) else 0]
            batch.color = if (finish != null && skin.isEmpty()) Color.valueOf(finish.getString("tint")).lerp(Color.WHITE, .35f) else Color.WHITE
            val bob = if (animated) abs(sin(phase)).toFloat() * 4 else 0f
            val rotation = if (animated) (sin(phase) * .07 - stride.getJSONArray("direction").getDouble(0) * .08) * 180 / PI else 0.0
            val squash = if (animated) 1 - abs(sin(phase)).toFloat() * .04f else 1f
            val dimension = (if (skin.isNotEmpty()) if (squad.getString(i) in listOf("tank", "boomer")) 66 else 58 else if (squad.getString(i) in listOf("tank", "boomer")) 60 else 48) * unit
            batch.draw(region, rx - dimension / 2, ry - dimension / 2 + bob, dimension / 2, dimension / 2, dimension, dimension, 1f, squash, rotation.toFloat())
            batch.color = Color.WHITE
        }
        val activeEffects = mutableSetOf<Int>()
        presentation.effects.forEach { rendered ->
            val effect = rendered.data; val age = elapsed - rendered.born
            val id = effect.getInt("id"); activeEffects.add(id)
            if (seenEffects.add(id) && effect.getDouble("damage") > 0 && elapsed - lastShotSoundAt >= .18) { audio.cue("weapon"); lastShotSoundAt = elapsed }
            if (effect.getDouble("damage") > 0 && repository.profile.getJSONObject("preferences").getBoolean("damageNumbers")) {
                val to = effect.getJSONArray("to"); font.color = if (effect.getBoolean("critical")) Color.YELLOW else Color.WHITE
                font.color.a = (1 - age / .45).toFloat().coerceIn(0f, 1f)
                font.data.setScale((if (effect.getBoolean("critical")) 19 else 13) / baseFontHeight)
                font.draw(batch, effect.getDouble("damage").toInt().toString(), x(to.getDouble(0)), y(to.getDouble(1)) + font.capHeight + if (reducedMotion) 0f else (age / .45 * 20).toFloat())
            }
        }
        seenEffects.retainAll(activeEffects)
        announcement?.let { (text, color, born) ->
            val age = elapsed - born
            if (age < 1.5) {
                font.data.setScale(min(22f, width / 18) / baseFontHeight)
                font.color = color.cpy().apply { a = if (reducedMotion || age < 1) 1f else ((1.5 - age) / .5).toFloat() }
                val layout = com.badlogic.gdx.graphics.g2d.GlyphLayout(font, text)
                font.draw(batch, layout, width / 2 - layout.width / 2, height * .8f)
            } else announcement = null
        }
        batch.end()
        val enemies = battle.getJSONArray("enemies")
        val bossPresent = (0 until enemies.length()).any { enemies.getJSONObject(it).getString("kind") == "boss" }
        audio.music(if (bossPresent) "boss" else "battle")
        if (paused != audioPaused) { if (paused) audio.pause() else audio.resume(); audioPaused = paused }
        if (battle.getInt("kills") > previousKills) { audio.cue("explosion"); previousKills = battle.getInt("kills") }
        previousWave = battle.getInt("wave")
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
    private fun outlineArea(area: JSONObject, color: Color) {
        val from = area.getJSONArray("from"); val to = area.getJSONArray("to"); val radius = area.getDouble("radius").toFloat() * scale
        val cx = x(to.getDouble(0)); val cy = y(to.getDouble(1))
        if (area.getString("shape") != "line") { ring(cx, cy, radius, 2f, color); return }
        val fx = x(from.getDouble(0)); val fy = y(from.getDouble(1)); val length = hypot(cx - fx, cy - fy).coerceAtLeast(.001f)
        val ox = -(cy - fy) / length * radius; val oy = (cx - fx) / length * radius
        shapes.color = color
        shapes.rectLine(fx + ox, fy + oy, cx + ox, cy + oy, 2f); shapes.rectLine(fx - ox, fy - oy, cx - ox, cy - oy, 2f)
        val angle = atan2(cy - fy, cx - fx)
        for (end in 0..1) for (segment in 0 until 24) {
            val a = angle + (if (end == 0) PI / 2 else -PI / 2) + segment * PI / 24; val b = a + PI / 24
            val ex = if (end == 0) fx else cx; val ey = if (end == 0) fy else cy
            shapes.rectLine(ex + cos(a).toFloat() * radius, ey + sin(a).toFloat() * radius, ex + cos(b).toFloat() * radius, ey + sin(b).toFloat() * radius, 2f)
        }
    }
    private fun rounded(x: Float, y: Float, w: Float, h: Float, radius: Float, color: Color) {
        val r = radius.coerceIn(0f, min(w, h) / 2); shapes.color = color
        shapes.rect(x + r, y, w - r * 2, h); shapes.rect(x, y + r, w, h - r * 2)
        for (cx in listOf(x + r, x + w - r)) for (cy in listOf(y + r, y + h - r)) shapes.circle(cx, cy, r, 12)
    }
    private fun ring(cx: Float, cy: Float, radius: Float, thickness: Float, color: Color) {
        shapes.color = color
        for (i in 0 until 64) { val a = i * PI / 32; val b = (i + 1) * PI / 32; shapes.rectLine(cx + cos(a).toFloat() * radius, cy + sin(a).toFloat() * radius, cx + cos(b).toFloat() * radius, cy + sin(b).toFloat() * radius, thickness) }
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
    override fun dispose() { disposed = true; stopRecovery(); worker.shutdownNow(); repository.battleJournal.close(); android.util.Log.i("ScrapRender", metrics.report().toString()); signatureTextures.values.flatten().forEach { it.texture.dispose() }; batch.dispose(); shapes.dispose(); atlas.dispose(); audio.dispose(); font.dispose() }
}
