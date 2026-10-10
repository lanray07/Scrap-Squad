package com.scrapsquad.fire

import android.content.Intent
import android.view.Gravity
import android.view.View
import android.widget.*
import org.json.JSONArray
import org.json.JSONObject
import java.text.NumberFormat

internal fun JSONArray.objects(): List<JSONObject> = (0 until length()).map { getJSONObject(it) }
internal fun JSONArray.strings(): List<String> = (0 until length()).map { getString(it) }

class MenuScreens(internal val activity: MainActivity, internal val repository: GameRepository, internal val strings: Strings) {
    var page = "city"
    internal lateinit var panel: LinearLayout
    internal lateinit var menu: JSONObject
    internal val profile get() = repository.profile
    internal val content get() = repository.content
    internal fun t(key: String) = strings.text(key)
    internal fun number(value: Int) = NumberFormat.getIntegerInstance().format(value)
    internal fun label(value: String, size: Float = 16f, color: Int = Ui.muted) { panel.addView(Ui.text(activity, value, size, color)) }
    internal fun heading(key: String, detail: String? = null) { label(t(key), 28f, Ui.gold); if (detail != null) label(t(detail)) }
    internal fun button(key: String, enabled: Boolean = true, action: () -> Unit): Button = Ui.button(activity, t(key), action).also { it.isEnabled = enabled; panel.addView(it) }
    internal fun action(op: String, vararg args: Pair<String, Any>, after: (() -> Unit)? = null) {
        try { repository.action(op, *args); if (op == "fuse" || op == "roulette") activity.playCue("fusion"); show(); after?.invoke() } catch (e: Exception) { error(e) }
    }
    internal fun error(e: Exception) {
        val message = runCatching { t("error.${e.message}") }.getOrElse { t("common.error") }
        PremiumDialog.Builder(activity).setTitle(t("common.error")).setMessage(message).setPositiveButton(t("common.ok"), null).show()
    }
    internal fun separator() { panel.addView(View(activity).apply { setBackgroundColor(Ui.surface); layoutParams = LinearLayout.LayoutParams(-1, Ui.dp(activity, 2)).apply { setMargins(0, 16, 0, 16) } }) }
    internal fun owns(group: String, id: String) = profile.getJSONObject(group).optInt(id) > 0
    internal fun item(group: String, id: String) = content.getJSONArray(group).objects().first { it.getString("id") == id }
    internal fun spinner(ids: List<String>, labels: List<String>, selected: String? = null): Spinner = Spinner(activity).apply {
        adapter = ArrayAdapter(activity, android.R.layout.simple_spinner_dropdown_item, labels)
        if (selected != null) setSelection(ids.indexOf(selected).coerceAtLeast(0))
        panel.addView(this)
    }
    fun show() {
        strings.language = profile.getJSONObject("preferences").getString("locale")
        menu = repository.action("menu").getJSONObject("menu")
        val root = Ui.panel(activity); Ui.fitInsets(root)
        root.addView(Ui.text(activity, "SCRAP SQUAD", 23f, Ui.gold))
        root.addView(Ui.text(activity, listOf("scrap", "credits", "cores").joinToString("   ") { "${t("currency.$it")} ${number(profile.getInt(it))}" }, 14f, Ui.mint))
        val tabs = LinearLayout(activity).apply { orientation = LinearLayout.HORIZONTAL }
        listOf("city", "squad", "battle", "blueprints", "shop").forEach { tab ->
            tabs.addView(Ui.button(activity, t("nav.$tab")) { page = tab; show() }.apply {
                textSize = 12f; alpha = if (page == tab) 1f else .7f
                layoutParams = LinearLayout.LayoutParams(0, -2, 1f).apply { setMargins(3, 8, 3, 8) }
            })
        }
        root.addView(tabs); panel = Ui.panel(activity)
        val container = FrameLayout(activity).apply { addView(panel, FrameLayout.LayoutParams(Ui.dp(activity, 760).coerceAtMost(activity.resources.displayMetrics.widthPixels), -2, Gravity.CENTER_HORIZONTAL)) }
        root.addView(ScrollView(activity).apply { addView(container) }, LinearLayout.LayoutParams(-1, 0, 1f))
        when (page) { "city" -> city(); "squad" -> squad(); "battle" -> battle(); "blueprints" -> blueprints(); "workshop" -> workshop(); "journal" -> journal(); "settings" -> settings(); "shop" -> shop() }
        val footer = LinearLayout(activity)
        listOf("city" to "nav.city", "settings" to "settings.title").forEach { (destination, key) -> footer.addView(Ui.button(activity, t(key)) { page = destination; show() }, LinearLayout.LayoutParams(0, -2, 1f)) }
        root.addView(footer); activity.setContentView(root)
    }
    fun offerOffline() {
        val reward = menu.getJSONObject("offline")
        if (reward.getInt("scrap") == 0 && reward.getInt("credits") == 0) return
        PremiumDialog.Builder(activity).setTitle(t("offline.title"))
            .setCharacter("bolt", t("premium.victory"))
            .setMessage("${t("offline.description")}\n${t("offline.away")}: ${reward.getDouble("seconds").toInt() / 60} ${t("android.minutes")}\n${t("currency.scrap")}: ${number(reward.getInt("scrap"))}\n${t("currency.credits")}: ${number(reward.getInt("credits"))}")
            .setPositiveButton(t("offline.claim")) { _, _ -> action("offline") }.setCancelable(false).show()
    }
    internal fun share(text: String) { activity.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text), t("run.share"))) }
}
