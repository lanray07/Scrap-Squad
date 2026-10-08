package com.scrapsquad.fire

import android.content.Context
import android.util.AtomicFile
import org.json.JSONObject
import java.io.File

class GameRepository(val context: Context) {
    val content = JSONObject(context.assets.open("generated/content.json").bufferedReader().use { it.readText() })
    private val save = AtomicFile(File(context.filesDir, "profile.json"))
    val battleJournal = BattleJournal(context)
    var profile = JSONObject()
        private set
    fun initialize() = synchronized(NativeCore) {
        val settled = battleJournal.settledProfile()
        val old = settled ?: if (save.baseFile.exists()) save.openRead().bufferedReader().use { it.readText() } else null
        val args = mutableListOf<Pair<String, Any>>("content" to content.toString())
        if (old != null) args.add("profile" to old)
        // Corrupt saves cause a visible error; never silently overwrite progress.
        update(NativeCore.call("init", *args.toTypedArray()))
        if (settled != null) battleJournal.clear()
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
    fun action(op: String, vararg values: Pair<String, Any>): JSONObject {
        val result = NativeCore.call(op, *values)
        if (op == "claim" && battleJournal.pending()) {
            battleJournal.settle(result.getString("profile"))
            update(result); battleJournal.clear()
            return result
        }
        return update(result)
    }
    fun beginBattle(vararg values: Pair<String, Any>): JSONObject {
        val deploy = JSONObject().put("op", "deploy").put("now", System.currentTimeMillis() / 1000.0)
        values.forEach { deploy.put(it.first, it.second) }
        val result = JSONObject(NativeCore.request(deploy.toString()))
        check(!result.has("error")) { result.optString("error") }
        battleJournal.begin(content.toString(), profile.toString(), deploy)
        return result
    }
    fun battleCommand(op: String, vararg values: Pair<String, Any>): JSONObject {
        val command = JSONObject().put("op", op).put("now", System.currentTimeMillis() / 1000.0)
        values.forEach { command.put(it.first, it.second) }
        val result = JSONObject(NativeCore.request(command.toString()))
        check(!result.has("error")) { result.optString("error") }
        battleJournal.append(command)
        if (op == "background") update(result)
        return result
    }
    fun restoreBattle(progress: (Int) -> Unit = {}) = synchronized(NativeCore) {
        val result = battleJournal.restore(progress)
        if (Thread.currentThread().isInterrupted) throw java.util.concurrent.CancellationException("Recovery interrupted")
        update(result)
    }
}
