package com.scrapsquad.fire

import android.graphics.*

/** Faithful Canvas translation of App/Views/SignatureRobotArt.swift.
 * Original 512-point geometry, palette, layering, four strides and victory pose.
 */
object SignatureRobotArt {
    private val cache = mutableMapOf<String, Bitmap>()
    @Synchronized fun image(skin: String, frame: Int = 0, victory: Boolean = false): Bitmap {
        require(skin in listOf("ronin", "bastion", "medic"))
        val key = "$skin-${frame % 4}-$victory"
        return cache.getOrPut(key) { render(skin, frame % 4, victory) }
    }
    private fun render(skin: String, frame: Int, victory: Boolean): Bitmap {
        val bitmap = Bitmap.createBitmap(512, 512, Bitmap.Config.ARGB_8888); val canvas = Canvas(bitmap)
        fun hex(value: String) = Color.parseColor("#$value")
        val ink = hex("10252D"); val gold = hex("FFBD55"); val blue = hex("83B9FF"); val pink = hex("F6B8DF"); val mint = hex("A5FFE1")
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { strokeJoin = Paint.Join.ROUND }
        fun shape(path: Path, color: Int) { paint.style = Paint.Style.FILL; paint.color = color; canvas.drawPath(path, paint); paint.style = Paint.Style.STROKE; paint.strokeWidth = 6f; paint.color = ink; canvas.drawPath(path, paint) }
        fun rect(x: Int, y: Int, w: Int, h: Int, color: Int, radius: Int = 12) { shape(Path().apply { addRoundRect(RectF(x.toFloat(), y.toFloat(), (x + w).toFloat(), (y + h).toFloat()), radius.toFloat(), radius.toFloat(), Path.Direction.CW) }, color) }
        fun oval(x: Int, y: Int, w: Int, h: Int, color: Int) { paint.style = Paint.Style.FILL; paint.color = color; canvas.drawOval(x.toFloat(), y.toFloat(), (x + w).toFloat(), (y + h).toFloat(), paint) }
        fun polygon(color: Int, vararg xy: Int) { val path = Path(); path.moveTo(xy[0].toFloat(), xy[1].toFloat()); for (i in 2 until xy.size step 2) path.lineTo(xy[i].toFloat(), xy[i + 1].toFloat()); path.close(); shape(path, color) }
        val tint = if (skin == "ronin") gold else if (skin == "bastion") blue else pink
        val stride = if (victory) 0 else intArrayOf(0, 8, 0, -8)[frame]
        oval(119, 444, 275, 32, Color.argb((.18 * 255).toInt(), 16, 37, 45))
        if (skin == "medic") {
            for (side in listOf(-1, 1)) {
                polygon(mint, 256 + side * 57, 256, 256 + side * 193, 184, 256 + side * 176, 307, 256 + side * 72, 337)
                rect(256 + side * 144 - 14, 220, 28, 69, Color.WHITE, 8)
            }
            paint.style = Paint.Style.STROKE; paint.strokeWidth = 12f; paint.color = mint; canvas.drawOval(161f, 60f, 351f, 94f, paint)
        }
        if (skin == "ronin") {
            polygon(hex("A43D47"), 154, 241, 122, 389, 214, 367, 262, 246)
            polygon(hex("E9F5F8"), 375, 164, 404, 183, 326, 385, 303, 373)
            rect(298, 353, 64, 18, gold, 5)
        }
        rect(179, 347 + stride, 64, 92, hex("304957")); rect(269, 347 - stride, 64, 92, hex("304957"))
        rect(163, 411 + stride, 86, 37, tint); rect(263, 411 - stride, 86, 37, tint)
        rect(121, if (victory) 152 else 258 + stride, 53, 111, tint, 18); rect(338, if (victory) 152 else 258 - stride, 53, 111, tint, 18)
        rect(166, 224, 180, 147, tint, if (skin == "bastion") 18 else 38)
        rect(188, 255, 136, 57, hex("293F50"), 14); rect(195, 326, 122, 20, if (tint == pink) mint else Color.WHITE, 5)
        if (skin == "bastion") {
            rect(95, 214, 92, 61, blue, 14); rect(325, 214, 92, 61, blue, 14)
            polygon(hex("4866AD"), 333, 270, 430, 259, 440, 358, 382, 407, 327, 355)
            polygon(blue, 350, 294, 408, 287, 411, 343, 381, 373, 349, 342)
            rect(136, 117, 240, 113, blue, 18); rect(189, 92, 134, 38, hex("D8E9FF"), 9)
        } else rect(161, 115, 190, 123, tint, 36)
        rect(178, 150, 156, 65, ink, 22)
        oval(202, 167, 24, 23, mint); oval(286, 167, 24, 23, mint)
        paint.style = Paint.Style.STROKE; paint.strokeWidth = 5f; paint.color = mint
        canvas.drawPath(Path().apply { moveTo(238f, 195f); quadTo(256f, if (victory) 217f else 205f, 276f, 195f) }, paint)
        when (skin) {
            "ronin" -> {
                polygon(gold, 162, 142, 134, 81, 210, 116, 256, 91, 300, 116, 376, 81, 350, 142)
                oval(238, 111, 36, 36, hex("E97043")); polygon(gold, 230, 268, 268, 268, 245, 291, 278, 291, 237, 320)
            }
            "medic" -> { rect(237, 103, 38, 53, Color.WHITE, 5); rect(228, 118, 56, 20, Color.WHITE, 4); rect(246, 263, 20, 43, mint, 3); rect(234, 275, 44, 19, mint, 3) }
            else -> { rect(229, 269, 54, 35, hex("D8E9FF"), 8); for (x in listOf(190, 310)) oval(x, 232, 12, 12, Color.WHITE) }
        }
        return bitmap
    }
}
