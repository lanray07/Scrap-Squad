package com.scrapsquad.fire

import android.content.ContentValues
import android.content.Context
import android.graphics.*
import android.provider.MediaStore

/** Build-time export of the authorized originals, not replacement artwork. */
internal object StoreArtExporter {
    fun export(context: Context) {
        fun save(name: String, bitmap: Bitmap) {
            val values = ContentValues().apply { put(MediaStore.Downloads.DISPLAY_NAME, name); put(MediaStore.Downloads.MIME_TYPE, "image/png"); put(MediaStore.Downloads.IS_PENDING, 1) }
            val uri = checkNotNull(context.contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values))
            context.contentResolver.openOutputStream(uri)!!.use { check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)) }
            context.contentResolver.update(uri, ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }, null, null)
        }
        val original = BitmapFactory.decodeResource(context.resources, R.drawable.app_icon, BitmapFactory.Options().apply { inScaled = false })
        for (size in listOf(114, 512)) {
            val bitmap = Bitmap.createScaledBitmap(original, size, size, true)
            save("scrap-squad-icon-$size.png", bitmap)
            if (bitmap !== original) bitmap.recycle()
        }
        original.recycle()
        val promo = Bitmap.createBitmap(1024, 500, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(promo)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG).apply { shader = LinearGradient(0f, 0f, 1024f, 500f, Ui.surface, Ui.ink, Shader.TileMode.CLAMP) }
        canvas.drawRect(0f, 0f, 1024f, 500f, paint); paint.shader = null
        paint.color = Ui.gold; paint.alpha = 28; canvas.drawCircle(793f, 240f, 205f, paint); paint.alpha = 255
        OriginalRobotArt.draw(context, canvas, "tank", RectF(477f, 145f, 777f, 445f), paint)
        OriginalRobotArt.draw(context, canvas, "patch", RectF(780f, 180f, 1010f, 410f), paint)
        OriginalRobotArt.draw(context, canvas, "bolt", RectF(612f, 65f, 992f, 445f), paint)
        paint.typeface = Typeface.create("sans-serif", Typeface.BOLD); paint.textSize = 84f; paint.color = Ui.gold
        canvas.drawText("SCRAP", 70f, 199f, paint); canvas.drawText("SQUAD", 70f, 286f, paint)
        paint.color = Ui.mint; paint.textSize = 27f; canvas.drawText("MERGE & SURVIVE", 75f, 340f, paint)
        save("scrap-squad-promo.png", promo); promo.recycle()
    }
}
