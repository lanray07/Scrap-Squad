package com.scrapsquad.fire

import android.app.AlertDialog
import android.content.Intent
import android.net.Uri
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.SeekBar
import android.widget.Switch
import org.json.JSONObject
import java.util.Locale

internal fun MenuScreens.battle() {
    heading("battle.title", "battle.subtitle")
    val zones = (0..profile.getInt("zone")).map(Int::toString)
    label(t("battle.zone")); val zone = spinner(zones, zones.map { t(content.getJSONArray("biomes").getJSONObject(it.toInt()).getString("nameKey")) })
    val modes = listOf("campaign", "survival", "bossRush", "scrapRun", "fusionLab", "dailyAnomaly", "arena")
    label(t("battle.mode")); val mode = spinner(modes, modes.map { t("mode.$it") })
    label("${t("battle.weapon")}: ${t(item("weapons", profile.getString("equippedWeapon")).getString("nameKey"))}", 20f, Ui.mint)
    val row = LinearLayout(activity)
    profile.getJSONArray("squad").strings().forEach { row.addView(RobotPortraitView(activity, it), LinearLayout.LayoutParams(Ui.dp(activity, 78), Ui.dp(activity, 78))) }; panel.addView(row)
    button("battle.deploy") { activity.deploy(modes[mode.selectedItemPosition], zone.selectedItemPosition) }
    label(t("battle.move")); label(t("battle.excitement.note")); label(t("battle.survival.note"))
    separator(); heading("challenge.title", "challenge.detail")
    val daily = menu.getString("dailyChallenge"); label(daily, 20f, Ui.gold)
    button("challenge.daily") { activity.deploy("dailyAnomaly", 0, daily) }
    button("challenge.share") { share(daily + "\nhttps://lanray07.github.io/Scrap-Squad/") }
    val input = EditText(activity).apply { hint = t("challenge.placeholder"); setTextColor(Ui.mint); isSingleLine = true }; panel.addView(input)
    button("challenge.play") { try { val code = input.text.toString().trim().uppercase(Locale.ROOT); NativeCore.call("challenge", "id" to code); activity.deploy("dailyAnomaly", 0, code) } catch (e: Exception) { error(e) } }
    label(t("challenge.local"))
}

internal fun MenuScreens.journal() {
    heading("journal.title", "journal.detail"); heading("mastery.title")
    menu.getJSONArray("mastery").objects().forEach { label("${t(it.getString("key"))}: ${it.getInt("progress")} / ${it.getInt("goal")}") }
    val journal = profile.optJSONObject("journal")
    if (journal == null || journal.getJSONArray("recent").length() == 0) { label(t("journal.empty")); return }
    journal.getJSONObject("bestScores").keys().forEach { mode -> label("${t("mode.$mode")}: ${number(journal.getJSONObject("bestScores").getInt(mode))}", color = Ui.mint) }
    journal.getJSONArray("recent").objects().forEach { run ->
        separator(); val highlights = run.getJSONObject("highlights")
        val text = "${t(if (run.getBoolean("victory")) "battle.victory" else "battle.defeat")} · ${t("mode.${run.getString("mode")}")}\n${t("battle.score")}: ${number(run.getInt("score"))}\n${t("battle.kills")}: ${run.getInt("kills")} · ${t("momentum.best")}: ${highlights.getInt("bestCombo")}\n${highlights.optString("challengeCode", "")}"
        label(text, 20f, Ui.gold)
        menu.getJSONObject("runMedals").optJSONArray(run.getString("id"))?.strings()?.forEach { label(t(it), color = Ui.mint) }
        button("run.share") { share("Scrap Squad\n$text\nhttps://lanray07.github.io/Scrap-Squad/") }
    }
}

internal fun MenuScreens.settings() {
    heading("settings.title")
    listOf("haptics" to "haptics", "motion" to "reducedMotion", "flashes" to "reducedFlashes", "shake" to "screenShake", "numbers" to "damageNumbers").forEach { (key, field) ->
        panel.addView(Switch(activity).apply { text = t("settings.$key"); setTextColor(Ui.mint); isChecked = profile.getJSONObject("preferences").getBoolean(field); setOnCheckedChangeListener { _, checked -> preference(field, checked) } })
    }
    listOf("particles" to "particleIntensity", "master" to "masterVolume", "music" to "musicVolume", "sfx" to "sfxVolume").forEach { (key, field) ->
        label(t("settings.$key"))
        panel.addView(SeekBar(activity).apply { max = 100; progress = (profile.getJSONObject("preferences").getDouble(field) * 100).toInt(); contentDescription = t("settings.$key")
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(bar: SeekBar?, value: Int, user: Boolean) {}
                override fun onStartTrackingTouch(bar: SeekBar?) {}
                override fun onStopTrackingTouch(bar: SeekBar) { preference(field, bar.progress / 100.0) }
            }) })
    }
    label(t("settings.language")); val languages = listOf("system") + strings.availableLanguages()
    val language = spinner(languages, languages.map { if (it == "system") t("settings.system") else Locale.forLanguageTag(it).getDisplayName(Locale.forLanguageTag(it)) }, profile.getJSONObject("preferences").getString("locale"))
    button("common.done") { preference("locale", languages[language.selectedItemPosition]); show() }
    button("android.privacy") { activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://lanray07.github.io/Scrap-Squad/privacy.html"))) }
    button("android.support") { activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/lanray07/Scrap-Squad/issues"))) }
    heading("achievements.title")
    menu.getJSONObject("achievements").keys().forEach { id -> label("${t("achievement.$id")}: ${menu.getJSONObject("achievements").getDouble(id).toInt()}%") }
    separator(); heading("settings.reboot", "settings.reboot.detail")
    button("settings.reboot.confirm", profile.getInt("zone") >= content.getJSONObject("economy").getInt("rebootZone")) {
        AlertDialog.Builder(activity).setTitle(t("settings.reboot")).setMessage(t("settings.reboot.detail")).setNegativeButton(t("common.cancel"), null)
            .setPositiveButton(t("settings.reboot.confirm")) { _, _ -> action("reboot") }.show()
    }
}
private fun MenuScreens.preference(field: String, value: Any) {
    try { repository.action("preferences", "value" to JSONObject(profile.getJSONObject("preferences").toString()).put(field, value)); activity.refreshAudio() } catch (e: Exception) { error(e) }
}

internal fun MenuScreens.shop() {
    heading("shop.title", "shop.subtitle")
    val catalog = JSONObject(activity.assets.open("generated/StoreConfiguration.json").bufferedReader().use { it.readText() })
    catalog.getJSONArray("packs").objects().forEach { pack ->
        separator(); label(t(pack.getString("nameKey")), 23f, Ui.gold); label(t(pack.getString("detailKey")))
        pack.getJSONArray("finishes").objects().forEach { finish -> panel.addView(RobotPortraitView(activity, finish.getString("robotID"), finish), LinearLayout.LayoutParams(Ui.dp(activity, 150), Ui.dp(activity, 150))) }
        button("premium.preview") { premiumPreview(pack, catalog) }
        label(t("shop.unavailable")); label(t("cosmetic.once"))
    }
    label(t("shop.note"))
}
