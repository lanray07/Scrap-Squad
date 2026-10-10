package com.scrapsquad.fire

import android.app.Activity
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import org.json.JSONObject
import java.text.NumberFormat

/** Native text stays sharp at device density and Android accessibility font sizes. */
class BattleHudView(private val activity: Activity, private val strings: Strings) : LinearLayout(activity) {
    val details = Ui.text(activity, "", 12f, Ui.muted)
    private val health = Ui.text(activity, strings.text("battle.health"), 13f, Color.WHITE)
    private val header = LinearLayout(activity).apply { orientation = HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
    private val integrity = ProgressBar(activity, null, android.R.attr.progressBarStyleHorizontal).apply {
        max = 1000; progress = 1000; progressTintList = ColorStateList.valueOf(Ui.mint)
        progressBackgroundTintList = ColorStateList.valueOf(Ui.disabled)
        contentDescription = strings.text("battle.health")
        background = Ui.rounded(activity, Ui.disabled, 8)
    }
    private val values = mutableMapOf<String, TextView>()
    init {
        orientation = VERTICAL; setPadding(Ui.dp(activity, 12), Ui.dp(activity, 8), Ui.dp(activity, 12), Ui.dp(activity, 8))
        background = Ui.rounded(activity, Ui.ink, 22, Ui.surface)
        header.addView(health, LayoutParams(0, -2, 1f)); addView(header, LayoutParams(-1, -2))
        addView(integrity, LayoutParams(-1, Ui.dp(activity, 10)).apply { setMargins(8, 0, 8, Ui.dp(activity, 6)) })
        val row = LinearLayout(activity).apply { orientation = HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        listOf("wave" to "momentum.wave", "score" to "battle.score", "combo" to "momentum.combo", "charge" to "momentum.overdrive").forEachIndexed { index, (id, key) ->
            val color = listOf(Ui.gold, Ui.mint, Color.rgb(131, 234, 255), Color.rgb(202, 173, 255))[index]
            val tile = LinearLayout(activity).apply {
                orientation = VERTICAL; gravity = Gravity.CENTER
                setPadding(4, Ui.dp(activity, 4), 4, Ui.dp(activity, 4)); background = Ui.rounded(activity, Ui.surface, 12)
            }
            tile.addView(Ui.text(activity, strings.text(key), 11f, Ui.muted).apply { gravity = Gravity.CENTER; setPadding(2, 2, 2, 2) })
            val value = Ui.text(activity, "0", 19f, color).apply {
                gravity = Gravity.CENTER; typeface = Typeface.create("sans-serif", Typeface.BOLD); setPadding(2, 2, 2, 2)
            }
            values[id] = value; tile.addView(value)
            row.addView(tile, LayoutParams(0, -2, 1f).apply { setMargins(4, 0, 4, 0) })
        }
        addView(row, LayoutParams(-1, -2))
        details.setPadding(8, Ui.dp(activity, 6), 8, 0); addView(details, LayoutParams(-1, -2))
    }
    fun addPriorityControl(button: android.widget.Button) {
        button.textSize = 11f; button.minHeight = Ui.dp(activity, 38)
        header.addView(button, LayoutParams(Ui.dp(activity, 130), -2))
    }
    fun update(state: JSONObject) {
        val maximum = state.getDouble("maxHealth").coerceAtLeast(1.0)
        val fraction = (state.getDouble("health") / maximum).coerceIn(0.0, 1.0)
        health.text = "${strings.text("battle.health")}   ${state.getDouble("health").toInt().coerceAtLeast(0)} / ${maximum.toInt()}"
        integrity.progress = (fraction * 1000).toInt()
        integrity.progressTintList = ColorStateList.valueOf(if (fraction < .25) Color.rgb(255, 124, 133) else if (fraction < .5) Ui.gold else Ui.mint)
        values["wave"]?.text = state.getInt("wave").toString()
        values["score"]?.text = NumberFormat.getIntegerInstance().format(state.getInt("score"))
        values["combo"]?.text = state.getInt("combo").toString()
        values["charge"]?.text = "${(state.getDouble("charge").coerceIn(0.0, 1.0) * 100).toInt()}%"
    }
}
