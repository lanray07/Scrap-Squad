package com.scrapsquad.fire

import android.content.Context
import android.util.AtomicFile
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.security.MessageDigest

/** Durable input replay plus a write-ahead reward transaction. No engine internals
 * are reimplemented, and a reward cannot be granted twice across process death.
 */
class BattleJournal(private val context: Context) {
    private val header = AtomicFile(File(context.filesDir, "pending-battle.json"))
    private val commands = File(context.filesDir, "pending-battle.ndjson")
    private val settlement = AtomicFile(File(context.filesDir, "settled-battle.json"))
    private var stream: FileOutputStream? = null
    private var lastSync = 0L
    fun pending() = header.baseFile.exists()
    private fun signature(): String {
        val hashes = JSONObject(context.assets.open("generated/source-hashes.json").bufferedReader().use { it.readText() })
        val rules = hashes.keys().asSequence().filter { it.startsWith("Sources/ScrapCore/") }.sorted().joinToString("\n") { "$it:${hashes.getString(it)}" }
        return MessageDigest.getInstance("SHA-256").digest(rules.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }
    }
    private fun write(file: AtomicFile, text: String) {
        val output = file.startWrite()
        try { output.write(text.toByteArray(Charsets.UTF_8)); file.finishWrite(output) }
        catch (e: Exception) { file.failWrite(output); throw e }
    }
    @Synchronized fun begin(content: String, profile: String, deploy: JSONObject) {
        check(!pending()) { "A pending battle must be recovered before deploying" }
        close(); commands.writeBytes(byteArrayOf())
        write(header, JSONObject().put("schema", 1).put("signature", signature()).put("content", content).put("profile", profile).put("deploy", deploy).toString())
    }
    @Synchronized fun append(command: JSONObject) {
        check(pending()) { "Battle replay header is missing" }
        val output = stream ?: FileOutputStream(commands, true).also { stream = it }
        output.write((command.toString() + "\n").toByteArray(Charsets.UTF_8))
        if (android.os.SystemClock.elapsedRealtime() - lastSync >= 1000) { output.fd.sync(); lastSync = android.os.SystemClock.elapsedRealtime() }
    }
    @Synchronized fun checkpoint() { stream?.fd?.sync() }
    @Synchronized fun close() { stream?.let { it.fd.sync(); it.close() }; stream = null }
    fun restore(progress: (Int) -> Unit = {}) = synchronized(NativeCore) {
        close()
        val metadata = JSONObject(header.openRead().bufferedReader().use { it.readText() })
        check(metadata.getInt("schema") == 1 && metadata.getString("signature") == signature()) { "Battle rules changed; preserve this save for migration" }
        NativeCore.call("init", "content" to metadata.getString("content"), "profile" to metadata.getString("profile"), "now" to metadata.getJSONObject("deploy").getDouble("now"))
        fun replay(command: JSONObject) {
            if (Thread.currentThread().isInterrupted) throw java.util.concurrent.CancellationException("Recovery interrupted")
            val result = JSONObject(NativeCore.request(command.toString()))
            check(!result.has("error")) { result.optString("error") }
        }
        replay(metadata.getJSONObject("deploy"))
        if (commands.exists()) {
            // A power loss can leave only the final append incomplete. Keep every
            // complete durable command and discard that incomplete suffix alone.
            RandomAccessFile(commands, "rw").use { file ->
                var end = file.length()
                while (end > 0) { file.seek(end - 1); if (file.readByte().toInt() == 10) break; end-- }
                if (end != file.length()) file.setLength(end)
            }
            val length = commands.length().coerceAtLeast(1); var consumed = 0L; var count = 0
            commands.bufferedReader(Charsets.UTF_8).useLines { lines -> lines.forEach { line ->
                replay(JSONObject(line)); consumed += line.toByteArray(Charsets.UTF_8).size + 1; count++
                if (count % 250 == 0) progress((consumed * 100 / length).toInt())
            } }
        }
        progress(100)
        NativeCore.call("state")
    }
    @Synchronized fun settle(profile: String) { close(); write(settlement, JSONObject().put("profile", profile).toString()) }
    fun settledProfile(): String? = if (settlement.baseFile.exists()) JSONObject(settlement.openRead().bufferedReader().use { it.readText() }).getString("profile") else null
    @Synchronized fun clear() { close(); header.delete(); commands.delete(); settlement.delete() }
}
