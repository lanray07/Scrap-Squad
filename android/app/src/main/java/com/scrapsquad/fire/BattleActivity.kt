package com.scrapsquad.fire

import android.app.AlertDialog
import android.os.Bundle
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Button
import kotlin.math.ceil
import com.badlogic.gdx.backends.android.AndroidApplication
import com.badlogic.gdx.backends.android.AndroidApplicationConfiguration
import org.json.JSONObject
import java.security.SecureRandom

class BattleActivity : AndroidApplication() {
    private lateinit var repository: GameRepository
    private lateinit var strings: Strings
    private lateinit var renderer: BattleRenderer
    private lateinit var status: TextView
    private lateinit var battleHud: BattleHudView
    private lateinit var banner: TextView
    private val hideBanner = Runnable { if (::banner.isInitialized) banner.visibility = android.view.View.GONE }
    private var dialog: AlertDialog? = null
    private var ending = false
    private var resumedOnce = false
    private val buttons = mutableMapOf<String, Button>()
    private var currentPriority = "nearest"
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        repository = GameRepository(this); strings = Strings(this)
        repository.initialize()
        strings.language = repository.profile.getJSONObject("preferences").getString("locale")
        val mode = intent.getStringExtra("mode") ?: "campaign"
        renderer = BattleRenderer(repository, mode, (SecureRandom().nextLong().ushr(1)).toString(), intent.getIntExtra("zone", 0), intent.getStringExtra("challenge"),
            recover = repository.battleJournal.pending(), retreatRecovered = intent.getBooleanExtra("retreatRecovered", false),
            recoveryProgress = { progress -> runOnUiThread { if (::status.isInitialized && !isFinishing) status.text = "${strings.text("android.recovering")} $progress%" } },
            recoveryError = { error -> runOnUiThread { showRecoveryError(error) } },
            notification = { text, color -> runOnUiThread { showAnnouncement(text, color) } },
            hud = { state -> runOnUiThread { updateHud(state) } })
        val config = AndroidApplicationConfiguration().apply { useAccelerometer = false; useCompass = false; useGyroscope = false; useImmersiveMode = false; numSamples = 0 }
        val root = FrameLayout(this)
        root.addView(initializeForView(renderer, config), FrameLayout.LayoutParams(-1, -1))
        battleHud = BattleHudView(this, strings)
        status = battleHud.details
        if (repository.battleJournal.pending()) status.text = strings.text("android.recovering")
        battleHud.addPriorityControl(Ui.button(this, strings.text("battle.priority")) {
            if (dialog != null || renderer.recovering) return@button
            val priorities = listOf("nearest", "weakest", "boss")
            dialog = AlertDialog.Builder(this).setTitle(strings.text("battle.priority"))
                .setSingleChoiceItems(priorities.map { strings.text("priority.$it") }.toTypedArray(), priorities.indexOf(currentPriority)) { selected, which -> currentPriority = priorities[which]; renderer.action("priority", currentPriority); selected.dismiss(); dialog = null }
                .setNegativeButton(strings.text("common.cancel"), null).create().also { choice -> choice.setOnDismissListener { if (dialog === choice) dialog = null }; choice.show() }
        })
        root.addView(battleHud, FrameLayout.LayoutParams(-1, -2, Gravity.TOP))
        banner = Ui.text(this, "", 22f, android.graphics.Color.WHITE).apply {
            gravity = Gravity.CENTER; typeface = android.graphics.Typeface.create("sans-serif", android.graphics.Typeface.BOLD)
            setPadding(Ui.dp(this@BattleActivity, 18), Ui.dp(this@BattleActivity, 12), Ui.dp(this@BattleActivity, 18), Ui.dp(this@BattleActivity, 12))
            visibility = android.view.View.GONE; importantForAccessibility = android.view.View.IMPORTANT_FOR_ACCESSIBILITY_NO
        }
        root.addView(banner, FrameLayout.LayoutParams(minOf(Ui.dp(this, 660), resources.displayMetrics.widthPixels - Ui.dp(this, 48)), -2, Gravity.TOP or Gravity.CENTER_HORIZONTAL))
        battleHud.addOnLayoutChangeListener { _, _, _, _, bottom, _, _, _, _ ->
            (banner.layoutParams as FrameLayout.LayoutParams).also { it.topMargin = bottom + Ui.dp(this, 12); banner.layoutParams = it }
        }
        val controls = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setBackgroundColor(Ui.ink) }
        listOf("battle.dash" to "dash", "battle.ability" to "ability", "momentum.overdrive" to "overdrive", "battle.pause" to "pause").forEach { (key, op) ->
            controls.addView(Ui.button(this, strings.text(key)) { if (op == "pause") pauseDialog() else { if (repository.profile.getJSONObject("preferences").getBoolean("haptics")) root.performHapticFeedback(android.view.HapticFeedbackConstants.LONG_PRESS); renderer.action(op) } }.apply { layoutParams = LinearLayout.LayoutParams(0, -2, 1f).apply { setMargins(4, 4, 4, 4) }; textSize = 12f; buttons[op] = this })
        }
        root.addView(controls, FrameLayout.LayoutParams(-1, -2, Gravity.BOTTOM))
        Ui.fitInsets(root); setContentView(root)
    }
    private fun updateHud(state: JSONObject) {
        if (isFinishing || ending) return
        battleHud.update(state)
        status.text = "${strings.text("battle.kills")}: ${state.getInt("kills")}   •   ${state.getDouble("elapsed").toInt()}${strings.text("android.seconds")}"
        currentPriority = state.getString("priority")
        val extras = mutableListOf<String>()
        state.getJSONArray("enemies").objects().firstOrNull { it.getString("kind") == "boss" }?.let { boss ->
            val biome = repository.content.getJSONArray("biomes").getJSONObject(state.getInt("zone"))
            extras.add("${strings.text(biome.getString("bossKey"))} ${(100 * boss.getDouble("health") / boss.getDouble("maxHealth")).toInt()}%")
            val armor = boss.getDouble("armor")
            extras.add(if (armor > 0) "${strings.text("battle.armor")} ${(100 * armor / (90 * biome.getDouble("difficulty"))).toInt()}%" else strings.text("battle.armor.broken"))
        }
        state.getJSONArray("synergies").strings().forEach { extras.add(strings.text("synergy.$it")) }
        if (state.getString("evolution").isNotEmpty()) extras.add(strings.text("evolution.${state.getString("evolution")}"))
        if (state.getString("event").isNotEmpty()) extras.add("${strings.text("event.${state.getString("event")}")} ${ceil(state.getDouble("eventRemaining")).toInt()}")
        if (state.getDouble("perfectDodgeBoost") > 0) extras.add(strings.text("battle.perfectDodge"))
        if (extras.isNotEmpty()) status.append("\n" + extras.joinToString(" · "))
        listOf("dash" to "dashCooldown", "ability" to "abilityCooldown").forEach { (op, cooldown) ->
            buttons[op]?.apply { val remaining = ceil(state.getDouble(cooldown)).toInt(); text = strings.text("battle.$op") + if (remaining > 0) " $remaining" else ""; isEnabled = remaining == 0 && state.getString("state") == "fighting"; alpha = if (isEnabled) 1f else .55f }
        }
        buttons["overdrive"]?.apply { isEnabled = state.getDouble("charge") >= 1 && state.getDouble("overdrive") <= 0 && state.getString("state") == "fighting"; alpha = if (isEnabled) 1f else .55f }
        if (state.getString("state") == "fighting" && renderer.paused && dialog == null) pauseDialog()
        when (state.getString("state")) {
            "choosing" -> if (dialog == null) {
                val ids = state.getJSONArray("choices"); val upgrades = repository.content.getJSONArray("upgrades")
                val choices = ids.strings().map { id -> upgrades.objects().first { it.getString("id") == id } }
                dialog = UpgradePicker.show(this, strings, choices) { id -> dialog = null; renderer.action("choose", id) }
            }
            "victory", "defeated" -> {
                ending = true
                try { repository.action("claim") } catch (error: Exception) { showRecoveryError(error); return }
                dialog?.dismiss()
                dialog = AlertDialog.Builder(this).setTitle(strings.text(if (state.getString("state") == "victory") "battle.victory" else "battle.defeat"))
                    .setMessage("${strings.text("battle.kills")}: ${state.getInt("kills")}\n${strings.text("battle.score")}: ${state.getInt("score")}\n${strings.text("battle.perfectDodges")}: ${state.getInt("perfectDodges")}")
                    .setPositiveButton(strings.text("battle.return")) { _, _ -> finish() }.setCancelable(false).show()
            }
        }
    }
    private fun showAnnouncement(text: String, hex: String) {
        if (isFinishing || isDestroyed || !::banner.isInitialized) return
        banner.removeCallbacks(hideBanner)
        val accent = android.graphics.Color.parseColor("#" + hex.removePrefix("#"))
        banner.text = text; banner.background = Ui.rounded(this, Ui.ink, 20, accent)
        banner.visibility = android.view.View.VISIBLE
        banner.postDelayed(hideBanner, 1800)
    }
    private fun pauseDialog() {
        if (dialog != null || ending || renderer.recovering) return
        renderer.paused = true
        dialog = AlertDialog.Builder(this).setTitle(strings.text("battle.paused"))
            .setPositiveButton(strings.text("battle.resume")) { _, _ -> dialog = null; renderer.paused = false }
            .setNegativeButton(strings.text("battle.retreat")) { _, _ -> dialog = null; renderer.action("retreat") }
            .setCancelable(false).show()
    }
    private fun showRecoveryError(error: Throwable) {
        if (isFinishing || isDestroyed) return
        android.util.Log.e("ScrapRecovery", "Battle recovery failed", error); ending = true
        dialog?.dismiss()
        dialog = AlertDialog.Builder(this).setTitle(strings.text("common.error")).setMessage(strings.text("android.recovery.error"))
            .setPositiveButton(strings.text("common.ok")) { _, _ -> finish() }.setCancelable(false).show()
    }
    override fun finish() { if (::renderer.isInitialized) renderer.stopRecovery(); super.finish() }
    override fun onDestroy() { if (::banner.isInitialized) banner.removeCallbacks(hideBanner); dialog?.dismiss(); dialog = null; super.onDestroy() }
    @Deprecated("Android back compatibility") override fun onBackPressed() { if (::renderer.isInitialized && renderer.recovering) finish() else pauseDialog() }
    override fun onResume() { super.onResume(); if (resumedOnce && ::renderer.isInitialized && !ending) pauseDialog(); resumedOnce = true }
}
