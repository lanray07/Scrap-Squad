package com.scrapsquad.fire

import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class CosmeticParityTest {
    @Test fun originalBundleOverlapAndRevocationRulesStayOutsideProgression() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val repository = GameRepository(context); repository.initialize()
        val original = NativeCore.call("state").getString("profile")
        val catalog = JSONObject(context.assets.open("generated/StoreConfiguration.json").bufferedReader().use { it.readText() })
        val selection = JSONObject().put("robotFinishIDs", JSONObject().put("bolt", "bolt-ronin").put("tank", "tank-cobalt").put("patch", "invented"))
            .put("goldenTrails", true).put("founderBadge", true).put("weaponEffectID", "prism")
        val prefix = "com.ScrapSquad.app."
        val granted = NativeCore.call("cosmetics", "catalog" to catalog, "owned" to JSONArray(listOf(prefix + "collection", prefix + "styles", "unknown")), "selection" to selection)
        val effective = granted.getJSONArray("effectiveOwnership").strings()
        assertTrue(prefix + "ronin" in effective); assertTrue(prefix + "prism" in effective); assertFalse("unknown" in effective)
        assertEquals("ronin", granted.getJSONObject("finishes").getJSONObject("bolt").getString("skin"))
        assertFalse(granted.getJSONObject("finishes").has("patch"))
        assertFalse(granted.getJSONObject("selection").getBoolean("goldenTrails"))
        assertFalse(granted.getJSONObject("selection").getBoolean("founderBadge"))
        assertEquals("prism", granted.getJSONObject("selection").getString("weaponEffectID"))
        assertFalse(granted.getJSONObject("canPurchase").getBoolean(prefix + "ronin"))
        val overlap = NativeCore.call("cosmetics", "catalog" to catalog, "owned" to JSONArray(listOf(prefix + "medic")), "selection" to selection)
        assertFalse("Collection must not charge for already-owned component", overlap.getJSONObject("canPurchase").getBoolean(prefix + "collection"))
        val revoked = NativeCore.call("cosmetics", "catalog" to catalog, "owned" to JSONArray(), "selection" to granted.getJSONObject("selection"))
        assertEquals(0, revoked.getJSONObject("finishes").length())
        assertEquals(0, revoked.getJSONObject("selection").getJSONObject("robotFinishIDs").length())
        assertTrue(revoked.getJSONObject("selection").isNull("weaponEffectID"))
        val after = JSONObject(NativeCore.call("state").getString("profile"))
        fun canonical(value: Any?): String = when (value) {
            is JSONObject -> value.keys().asSequence().toList().sorted().joinToString(prefix = "{", postfix = "}") { JSONObject.quote(it) + ":" + canonical(value.get(it)) }
            is JSONArray -> (0 until value.length()).joinToString(prefix = "[", postfix = "]") { canonical(value.get(it)) }
            else -> value.toString()
        }
        assertEquals("Cosmetics must never change game progress", canonical(JSONObject(original)), canonical(after))
    }
}
