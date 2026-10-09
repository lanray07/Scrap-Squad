package com.scrapsquad.fire

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.DialogInterface
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.ScrollView

/** One native, density-sharp presentation for information and action dialogs. */
object PremiumDialog {
    class Builder(context: Context) {
        private val activity = context as Activity
        private var title: CharSequence = ""
        private var message: CharSequence? = null
        private var content: View? = null
        private var cancelable = true
        private var accent = Ui.gold
        private var statistics: List<Pair<String, String>> = emptyList()
        private var feature: Triple<String, String, String>? = null
        private var character: Pair<String, CharSequence>? = null
        private var choices: Triple<Array<String>, Int, DialogInterface.OnClickListener>? = null
        private val actions = linkedMapOf<Int, Pair<CharSequence, DialogInterface.OnClickListener?>>()
        fun setTitle(value: CharSequence) = apply { title = value }
        fun setMessage(value: CharSequence) = apply { message = value }
        fun setView(value: View) = apply { content = value }
        fun setCancelable(value: Boolean) = apply { cancelable = value }
        fun setAccent(value: Int) = apply { accent = value }
        fun setStats(values: List<Pair<String, String>>) = apply { statistics = values }
        fun setFeature(name: String, badge: String, detail: String) = apply { feature = Triple(name, badge, detail) }
        fun setCharacter(id: String, actionLabel: CharSequence) = apply { character = id to actionLabel }
        fun setPositiveButton(label: CharSequence, listener: DialogInterface.OnClickListener?) = apply { actions[DialogInterface.BUTTON_POSITIVE] = label to listener }
        fun setNegativeButton(label: CharSequence, listener: DialogInterface.OnClickListener?) = apply { actions[DialogInterface.BUTTON_NEGATIVE] = label to listener }
        fun setNeutralButton(label: CharSequence, listener: DialogInterface.OnClickListener?) = apply { actions[DialogInterface.BUTTON_NEUTRAL] = label to listener }
        fun setSingleChoiceItems(items: Array<String>, selected: Int, listener: DialogInterface.OnClickListener) = apply { choices = Triple(items, selected, listener) }
        private fun togglePortrait(view: RobotPortraitView) {
            view.victory = !view.victory; view.frame = (view.frame + 1) % 4; view.isSelected = view.victory
            view.rotation = if (view.victory) -8f else 0f
            view.translationY = if (view.victory) -Ui.dp(activity, 4).toFloat() else 0f
            view.invalidate()
        }
        fun create(): AlertDialog {
            val column = LinearLayout(activity).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(Ui.dp(activity, 18), Ui.dp(activity, 18), Ui.dp(activity, 18), Ui.dp(activity, 18))
                background = Ui.rounded(activity, Ui.ink, 28, Ui.mint)
            }
            val header = LinearLayout(activity).apply {
                gravity = Gravity.CENTER_VERTICAL
                setPadding(Ui.dp(activity, 12), Ui.dp(activity, 10), Ui.dp(activity, 12), Ui.dp(activity, 10))
                val light = Color.rgb((Color.red(accent) * 3 + 255) / 4, (Color.green(accent) * 3 + 255) / 4, (Color.blue(accent) * 3 + 255) / 4)
                background = GradientDrawable(GradientDrawable.Orientation.TL_BR, intArrayOf(light, accent)).apply { cornerRadius = Ui.dp(activity, 20).toFloat() }
            }
            var portrait: RobotPortraitView? = null
            character?.let { (id, label) ->
                header.addView(RobotPortraitView(activity, id).apply {
                    portrait = this
                    contentDescription = label; isFocusable = true
                    setOnClickListener {
                        togglePortrait(this)
                        if (activity is MainActivity) {
                            activity.playCue("ui")
                            if (activity.hapticsEnabled()) performHapticFeedback(android.view.HapticFeedbackConstants.KEYBOARD_TAP)
                        }
                    }
                }, LinearLayout.LayoutParams(Ui.dp(activity, 84), Ui.dp(activity, 84)))
            }
            val headline = LinearLayout(activity).apply { orientation = LinearLayout.VERTICAL }
            headline.addView(Ui.text(activity, title.toString(), 25f, Ui.ink).apply {
                typeface = Typeface.create("sans-serif", Typeface.BOLD)
                isAccessibilityHeading = true
            })
            character?.let { (_, label) ->
                headline.addView(Ui.button(activity, label.toString()) { portrait?.let { togglePortrait(it) } }.apply {
                    minHeight = Ui.dp(activity, 40); textSize = 13f
                    backgroundTintList = ColorStateList.valueOf(Ui.mint)
                })
            }
            header.addView(headline, LinearLayout.LayoutParams(0, -2, 1f))
            column.addView(header, LinearLayout.LayoutParams(-1, -2))
            val accents = listOf(Ui.mint, Color.rgb(131, 234, 255), Ui.gold, Color.rgb(202, 173, 255))
            feature?.let { (name, badge, detail) ->
                val card = LinearLayout(activity).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(Ui.dp(activity, 14), Ui.dp(activity, 12), Ui.dp(activity, 14), Ui.dp(activity, 12))
                    background = Ui.rounded(activity, Ui.surface, 20, accent)
                }
                card.addView(Ui.text(activity, name, 24f, accent).apply { typeface = Typeface.create("sans-serif", Typeface.BOLD) })
                card.addView(Ui.text(activity, badge, 15f, Ui.mint))
                card.addView(Ui.text(activity, detail, 17f, Color.WHITE))
                column.addView(card, LinearLayout.LayoutParams(-1, -2).apply { topMargin = Ui.dp(activity, 12) })
            }
            if (statistics.isNotEmpty()) {
                val compact = activity.resources.displayMetrics.widthPixels / activity.resources.displayMetrics.density < 480
                val row = LinearLayout(activity).apply { orientation = if (compact) LinearLayout.VERTICAL else LinearLayout.HORIZONTAL }
                statistics.forEachIndexed { index, (label, value) ->
                    val tile = LinearLayout(activity).apply {
                        orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER
                        setPadding(Ui.dp(activity, 8), Ui.dp(activity, 12), Ui.dp(activity, 8), Ui.dp(activity, 12))
                        background = Ui.rounded(activity, Ui.surface, 18, accents[index % accents.size])
                    }
                    tile.addView(Ui.text(activity, value, 28f, accents[index % accents.size]).apply { gravity = Gravity.CENTER; typeface = Typeface.create("sans-serif", Typeface.BOLD) })
                    tile.addView(Ui.text(activity, label, 13f, Color.WHITE).apply { gravity = Gravity.CENTER })
                    row.addView(tile, (if (compact) LinearLayout.LayoutParams(-1, -2) else LinearLayout.LayoutParams(0, -2, 1f)).apply { setMargins(Ui.dp(activity, 3), Ui.dp(activity, 6), Ui.dp(activity, 3), 0) })
                }
                column.addView(row, LinearLayout.LayoutParams(-1, -2).apply { topMargin = Ui.dp(activity, 6) })
            }
            message?.toString()?.split(Regex("\\n+"))?.filter { it.isNotBlank() }?.forEachIndexed { index, line ->
                val card = Ui.text(activity, line, 17f, Color.WHITE).apply {
                    setPadding(Ui.dp(activity, 16), Ui.dp(activity, 14), Ui.dp(activity, 16), Ui.dp(activity, 14))
                    background = Ui.rounded(activity, Ui.surface, 18, accents[index % accents.size])
                }
                column.addView(card, LinearLayout.LayoutParams(-1, -2).apply { topMargin = Ui.dp(activity, 10) })
            }
            content?.let { column.addView(it, LinearLayout.LayoutParams(-1, -2).apply { topMargin = Ui.dp(activity, 10) }) }
            val scroll = ScrollView(activity).apply { isFillViewport = false; addView(column) }
            val dialog = AlertDialog.Builder(activity).setCancelable(cancelable).create().apply { setView(scroll, 0, 0, 0, 0) }
            choices?.let { (items, checked, listener) ->
                val radios = mutableListOf<RadioButton>()
                items.forEachIndexed { index, label ->
                    column.addView(RadioButton(activity).apply {
                        text = label; textSize = 18f; setTextColor(Color.WHITE)
                        buttonTintList = ColorStateList.valueOf(Ui.mint); isChecked = index == checked
                        minHeight = Ui.dp(activity, 54)
                        setPadding(Ui.dp(activity, 12), Ui.dp(activity, 8), Ui.dp(activity, 12), Ui.dp(activity, 8))
                        background = Ui.rounded(activity, Ui.surface, 16, Ui.mint)
                        radios.add(this)
                        setOnClickListener { radios.forEachIndexed { position, radio -> radio.isChecked = position == index }; listener.onClick(dialog, index) }
                    }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = Ui.dp(activity, 10) })
                }
            }
            actions.forEach { (which, action) ->
                column.addView(Ui.button(activity, action.first.toString()) {
                    // Match AlertDialog semantics: the listener runs before automatic dismissal.
                    try { action.second?.onClick(dialog, which) } finally { dialog.dismiss() }
                }.apply {
                    if (which == DialogInterface.BUTTON_POSITIVE && accent != Ui.gold) backgroundTintList = ColorStateList.valueOf(accent)
                    else if (which != DialogInterface.BUTTON_POSITIVE) backgroundTintList = ColorStateList.valueOf(if (which == DialogInterface.BUTTON_NEGATIVE) Ui.mint else accents[1])
                })
            }
            dialog.setOnShowListener {
                dialog.window?.apply {
                    setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT)); decorView.setPadding(0, 0, 0, 0)
                    setDimAmount(.7f)
                    val width = minOf(Ui.dp(activity, 620), activity.resources.displayMetrics.widthPixels - Ui.dp(activity, 32))
                    val maximumHeight = (activity.resources.displayMetrics.heightPixels * .84).toInt()
                    scroll.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(maximumHeight, View.MeasureSpec.AT_MOST))
                    setLayout(width, scroll.measuredHeight.coerceAtMost(maximumHeight)); setGravity(Gravity.CENTER)
                }
            }
            return dialog
        }
        fun show(): AlertDialog = create().also { it.show() }
    }
}
