package com.scrapsquad.fire

import android.app.Activity
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

object Ui {
    val ink = Color.rgb(16, 37, 45); val surface = Color.rgb(32, 58, 67)
    val gold = Color.rgb(245, 185, 66); val mint = Color.rgb(121, 217, 186); val muted = Color.rgb(174, 193, 196)
    fun dp(activity: Activity, value: Int) = (activity.resources.displayMetrics.density * value).toInt()
    fun panel(activity: Activity) = LinearLayout(activity).apply { orientation = LinearLayout.VERTICAL; setPadding(24, 20, 24, 20); setBackgroundColor(ink) }
    fun text(activity: Activity, value: String, size: Float = 16f, color: Int = Color.WHITE) = TextView(activity).apply { text = value; textSize = size; setTextColor(color); setPadding(8, 10, 8, 10); typeface = Typeface.create("sans-serif-rounded", Typeface.NORMAL) }
    fun button(activity: Activity, value: String, action: () -> Unit) = Button(activity).apply {
        text = value; isAllCaps = false; setTextColor(ink); textSize = 16f; minHeight = dp(activity, 48)
        background = GradientDrawable().apply { cornerRadius = dp(activity, 16).toFloat(); setColor(gold) }
        layoutParams = LinearLayout.LayoutParams(-1, -2).apply { setMargins(6, 8, 6, 8) }
        setOnClickListener {
            if (activity is MainActivity) { activity.playCue("ui"); if (activity.hapticsEnabled()) performHapticFeedback(android.view.HapticFeedbackConstants.KEYBOARD_TAP) }
            action()
        }
    }
    @Suppress("DEPRECATION")
    fun fitInsets(view: View) { view.setOnApplyWindowInsetsListener { v, insets ->
        if (android.os.Build.VERSION.SDK_INT >= 30) { val bars = insets.getInsets(android.view.WindowInsets.Type.systemBars()); v.setPadding(bars.left + 16, bars.top + 12, bars.right + 16, bars.bottom + 12) }
        else v.setPadding(insets.systemWindowInsetLeft + 16, insets.systemWindowInsetTop + 12, insets.systemWindowInsetRight + 16, insets.systemWindowInsetBottom + 12)
        insets
    } }
}
