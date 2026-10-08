package com.scrapsquad.fire

import android.content.Context
import android.graphics.*
import android.view.View
import org.json.JSONObject

internal object OriginalRobotArt {
    private var atlas: Bitmap? = null
    private val order = listOf("bolt", "tank", "zip", "patch", "nova", "boomer", "glitch", "magnet")
    @Synchronized fun atlas(context: Context): Bitmap = atlas ?: context.assets.open("generated/RobotAtlas.png").use { BitmapFactory.decodeStream(it) }.also { atlas = it }
    fun draw(context: Context, canvas: Canvas, id: String, target: RectF, paint: Paint) {
        val bitmap = atlas(context); val index = order.indexOf(id).coerceAtLeast(0); val w = bitmap.width / 4; val h = bitmap.height / 2
        canvas.drawBitmap(bitmap, Rect(index % 4 * w, index / 4 * h, (index % 4 + 1) * w, (index / 4 + 1) * h), target, paint)
    }
}

class RobotPortraitView(context: Context, private val id: String, private val finish: JSONObject? = null) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
    var frame = 0
    var victory = false
    init { contentDescription = Strings(context).text("robot.$id") }
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas); val dimension = minOf(width, height).toFloat()
        val target = RectF((width - dimension) / 2, (height - dimension) / 2, (width + dimension) / 2, (height + dimension) / 2)
        val skin = finish?.optString("skin")?.takeIf { it.isNotEmpty() }
        if (skin != null) { canvas.drawBitmap(SignatureRobotArt.image(skin, frame, victory), null, target, paint); return }
        if (finish != null) {
            val tint = Color.parseColor("#${finish.getString("tint")}")
            paint.colorFilter = ColorMatrixColorFilter(ColorMatrix().apply { setScale(Color.red(tint) / 255f, Color.green(tint) / 255f, Color.blue(tint) / 255f, 1f) })
        }
        OriginalRobotArt.draw(context, canvas, id, target, paint); paint.colorFilter = null
        if (finish != null) {
            val cx = target.right - dimension * .14f; val cy = target.bottom - dimension * .14f; val radius = dimension * .12f
            paint.color = Ui.ink; canvas.drawCircle(cx, cy, radius, paint)
            paint.style = Paint.Style.STROKE; paint.strokeWidth = dimension * .015f; paint.color = Color.parseColor("#${finish.getString("tint")}"); canvas.drawCircle(cx, cy, radius, paint)
            paint.color = Color.parseColor("#${finish.getString("accent")}"); paint.style = Paint.Style.FILL
            val emblem = Path(); val points = if (finish.getString("symbol").contains("diamond")) 4 else 10
            for (i in 0 until points) { val angle = i * Math.PI * 2 / points - Math.PI / 2; val r = radius * if (points == 4 || i % 2 == 0) .65 else .3; val x = cx + kotlin.math.cos(angle).toFloat() * r.toFloat(); val y = cy + kotlin.math.sin(angle).toFloat() * r.toFloat(); if (i == 0) emblem.moveTo(x, y) else emblem.lineTo(x, y) }; emblem.close(); canvas.drawPath(emblem, paint)
        }
    }
}

/** Android Canvas equivalent of RootView.CityIllustration; no replacement assets. */
class CityArtView(context: Context, private val content: JSONObject, private val profile: JSONObject) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas); canvas.save(); canvas.scale(width / 380f, height / 240f)
        paint.shader = LinearGradient(0f, 0f, 380f, 240f, Color.rgb(50, 83, 97), Ui.ink, Shader.TileMode.CLAMP)
        canvas.drawRoundRect(0f, 0f, 380f, 240f, 28f, 28f, paint); paint.shader = null
        paint.color = Ui.gold; paint.alpha = 204; canvas.drawCircle(290f, 65f, 35f, paint); paint.alpha = 255
        content.getJSONArray("buildings").objects().take(6).forEachIndexed { index, building ->
            val level = profile.getJSONObject("buildingLevels").optInt(building.getString("id")); val x = 380f * (index % 3 + .5f) / 3; val y = if (index < 3) 120f else 193f; val h = 55f + level * 5
            paint.color = if (level > 0) Ui.surface else Color.rgb(48, 64, 71); canvas.drawRoundRect(x - 32, y - h / 2, x + 32, y + h / 2, 12f, 12f, paint)
            paint.color = if (level > 0) Ui.gold else Ui.muted
            for (window in 0..3) { val wx = x - 15 + window % 2 * 23; val wy = y - 12 + window / 2 * 21; canvas.drawRoundRect(wx, wy, wx + 8, wy + 9, 2f, 2f, paint) }
            paint.color = Ui.muted; paint.alpha = 77; canvas.drawRect(x - 36, y + h / 2, x + 36, y + h / 2 + 8, paint); paint.alpha = 255
        }
        OriginalRobotArt.draw(context, canvas, "bolt", RectF(152.5f, 162.5f, 227.5f, 237.5f), paint); canvas.restore()
    }
}
