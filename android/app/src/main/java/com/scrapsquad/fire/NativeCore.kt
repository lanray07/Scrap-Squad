package com.scrapsquad.fire

import org.json.JSONObject

object NativeCore {
    init { System.loadLibrary("scrapjni") }
    private external fun exchange(input: ByteArray): ByteArray
    fun request(input: String): String = exchange(input.toByteArray(Charsets.UTF_8)).toString(Charsets.UTF_8)
    @Synchronized fun call(op: String, vararg values: Pair<String, Any>): JSONObject {
        val q = JSONObject().put("op", op)
        values.forEach { q.put(it.first, it.second) }
        val result = JSONObject(request(q.toString()))
        check(!result.has("error")) { result.optString("error") }
        return result
    }
}
