package com.scrapsquad.fire

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import com.badlogic.gdx.graphics.Pixmap
import com.badlogic.gdx.graphics.Texture
import com.badlogic.gdx.graphics.g2d.BitmapFont
import com.badlogic.gdx.graphics.g2d.TextureRegion
import java.io.ByteArrayOutputStream

/** Rasterize once at high resolution; never enlarge the bundled tiny bitmap font. */
object BattleNumberFont {
    fun create(): BitmapFont {
        val bitmap = Bitmap.createBitmap(256, 256, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.WHITE
            textSize = 52f
            typeface = Typeface.create("sans-serif", Typeface.BOLD)
        }
        val data = BitmapFont.BitmapFontData().apply {
            lineHeight = 64f; capHeight = 38f; ascent = 0f; descent = -12f; down = -64f
        }
        "0123456789-".forEachIndexed { index, character ->
            val left = index % 4 * 64; val top = index / 4 * 64
            canvas.drawText(character.toString(), left + 2f, top + 54f, paint)
            data.setGlyph(character.code, BitmapFont.Glyph().apply {
                id = character.code; srcX = left; srcY = top
                width = 64; height = 64; xoffset = -2; yoffset = -54
                xadvance = kotlin.math.ceil(paint.measureText(character.toString())).toInt()
            })
        }
        val bytes = ByteArrayOutputStream().also { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }.toByteArray()
        bitmap.recycle()
        val pixmap = Pixmap(bytes, 0, bytes.size)
        val texture = Texture(pixmap); pixmap.dispose()
        texture.setFilter(Texture.TextureFilter.Linear, Texture.TextureFilter.Linear)
        return BitmapFont(data, TextureRegion(texture), false).apply { setOwnsTexture(true) }
    }
}
