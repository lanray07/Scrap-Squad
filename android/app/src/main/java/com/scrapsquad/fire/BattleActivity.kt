package com.scrapsquad.fire

import android.app.AlertDialog
import android.os.Bundle
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import com.badlogic.gdx.backends.android.AndroidApplication
import com.badlogic.gdx.backends.android.AndroidApplicationConfiguration
import org.json.JSONObject
import java.security.SecureRandom

class BattleActivity : AndroidApplication() {
    private lateinit var repository: GameRepository
    private lateinit var strings: Strings
    private lateinit var renderer: BattleRenderer
    private lateinit var status: TextView
    private var dialog: AlertDialog? = null
    private var ending = false
    private var resumedOnce = false
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        repository = GameRepository(this); strings = Strings(this)
        repository.initialize()
        val mode = intent.getStringExtra("mode") ?: "campaign"
        renderer = BattleRenderer(repository, mode, (SecureRandom().nextLong().ushr(1)).toString(), intent.getIntExtra("zone", 0), intent.getStringExtra("challenge")) { state -> runOnUiThread { updateHud(state) } }
        val config = AndroidApplicationConfiguration().apply { useAccelerometer = false; useCompass = false; useGyroscope = false; useImmersiveMode = false; numSamples = 0 }
        val root = FrameLayout(this)
        root.addView(initializeForView(renderer, config), FrameLayout.LayoutParams(-1, -1))
        status = Ui.text(this, "", 15f, Ui.mint).apply { setBackgroundColor(Ui.surface) }
        root.addView(status, FrameLayout.LayoutParams(-1, -2, Gravity.TOP))
        val controls = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setBackgroundColor(Ui.ink) }
        listOf("battle.dash" to "dash", "battle.ability" to "ability", "momentum.overdrive" to "overdrive", "battle.pause" to "pause").forEach { (key, op) ->
            controls.addView(Ui.button(this, strings.text(key)) { if (op == "pause") pauseDialog() else renderer.action(op) }.apply { layoutParams = LinearLayout.LayoutParams(0, -2, 1f).apply { setMargins(4, 4, 4, 4) }; textSize = 12f })
        }
        root.addView(controls, FrameLayout.LayoutParams(-1, -2, Gravity.BOTTOM))
        Ui.fitInsets(root); setContentView(root)
    }
    private fun updateHud(state: JSONObject) {
        if (isFinishing || ending) return
        status.text = "${strings.text("battle.health")} ${state.getDouble("health").toInt()}/${state.getDouble("maxHealth").toInt()}   ${strings.text("momentum.wave")} ${state.getInt("wave")}   ${strings.text("battle.score")} ${state.getInt("score")}\n${strings.text("momentum.combo")} ${state.getInt("combo")}   ${strings.text("momentum.overdrive")} ${(state.getDouble("charge") * 100).toInt()}%   ${state.getDouble("elapsed").toInt()}s"
        when (state.getString("state")) {
            "choosing" -> if (dialog == null) {
                val ids = state.getJSONArray("choices"); val upgrades = repository.content.getJSONArray("upgrades")
                val labels = (0 until ids.length()).map { i -> val id = ids.getString(i); val item = (0 until upgrades.length()).map { upgrades.getJSONObject(it) }.first { it.getString("id") == id }; strings.text(item.getString("nameKey")) + "\n" + strings.text(item.getString("descriptionKey")) }.toTypedArray()
                dialog = AlertDialog.Builder(this).setTitle(strings.text("battle.choose")).setItems(labels) { _, which -> dialog = null; renderer.action("choose", ids.getString(which)) }.setCancelable(false).show()
            }
            "victory", "defeated" -> {
                ending = true
                repository.action("claim")
                dialog?.dismiss()
                dialog = AlertDialog.Builder(this).setTitle(strings.text(if (state.getString("state") == "victory") "battle.victory" else "battle.defeat"))
                    .setMessage("${strings.text("battle.kills")}: ${state.getInt("kills")}\n${strings.text("battle.score")}: ${state.getInt("score")}\n${strings.text("battle.perfectDodges")}: ${state.getInt("perfectDodges")}")
                    .setPositiveButton(strings.text("battle.return")) { _, _ -> finish() }.setCancelable(false).show()
            }
        }
    }
    private fun pauseDialog() {
        if (dialog != null || ending) return
        renderer.paused = true
        dialog = AlertDialog.Builder(this).setTitle(strings.text("battle.paused"))
            .setPositiveButton(strings.text("battle.resume")) { _, _ -> dialog = null; renderer.paused = false }
            .setNegativeButton(strings.text("battle.retreat")) { _, _ -> dialog = null; renderer.action("retreat") }
            .setCancelable(false).show()
    }
    @Deprecated("Android back compatibility") override fun onBackPressed() { pauseDialog() }
    override fun onResume() { super.onResume(); if (resumedOnce && ::renderer.isInitialized && !ending) pauseDialog(); resumedOnce = true }
}
