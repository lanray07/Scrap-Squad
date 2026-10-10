package com.scrapsquad.fire

import android.content.Context
import org.json.JSONObject
import java.util.Locale

class Strings(context: Context) {
    private val catalog = JSONObject(context.assets.open("generated/localization.json").bufferedReader().use { it.readText() })
    private val english = catalog.getJSONObject("en")
    var language = "system"
    fun availableLanguages(): List<String> = catalog.keys().asSequence().toList().sorted()
    fun text(key: String): String {
        val tag = if (language == "system") Locale.getDefault().toLanguageTag() else language
        val local = catalog.optJSONObject(tag) ?: catalog.optJSONObject(tag.substringBefore('-'))
        return local?.optString(key)?.takeIf { it.isNotEmpty() } ?: english.optString(key).takeIf { it.isNotEmpty() }
            ?: error("Missing localization: $key")
    }
}
