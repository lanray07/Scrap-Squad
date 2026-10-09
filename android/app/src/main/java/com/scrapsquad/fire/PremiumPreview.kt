package com.scrapsquad.fire

import android.widget.LinearLayout
import android.widget.ScrollView
import org.json.JSONObject

internal fun MenuScreens.premiumPreview(pack: JSONObject, catalog: JSONObject) {
    val body = Ui.panel(activity)
    body.addView(Ui.text(activity, t("premium.preview.note"), color = Ui.muted))
    val packs = catalog.getJSONArray("packs").objects()
    val all = listOf(pack) + (pack.optJSONArray("includes")?.strings() ?: emptyList()).map { id -> packs.first { it.getString("id") == id } }
    val portraits = mutableListOf<RobotPortraitView>()
    all.flatMap { it.getJSONArray("finishes").objects() }.forEach { finish ->
        body.addView(Ui.text(activity, t(finish.getString("nameKey")), 22f, Ui.gold))
        val portrait = RobotPortraitView(activity, finish.getString("robotID"), finish)
        portraits.add(portrait); body.addView(portrait, LinearLayout.LayoutParams(-1, Ui.dp(activity, 250)))
    }
    if (pack.optString("weaponEffect") == "prism") body.addView(PrismPreviewView(activity), LinearLayout.LayoutParams(-1, Ui.dp(activity, 180)))
    val pose = Ui.button(activity, t("premium.victory")) { portraits.forEach { it.victory = !it.victory; it.invalidate() } }; body.addView(pose)
    val dialog = PremiumDialog.Builder(activity).setTitle(t(pack.getString("nameKey"))).setView(ScrollView(activity).apply { addView(body) }).setPositiveButton(t("premium.done"), null).create()
    val animate = object : Runnable {
        override fun run() {
            portraits.forEach { it.frame = (it.frame + 1) % 4; it.invalidate() }
            if (dialog.isShowing) body.postDelayed(this, 150)
        }
    }
    dialog.setOnDismissListener { body.removeCallbacks(animate) }; dialog.show()
    if (!profile.getJSONObject("preferences").getBoolean("reducedMotion")) body.post(animate)
}

/** Preview of the existing cosmetic prism tracer; no combat-stat benefit. */
private class PrismPreviewView(context: android.content.Context) : android.view.View(context) {
    private val paint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
    override fun onDraw(canvas: android.graphics.Canvas) {
        super.onDraw(canvas)
        paint.strokeWidth = resources.displayMetrics.density * 7
        paint.shader = android.graphics.LinearGradient(0f, 0f, width.toFloat(), height.toFloat(), intArrayOf(android.graphics.Color.CYAN, android.graphics.Color.MAGENTA, Ui.gold), null, android.graphics.Shader.TileMode.CLAMP)
        canvas.drawLine(width * .1f, height * .7f, width * .9f, height * .3f, paint); paint.shader = null
    }
}
