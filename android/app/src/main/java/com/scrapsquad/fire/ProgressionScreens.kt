package com.scrapsquad.fire

import android.app.AlertDialog
import android.widget.*
import java.security.SecureRandom
import java.text.NumberFormat
import org.json.JSONObject

internal fun MenuScreens.city() {
    heading("city.title", "city.subtitle")
    panel.addView(CityArtView(activity, content, profile), LinearLayout.LayoutParams(-1, Ui.dp(activity, 240)))
    label("${t("city.level")} ${number(menu.getInt("cityLevel"))}", 20f, Ui.mint)
    button("city.workshop") { page = "workshop"; show() }; button("journal.open") { page = "journal"; show() }
    content.getJSONArray("buildings").objects().forEach { building ->
        separator(); val id = building.getString("id"); val level = profile.getJSONObject("buildingLevels").optInt(id)
        label(t(building.getString("nameKey")), 21f, Ui.gold); label(t(building.getString("descriptionKey")))
        label("${t("city.level.label")} $level", color = Ui.mint)
        if (level < building.getInt("maxLevel")) {
            val cost = menu.getJSONObject("buildingCosts").getInt(id); label("${t("currency.scrap")}: ${number(cost)}")
            button("city.upgrade", profile.getInt("scrap") >= cost) { action("building", "id" to id) }
        } else label(t("common.max"))
    }
    separator(); heading("city.missions")
    listOf(false, true).forEach { weekly ->
        val progress = profile.getInt(if (weekly) "weeklyBosses" else "dailyKills"); val goal = if (weekly) 3 else 60
        val claimed = profile.getBoolean(if (weekly) "weeklyClaimed" else "dailyClaimed")
        label(t(if (weekly) "mission.weekly" else "mission.daily"), 18f, Ui.gold); label("${progress.coerceAtMost(goal)} / $goal")
        button(if (claimed) "mission.claimed" else "mission.claim", progress >= goal && !claimed) { action("mission", "weekly" to weekly) }
    }
    label(t("mission.note"))
}
internal fun MenuScreens.squad() {
    heading("squad.title", "squad.subtitle")
    label("${profile.getJSONArray("squad").length()} / ${menu.getInt("squadCapacity")}", color = Ui.mint); label(t("squad.commander"))
    content.getJSONArray("robots").objects().forEach { robot ->
        separator(); val id = robot.getString("id"); val unlocked = id in profile.getJSONArray("unlockedRobots").strings()
        panel.addView(RobotPortraitView(activity, id).apply { alpha = if (unlocked) 1f else .4f }, LinearLayout.LayoutParams(Ui.dp(activity, 120), Ui.dp(activity, 120)))
        label(t(robot.getString("nameKey")), 23f, Ui.gold); label(t(robot.getString("personalityKey")))
        label(t("rarity.${robot.getString("rarity")}"), color = Ui.mint)
        label("${t("city.level.label")} ${profile.getJSONObject("robotLevels").optInt(id, 1)}")
        label(t("squad.passive"), color = Ui.gold); label(t(robot.getString("passiveKey")))
        label(t("squad.active"), color = Ui.gold); label(t(robot.getString("activeKey")))
        val cost = menu.getJSONObject("robotCosts").getInt(id); label("${t("currency.credits")}: ${number(cost)}")
        button(if (unlocked) "squad.upgrade" else "squad.unlock", profile.getInt("credits") >= cost && profile.getJSONObject("robotLevels").optInt(id, 1) < 50) { action("robot", "id" to id) }
        if (unlocked) button(if (id in profile.getJSONArray("squad").strings()) "squad.remove" else "squad.add") { action("squad", "id" to id) }
    }
}
internal fun MenuScreens.workshop() {
    heading("lab.title", "lab.subtitle")
    content.getJSONArray("recipes").objects().forEach { recipe ->
        separator(); val result = item("weapons", recipe.getString("result"))
        label(t(result.getString("nameKey")), 22f, Ui.gold)
        label("${t("weapon.${recipe.getString("weapon")}")} + ${t("component.${recipe.getString("component")}")}")
        label("${number(recipe.getInt("scrapCost"))} ${t("currency.scrap")}")
        button("lab.fuse", profile.getInt("scrap") >= recipe.getInt("scrapCost") && owns("weapons", recipe.getString("weapon")) && owns("components", recipe.getString("component"))) {
            action("fuse", "id" to recipe.getString("id"), after = { reveal(result) })
        }
    }
    separator(); heading("lab.roulette", "lab.roulette.note")
    val owned = content.getJSONArray("weapons").objects().filter { owns("weapons", it.getString("id")) }
    val ids = owned.map { it.getString("id") }; val names = owned.map { t(it.getString("nameKey")) }
    val a = spinner(ids, names); val b = spinner(ids, names, ids.getOrNull(1))
    button("lab.spin", owned.size >= 2 && profile.getInt("cores") > 0) {
        try {
            val first = ids[a.selectedItemPosition]; val second = ids[b.selectedItemPosition]
            val options = NativeCore.call("roulettePreview", "a" to first, "b" to second).getJSONArray("candidates").strings()
            if (options.isEmpty()) throw IllegalStateException("invalidSelection")
            AlertDialog.Builder(activity).setTitle(t("lab.roulette")).setMessage(options.joinToString("\n") { "${t("weapon.$it")} · ${NumberFormat.getPercentInstance().apply { maximumFractionDigits = 1 }.format(1.0 / options.size)}" })
                .setNegativeButton(t("common.cancel"), null).setPositiveButton(t("lab.spin")) { _, _ -> val index = SecureRandom().nextInt(options.size); action("roulette", "a" to first, "b" to second, "index" to index, after = { reveal(item("weapons", options[index])) }) }.show()
        } catch (e: Exception) { error(e) }
    }
    separator(); heading("lab.components")
    content.getJSONArray("components").objects().forEach { label("${t(it.getString("nameKey"))}: ${profile.getJSONObject("components").optInt(it.getString("id"))}") }
    separator(); heading("lab.inventory")
    owned.forEach { weapon ->
        val id = weapon.getString("id"); label("${t(weapon.getString("nameKey"))} × ${profile.getJSONObject("weapons").optInt(id)}", 20f, Ui.gold)
        button("lab.equip", profile.getString("equippedWeapon") != id) { action("equip", "id" to id) }
        val cost = menu.getJSONObject("weaponCosts").getInt(id); label("${t("currency.scrap")}: ${number(cost)}")
        button("lab.upgrade", profile.getInt("scrap") >= cost && profile.getJSONObject("weaponLevels").optInt(id, 1) < 30) { action("weapon", "id" to id) }
    }
}
internal fun MenuScreens.reveal(weapon: JSONObject) {
    AlertDialog.Builder(activity).setTitle(t("lab.reveal")).setMessage("${t(weapon.getString("nameKey"))}\n${t("rarity.${weapon.getString("rarity")}")}\n${t(weapon.getString("descriptionKey"))}")
        .setPositiveButton(t("lab.equip")) { _, _ -> action("equip", "id" to weapon.getString("id")) }
        .setNegativeButton(t("common.done"), null).setNeutralButton(t("lab.share")) { _, _ -> share("Scrap Squad\n${t(weapon.getString("nameKey"))}\nhttps://lanray07.github.io/Scrap-Squad/") }.show()
}
internal fun MenuScreens.blueprints() {
    heading("lab.database", "lab.subtitle"); label("${profile.getJSONArray("blueprints").length()} / ${content.getJSONArray("recipes").length()}", 26f, Ui.mint)
    val elements = content.getJSONArray("weapons").objects().map { it.getString("element") }.distinct()
    val filter = spinner(listOf("") + elements, listOf(t("lab.database")) + elements.map { t("element.$it") })
    val results = Ui.panel(activity); panel.addView(results)
    fun render(element: String?) {
        results.removeAllViews()
        content.getJSONArray("recipes").objects().filter { element == null || item("weapons", it.getString("result")).getString("element") == element }.forEach { recipe ->
            val known = recipe.getString("id") in profile.getJSONArray("blueprints").strings()
            results.addView(Ui.text(activity, t(if (known) "weapon.${recipe.getString("result")}" else "lab.unknown"), 22f, Ui.gold))
            results.addView(Ui.text(activity, t(recipe.getString("clueKey"))))
            if (known) results.addView(Ui.text(activity, t("lab.discovered"), 16f, Ui.mint))
        }
    }
    filter.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
        override fun onItemSelected(parent: AdapterView<*>?, view: android.view.View?, position: Int, id: Long) { render(if (position == 0) null else elements[position - 1]) }
        override fun onNothingSelected(parent: AdapterView<*>?) {}
    }
    render(null)
    button("city.workshop") { page = "workshop"; show() }
}
