package com.scrapsquad.fire

import android.app.AlertDialog
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.widget.ImageView
import android.widget.ScrollView
import androidx.core.content.FileProvider
import org.json.JSONObject
import java.io.File
import java.text.NumberFormat

/** Canvas equivalent of the original 340-point RunCard, exported at 3x. */
internal object RunCard {
    fun render(context: Context, run: JSONObject, content: JSONObject, strings: Strings, medals: List<String>): Bitmap {
        val highlights = run.getJSONObject("highlights")
        data class Line(val text: String, val size: Float, val color: Int, val bold: Boolean = false)
        val lines = mutableListOf<Line>()
        fun line(key: String, size: Float = 14f, color: Int = Ui.mint, bold: Boolean = false) { lines.add(Line(strings.text(key), size, color, bold)) }
        line("battle.score", 12f, Ui.muted, true)
        val number = NumberFormat.getIntegerInstance()
        listOf("battle.kills" to run.getInt("kills"), "momentum.best" to highlights.getInt("bestCombo"), "battle.bosses" to run.getInt("bosses")).forEach { (key, value) -> lines.add(Line("${strings.text(key)}  ${number.format(value)}", 16f, Color.WHITE, true)) }
        content.getJSONArray("weapons").objects().firstOrNull { it.getString("id") == highlights.getString("weaponID") }?.let { line(it.getString("nameKey"), 17f, Ui.mint, true) }
        highlights.getJSONArray("synergies").strings().forEach { line("synergy.$it", 13f, Ui.gold, true) }
        highlights.optString("evolution").takeIf { it.isNotEmpty() && it != "null" }?.let { line("evolution.$it", 18f, Ui.mint, true) }
        if (highlights.optInt("perfectDodges") > 0) lines.add(Line("${strings.text("battle.perfectDodges")}  ${number.format(highlights.getInt("perfectDodges"))}", 16f, Color.WHITE, true))
        medals.forEach { line(it, 12f, Ui.gold, true) }
        highlights.optString("challengeCode").takeIf { it.isNotEmpty() && it != "null" }?.let { line("challenge.card", 12f, Ui.muted); lines.add(Line(it, 17f, Ui.mint, true)) }
        lines.add(Line("lanray07.github.io/Scrap-Squad", 10f, Ui.muted))
        fun paint(size: Float, color: Int, bold: Boolean = false) = TextPaint(Paint.ANTI_ALIAS_FLAG).apply { textSize = size; this.color = color; typeface = Typeface.create("sans-serif", if (bold) Typeface.BOLD else Typeface.NORMAL) }
        fun layout(line: Line) = StaticLayout.Builder.obtain(line.text, 0, line.text.length, paint(line.size, line.color, line.bold), 292).setAlignment(Layout.Alignment.ALIGN_NORMAL).setIncludePad(false).build()
        val layouts = lines.map(::layout)
        val title = strings.text(if (run.getBoolean("victory")) "battle.victory" else "battle.defeat")
        val titleLayout = StaticLayout.Builder.obtain(title, 0, title.length, paint(25f, Color.WHITE, true), 206).setIncludePad(false).build()
        val headerBottom = 75f + titleLayout.height + 46f
        val scoreBaseline = headerBottom + 74f
        val contentStart = scoreBaseline + 20f
        val cardHeight = contentStart.toInt() + layouts.sumOf { it.height + 14 } + 24
        val bitmap = Bitmap.createBitmap(1020, cardHeight * 3, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap); canvas.scale(3f, 3f)
        val background = Paint(Paint.ANTI_ALIAS_FLAG).apply { shader = LinearGradient(0f, 0f, 340f, cardHeight.toFloat(), Ui.surface, Ui.ink, Shader.TileMode.CLAMP) }
        canvas.drawRoundRect(0f, 0f, 340f, cardHeight.toFloat(), 24f, 24f, background)
        canvas.drawText("SCRAP SQUAD", 24f, 41f, paint(17f, Color.WHITE, true))
        canvas.drawText("MERGE & SURVIVE", 232f, 40f, paint(8f, Ui.muted, true))
        canvas.save(); canvas.translate(24f, 75f); titleLayout.draw(canvas); canvas.restore()
        canvas.drawText(strings.text("mode.${run.getString("mode")}"), 24f, headerBottom - 24f, paint(12f, Ui.mint))
        val biome = content.getJSONArray("biomes").getJSONObject(run.getInt("zone").coerceIn(0, content.getJSONArray("biomes").length() - 1))
        canvas.drawText(strings.text(biome.getString("nameKey")), 24f, headerBottom - 4f, paint(12f, Ui.muted))
        val robotTop = 75f + (headerBottom - 75f - 86f) / 2
        OriginalRobotArt.draw(context, canvas, "bolt", RectF(230f, robotTop, 316f, robotTop + 86f), Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG))
        val score = number.format(run.getInt("score")); val scorePaint = paint(54f, Ui.gold, true)
        while (scorePaint.measureText(score) > 292 && scorePaint.textSize > 27) scorePaint.textSize -= 1
        canvas.drawText(score, 24f, scoreBaseline, scorePaint)
        var y = contentStart
        layouts.forEach { value -> canvas.save(); canvas.translate(24f, y); value.draw(canvas); canvas.restore(); y += value.height + 14 }
        canvas.drawRoundRect(.5f, .5f, 339.5f, cardHeight - .5f, 24f, 24f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Ui.gold; alpha = 115; style = Paint.Style.STROKE; strokeWidth = 1f })
        return bitmap
    }
    fun preview(context: Context, bitmap: Bitmap, strings: Strings) {
        val image = ImageView(context).apply { setImageBitmap(bitmap); adjustViewBounds = true; contentDescription = strings.text("run.preview") }
        AlertDialog.Builder(context).setTitle(strings.text("run.preview")).setView(ScrollView(context).apply { addView(image) }).setPositiveButton(strings.text("common.done"), null).show()
    }
    fun share(context: Context, bitmap: Bitmap, run: JSONObject, strings: Strings) {
        val folder = File(context.cacheDir, "run-cards").apply { mkdirs() }
        val id = run.getString("id").replace(Regex("[^A-Za-z0-9-]"), "")
        val file = File(folder, "$id.png")
        file.outputStream().use { check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)) }
        folder.listFiles()?.filter { it != file }?.sortedByDescending { it.lastModified() }?.drop(19)?.forEach { it.delete() }
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.files", file)
        val text = run.getJSONObject("highlights").optString("challengeCode").takeIf { it != "null" }.orEmpty() + "\nhttps://lanray07.github.io/Scrap-Squad/"
        val send = Intent(Intent.ACTION_SEND).setType("image/png").putExtra(Intent.EXTRA_STREAM, uri).putExtra(Intent.EXTRA_TEXT, text).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        send.clipData = ClipData.newUri(context.contentResolver, "Scrap Squad", uri)
        context.startActivity(Intent.createChooser(send, strings.text("run.share")))
    }
}
