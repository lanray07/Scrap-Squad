package com.scrapsquad.fire

import androidx.test.platform.app.InstrumentationRegistry
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import kotlin.math.abs

class GameplayParityTest {
    private fun compare(expected: Any?, actual: Any?, path: String) {
        when (expected) {
            null, JSONObject.NULL -> assertTrue(path, actual == null || actual == JSONObject.NULL)
            is JSONObject -> { assertTrue(path, actual is JSONObject); val value = actual as JSONObject; expected.keys().forEach { key -> assertTrue("$path.$key missing", value.has(key)); compare(expected.get(key), value.get(key), "$path.$key") } }
            is JSONArray -> { assertTrue(path, actual is JSONArray); val value = actual as JSONArray; assertEquals(path, expected.length(), value.length()); for (i in 0 until expected.length()) compare(expected.get(i), value.get(i), "$path[$i]") }
            is Number -> { assertTrue(path, actual is Number); val a = expected.toDouble(); val b = (actual as Number).toDouble(); assertTrue("$path expected=$a actual=$b", abs(a - b) <= 0.000001 + abs(a) * 0.00000001) }
            else -> assertEquals(path, expected, actual)
        }
    }
    @Test fun originalSwiftTraceParity() {
        val context = InstrumentationRegistry.getInstrumentation().context
        val fixture = JSONObject(context.assets.open("parity.json").bufferedReader().use { it.readText() })
        val cases = fixture.getJSONArray("cases")
        var commandsRun = 0
        val start = System.nanoTime()
        for (c in 0 until cases.length()) {
            val scenario = cases.getJSONObject(c); val commands = scenario.getJSONArray("commands"); val checkpoints = scenario.getJSONArray("checkpoints")
            val indexed = (0 until checkpoints.length()).associate { checkpoints.getJSONObject(it).getInt("index") to checkpoints.getJSONObject(it).getJSONObject("expected") }
            for (i in 0 until commands.length()) {
                val response = JSONObject(NativeCore.request(commands.getJSONObject(i).toString())); assertFalse(response.toString(), response.has("error"))
                indexed[i]?.let { expected ->
                    val normalized = JSONObject().put("battle", response.opt("battle") ?: JSONObject.NULL).put("profile", JSONObject(response.getString("profile")))
                    compare(expected, normalized, "${scenario.getString("name")} command $i")
                }
                commandsRun++
            }
        }
        android.util.Log.i("ScrapParity", "PASS ${cases.length()} scenarios, $commandsRun JNI commands, ${(System.nanoTime() - start) / 1000000}ms; this is simulation throughput, not rendered FPS")
    }
    @Test fun malformedInputFailsClosed() { assertTrue(JSONObject(NativeCore.request("not-json")).has("error")) }
}
