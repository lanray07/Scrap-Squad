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
    heading("synergy.title")
    listOf("thermalShock", "stormLattice", "perfectStorm").forEach { id -> label(t("synergy.$id"), 20f, Ui.mint); label(t("synergy.$id.detail")) }
    if (journal == null || journal.getJSONArray("recent").length() == 0) { label(t("journal.empty")); return }
    journal.getJSONObject("bestScores").keys().forEach { mode -> label("${t("mode.$mode")}: ${number(journal.getJSONObject("bestScores").getInt(mode))}", color = Ui.mint) }
    journal.getJSONArray("recent").objects().forEach { run ->
        separator(); val highlights = run.getJSONObject("highlights")
        val text = "${t(if (run.getBoolean("victory")) "battle.victory" else "battle.defeat")} · ${t("mode.${run.getString("mode")}")}\n${t("battle.score")}: ${number(run.getInt("score"))}\n${t("battle.kills")}: ${run.getInt("kills")} · ${t("momentum.best")}: ${highlights.getInt("bestCombo")}\n${highlights.optString("challengeCode", "")}"
        label(text, 20f, Ui.gold)
        val medals = menu.getJSONObject("runMedals").optJSONArray(run.getString("id"))?.strings().orEmpty()
        medals.forEach { label(t(it), color = Ui.mint) }
        var card: android.graphics.Bitmap? = null
        fun image() = card ?: RunCard.render(activity, run, content, strings, medals).also { card = it }
        button("run.preview") { RunCard.preview(activity, image(), strings) }
        button("run.share") { try { RunCard.share(activity, image(), run, strings) } catch (e: Exception) { error(e) } }
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
    button("android.privacy", BuildConfig.PRIVACY_POLICY_URL.startsWith("https://")) { activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(BuildConfig.PRIVACY_POLICY_URL))) }
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
    val purchases = activity.purchases
    val cosmetics = CosmeticRepository(activity)
    val ownership = cosmetics.state()
    val effective = ownership.getJSONArray("effectiveOwnership").strings().toSet()
    val selected = ownership.getJSONObject("selection")
    label(t(purchases.statusKey))
    button("shop.restore", purchases.ready) { purchases.restore() }
    button("shop.refresh") { purchases.refresh() }
    val catalog = JSONObject(activity.assets.open("generated/StoreConfiguration.json").bufferedReader().use { it.readText() })
    catalog.getJSONArray("packs").objects().forEach { pack ->
        separator(); label(t(pack.getString("nameKey")), 23f, Ui.gold); label(t(pack.getString("detailKey")))
        val id = pack.getString("id")
        pack.getJSONArray("finishes").objects().forEach { finish ->
            panel.addView(RobotPortraitView(activity, finish.getString("robotID"), finish), LinearLayout.LayoutParams(Ui.dp(activity, 150), Ui.dp(activity, 150)))
            if (id in effective) {
                val robot = finish.getString("robotID"); val equipped = selected.getJSONObject("robotFinishIDs").optString(robot) == finish.getString("id")
                button(if (equipped) "cosmetic.remove" else "cosmetic.equip", robot in profile.getJSONArray("unlockedRobots").strings()) { if (equipped) cosmetics.remove(robot) else cosmetics.equip(finish); show() }
            }
        }
        button("premium.preview") { premiumPreview(pack, catalog) }
        if (id in effective) label(t("cosmetic.owned"), color = Ui.mint)
        else {
            val price = purchases.price(id)
            if (price != null) label(price, 20f, Ui.gold)
            button("cosmetic.buy", purchases.ready && price != null && ownership.getJSONObject("canPurchase").getBoolean(id)) { purchases.purchase(id) }
        }
        label(t("cosmetic.once"))
    }
    if (ownership.getBoolean("founder")) listOf("goldenTrails" to "cosmetic.trails.enable", "founderBadge" to "cosmetic.badge.enable").forEach { (field, key) ->
        panel.addView(Switch(activity).apply { text = t(key); setTextColor(Ui.mint); isChecked = selected.getBoolean(field); setOnCheckedChangeListener { _, value -> cosmetics.toggle(field, value) } })
    }
    if ("prism" in ownership.getJSONArray("weaponEffects").strings()) {
        val equipped = selected.optString("weaponEffectID") == "prism"
        button(if (equipped) "cosmetic.remove" else "cosmetic.equip") { cosmetics.weaponEffect(if (equipped) null else "prism"); show() }
    }
    label(t("shop.note"))
}
