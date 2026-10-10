package com.scrapsquad.fire

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Separate from progression, exactly like the original iOS CosmeticSelection. */
internal class CosmeticRepository(context: Context) {
    private val purchases = AmazonPurchases.get(context)
    private val preferences = context.getSharedPreferences("cosmetics", Context.MODE_PRIVATE)
    private val catalog = JSONObject(context.assets.open("generated/StoreConfiguration.json").bufferedReader().use { it.readText() })
    fun state(candidate: JSONObject? = null): JSONObject {
        val defaults = JSONObject().put("robotFinishIDs", JSONObject()).put("goldenTrails", false).put("founderBadge", false)
        val key = purchases.selectionKey
        val selection = candidate ?: runCatching { JSONObject(if (key == null) defaults.toString() else preferences.getString(key, defaults.toString())!!) }.getOrDefault(defaults)
        val value = NativeCore.call("cosmetics", "catalog" to catalog, "owned" to JSONArray(purchases.owned.toList()), "selection" to selection)
        val reconciled = value.getJSONObject("selection")
        // Commit synchronously: purchases can revoke before the next activity opens.
        if (key != null) check(preferences.edit().putString(key, reconciled.toString()).commit()) { "Cosmetic selection could not be saved" }
        return value
    }
    fun equip(finish: JSONObject) { val selection = state().getJSONObject("selection"); selection.getJSONObject("robotFinishIDs").put(finish.getString("robotID"), finish.getString("id")); state(selection) }
    fun remove(robot: String) { val selection = state().getJSONObject("selection"); selection.getJSONObject("robotFinishIDs").remove(robot); state(selection) }
    fun toggle(field: String, enabled: Boolean) { val selection = state().getJSONObject("selection"); selection.put(field, enabled); state(selection) }
    fun weaponEffect(effect: String?) { val selection = state().getJSONObject("selection"); selection.put("weaponEffectID", effect ?: JSONObject.NULL); state(selection) }
}
