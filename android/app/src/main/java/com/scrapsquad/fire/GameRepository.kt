package com.scrapsquad.fire

import android.content.Context
import android.util.AtomicFile
import org.json.JSONObject
import java.io.File

class GameRepository(val context: Context) {
    val content = JSONObject(context.assets.open("generated/content.json").bufferedReader().use { it.readText() })
    private val save = AtomicFile(File(context.filesDir, "profile.json"))
    var profile = JSONObject()
        private set
    fun initialize() {
        val old = if (save.baseFile.exists()) save.openRead().bufferedReader().use { it.readText() } else null
        val args = mutableListOf<Pair<String, Any>>("content" to content.toString())
        if (old != null) args.add("profile" to old)
        // Corrupt saves cause a visible error; never silently overwrite progress.
        update(NativeCore.call("init", *args.toTypedArray()))
    }
    @Synchronized fun update(value: JSONObject): JSONObject {
        if (value.has("profile")) {
            profile = JSONObject(value.getString("profile"))
            val stream = save.startWrite()
            try { stream.write(profile.toString().toByteArray(Charsets.UTF_8)); save.finishWrite(stream) }
            catch (e: Exception) { save.failWrite(stream); throw e }
        }
        return value
    }
    fun action(op: String, vararg values: Pair<String, Any>) = update(NativeCore.call(op, *values))
}
