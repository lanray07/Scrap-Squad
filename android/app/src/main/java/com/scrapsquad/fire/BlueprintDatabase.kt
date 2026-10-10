package com.scrapsquad.fire

import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.text.Editable
import android.text.TextWatcher
import android.widget.*

internal fun MenuScreens.blueprints() {
    heading("lab.database")
    val recipes = content.getJSONArray("recipes").objects()
    val discovered = profile.getJSONArray("blueprints").strings().toSet()
    val elements = recipes.map { item("weapons", it.getString("result")).getString("element") }.distinct()
    fun accent(element: String) = when (element) {
        "fire" -> Color.rgb(255, 168, 117)
        "electric" -> Ui.gold
        "cryo" -> Color.rgb(131, 234, 255)
        "poison" -> Ui.mint
        else -> Color.rgb(202, 173, 255)
    }
    fun progress(count: Int, total: Int, color: Int) = ProgressBar(activity, null, android.R.attr.progressBarStyleHorizontal).apply {
        max = total; progress = count; progressTintList = ColorStateList.valueOf(color)
        progressBackgroundTintList = ColorStateList.valueOf(Ui.disabled)
        layoutParams = LinearLayout.LayoutParams(-1, Ui.dp(activity, 8)).apply { setMargins(8, 4, 8, 12) }
        contentDescription = "${t("lab.discovered")}: ${number(count)} / ${number(total)}"
    }
    val knownCount = recipes.count { it.getString("id") in discovered }
    label("${t("lab.discovered")} · ${number(knownCount)} / ${number(recipes.size)}", 22f, Ui.mint)
    panel.addView(progress(knownCount, recipes.size, Ui.mint))
    label(t("android.blueprints.detail"))
    var status = 0
    var query = ""
    val search = EditText(activity).apply {
        tag = "blueprint-search"; hint = t("android.blueprints.search"); textSize = 18f
        setTextColor(Color.WHITE); setHintTextColor(Ui.muted); isSingleLine = true
        inputType = android.text.InputType.TYPE_CLASS_TEXT
        setPadding(Ui.dp(activity, 16), Ui.dp(activity, 12), Ui.dp(activity, 16), Ui.dp(activity, 12))
        background = Ui.rounded(activity, Ui.surface, 16, Ui.mint)
        layoutParams = LinearLayout.LayoutParams(-1, -2).apply { setMargins(6, 8, 6, 8) }
    }
    panel.addView(search)
    val tabs = LinearLayout(activity)
    panel.addView(HorizontalScrollView(activity).apply { isHorizontalScrollBarEnabled = false; addView(tabs) })
    val results = LinearLayout(activity).apply { orientation = LinearLayout.VERTICAL; tag = "blueprint-results" }
    panel.addView(results)
    val filters = mutableListOf<Button>()
    fun render() {
        filters.forEachIndexed { index, button ->
            button.backgroundTintList = ColorStateList.valueOf(if (status == index) Ui.mint else Ui.surface)
            button.setTextColor(if (status == index) Ui.ink else Ui.muted)
            button.isSelected = status == index
        }
        results.removeAllViews()
        val visible = recipes.filter { recipe ->
            val known = recipe.getString("id") in discovered
            val weapon = item("weapons", recipe.getString("result"))
            val name = t(if (known) weapon.getString("nameKey") else "lab.unknown")
            (status == 0 || known == (status == 1)) &&
                (query.isBlank() || listOf(name, t(recipe.getString("clueKey")), t("element.${weapon.getString("element")}")).any { it.contains(query, ignoreCase = true) })
        }
        if (visible.isEmpty()) results.addView(Ui.text(activity, t("android.blueprints.empty"), 18f, Ui.muted))
        elements.forEach { element ->
            val group = visible.filter { item("weapons", it.getString("result")).getString("element") == element }
            if (group.isEmpty()) return@forEach
            val color = accent(element)
            val allInElement = recipes.filter { item("weapons", it.getString("result")).getString("element") == element }
            val count = allInElement.count { it.getString("id") in discovered }
            val section = LinearLayout(activity).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(Ui.dp(activity, 14), Ui.dp(activity, 12), Ui.dp(activity, 14), Ui.dp(activity, 12))
                background = Ui.rounded(activity, Ui.surface, 24, color)
            }
            section.addView(Ui.text(activity, t("element.$element"), 24f, color).apply {
                typeface = Typeface.create("sans-serif", Typeface.BOLD); isAccessibilityHeading = true
            })
            section.addView(Ui.text(activity, "${t("lab.discovered")} · ${number(count)} / ${number(allInElement.size)}", 15f, Ui.muted))
            section.addView(progress(count, allInElement.size, color))
            group.sortedWith(compareBy({ it.getString("id") !in discovered }, {
                if (it.getString("id") in discovered) t(item("weapons", it.getString("result")).getString("nameKey")) else t(it.getString("clueKey"))
            })).forEach { recipe ->
                val known = recipe.getString("id") in discovered
                val weapon = item("weapons", recipe.getString("result"))
                val title = t(if (known) weapon.getString("nameKey") else "lab.unknown")
                val card = LinearLayout(activity).apply {
                    orientation = LinearLayout.VERTICAL; tag = "blueprint:${recipe.getString("id")}:$known"
                    setPadding(Ui.dp(activity, 12), Ui.dp(activity, 8), Ui.dp(activity, 12), Ui.dp(activity, 8))
                    background = Ui.rounded(activity, Ui.ink, 18, if (known) color else Ui.disabled)
                }
                card.addView(Ui.text(activity, t(if (known) "lab.discovered" else "android.blueprints.undiscovered"), 13f, if (known) Ui.mint else Ui.muted))
                card.addView(Ui.text(activity, title, 21f, if (known) color else Color.WHITE).apply { typeface = Typeface.create("sans-serif", Typeface.BOLD) })
                card.addView(Ui.text(activity, t(recipe.getString("clueKey")), 16f, Ui.muted))
                card.isFocusable = true
                card.contentDescription = "$title. ${t(recipe.getString("clueKey"))}"
                card.setOnClickListener {
                    activity.playCue("ui")
                    val dialog = PremiumDialog.Builder(activity).setTitle(title).setAccent(color)
                    if (known) dialog.setFeature(title, t("rarity.${weapon.getString("rarity")}"), t(weapon.getString("descriptionKey")))
                        .setMessage("${t("android.blueprints.ingredients")}\n${t("weapon.${recipe.getString("weapon")}")} + ${t("component.${recipe.getString("component")}")}\n${number(recipe.getInt("scrapCost"))} ${t("currency.scrap")}")
                        .setPositiveButton(t("city.workshop")) { _, _ -> page = "workshop"; show() }
                    else dialog.setMessage(t(recipe.getString("clueKey")))
                    dialog.setNegativeButton(t("common.done"), null).show()
                }
                section.addView(card, LinearLayout.LayoutParams(-1, -2).apply { setMargins(0, Ui.dp(activity, 8), 0, 0) })
            }
            results.addView(section, LinearLayout.LayoutParams(-1, -2).apply { setMargins(6, Ui.dp(activity, 14), 6, Ui.dp(activity, 4)) })
        }
    }
    listOf("android.blueprints.all", "lab.discovered", "android.blueprints.undiscovered").forEachIndexed { index, key ->
        val button = Ui.button(activity, t(key)) { status = index; render() }.apply {
            tag = "blueprint-filter:$index"
            layoutParams = LinearLayout.LayoutParams(-2, -2).apply { setMargins(6, 8, 6, 8) }
        }
        filters.add(button); tabs.addView(button)
    }
    search.addTextChangedListener(object : TextWatcher {
        override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
        override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) { query = s?.toString()?.trim().orEmpty(); render() }
        override fun afterTextChanged(s: Editable?) {}
    })
    render()
    button("city.workshop") { page = "workshop"; show() }
}
