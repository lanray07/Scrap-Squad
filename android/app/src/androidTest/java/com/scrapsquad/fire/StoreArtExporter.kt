package com.scrapsquad.fire

import android.content.ContentValues
import android.content.Context
import android.graphics.*
import android.provider.MediaStore

/** Build-time export of the authorized originals, not replacement artwork. */
internal object StoreArtExporter {
    fun export(context: Context) {
        fun save(name: String, bitmap: Bitmap) {
            if (android.os.Build.VERSION.SDK_INT < 29) {
                val file = java.io.File(context.getExternalFilesDir(null), name)
                file.outputStream().use { check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)) }
                return
            }
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
        val catalog = org.json.JSONObject(context.assets.open("generated/StoreConfiguration.json").bufferedReader().use { it.readText() })
        val packs = catalog.getJSONArray("packs").objects()
        for (pack in packs) {
            val icon = Bitmap.createBitmap(512, 512, Bitmap.Config.ARGB_8888)
            val art = Canvas(icon)
            paint.shader = LinearGradient(0f, 0f, 512f, 512f, Ui.surface, Ui.ink, Shader.TileMode.CLAMP)
            art.drawRoundRect(RectF(0f, 0f, 512f, 512f), 64f, 64f, paint); paint.shader = null
            val included = listOf(pack) + (pack.optJSONArray("includes")?.strings() ?: emptyList()).map { id -> packs.first { it.getString("id") == id } }
            val finishes = included.flatMap { it.getJSONArray("finishes").objects() }.distinctBy { it.getString("id") }
            finishes.take(3).forEachIndexed { index, finish ->
                val size = if (finishes.size == 1) 440 else 300
                val portrait = RobotPortraitView(context, finish.getString("robotID"), finish)
                portrait.layout(0, 0, size, size)
                art.save()
                art.translate(if (finishes.size == 1) 36f else listOf(12f, 200f, 108f)[index], if (finishes.size == 1) 36f else listOf(160f, 160f, 16f)[index])
                portrait.draw(art); art.restore()
            }
            if (pack.optString("weaponEffect") == "prism" || finishes.isEmpty()) {
                paint.shader = LinearGradient(60f, 360f, 452f, 152f, intArrayOf(Color.CYAN, Color.MAGENTA, Ui.gold), null, Shader.TileMode.CLAMP)
                paint.strokeWidth = 24f; art.drawLine(60f, 360f, 452f, 152f, paint); paint.shader = null
            }
            val id = pack.getString("id").substringAfterLast('.')
            save("scrap-squad-iap-$id-512.png", icon)
            val small = Bitmap.createScaledBitmap(icon, 114, 114, true)
            save("scrap-squad-iap-$id-114.png", small); small.recycle(); icon.recycle()
        }
    }
}
