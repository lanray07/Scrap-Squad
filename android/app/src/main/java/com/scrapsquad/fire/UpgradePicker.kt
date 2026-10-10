package com.scrapsquad.fire

import android.app.Activity
import android.app.AlertDialog
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.ColorDrawable
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ScrollView
import org.json.JSONObject

object UpgradePicker {
    fun show(activity: Activity, strings: Strings, choices: List<JSONObject>, selected: (String) -> Unit): AlertDialog {
        val column = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL; setPadding(Ui.dp(activity, 22), Ui.dp(activity, 18), Ui.dp(activity, 22), Ui.dp(activity, 18))
            background = Ui.rounded(activity, Ui.ink, 28, Ui.mint)
        }
        column.addView(Ui.text(activity, strings.text("battle.choose"), 26f, Ui.gold).apply { typeface = Typeface.create("sans-serif", Typeface.BOLD) })
        val dialog = AlertDialog.Builder(activity).setView(ScrollView(activity).apply { addView(column) }).setCancelable(false).create()
        choices.forEach { item ->
            val accent = when (item.getString("element")) {
                "fire" -> Color.rgb(255, 168, 117)
                "electric" -> Ui.gold
                "cryo" -> Color.rgb(131, 234, 255)
                "poison" -> Ui.mint
                else -> Color.rgb(202, 173, 255)
            }
            val card = LinearLayout(activity).apply {
                orientation = LinearLayout.VERTICAL; setPadding(Ui.dp(activity, 16), Ui.dp(activity, 12), Ui.dp(activity, 16), Ui.dp(activity, 12))
                background = Ui.rounded(activity, Ui.surface, 22, accent)
            }
            card.addView(Ui.text(activity, strings.text(item.getString("nameKey")), 22f, accent).apply { typeface = Typeface.create("sans-serif", Typeface.BOLD) })
            card.addView(Ui.text(activity, strings.text(item.getString("descriptionKey")), 16f, Color.WHITE))
            card.addView(Ui.button(activity, strings.text("battle.choose")) { dialog.dismiss(); selected(item.getString("id")) }.apply {
                contentDescription = strings.text(item.getString("nameKey")); backgroundTintList = android.content.res.ColorStateList.valueOf(accent)
            })
            column.addView(card, LinearLayout.LayoutParams(-1, -2).apply { setMargins(0, Ui.dp(activity, 10), 0, 0) })
        }
        dialog.show(); dialog.window?.apply {
            setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT)); setDimAmount(.7f)
            setLayout(minOf(Ui.dp(activity, 560), activity.resources.displayMetrics.widthPixels - Ui.dp(activity, 32)), -2)
            setGravity(Gravity.CENTER)
        }
        return dialog
    }
}
