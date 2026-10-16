package com.scrapsquad.fire

import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.net.URL
import javax.net.ssl.HttpsURLConnection

/** Server URL is public configuration. No merchant secret or shared client API key. */
internal class HttpAmazonReceiptVerifier(private val production: String, private val sandbox: String) : AmazonReceiptVerifier {
    init { listOf(production, sandbox).filter { it.isNotEmpty() }.forEach(::validateEndpoint) }
    override fun verify(userId: String, receiptId: String, sku: String, environment: AmazonStoreEnvironment): VerifiedAmazonReceipt {
        val endpoint = when (environment) {
            AmazonStoreEnvironment.PRODUCTION -> production
            AmazonStoreEnvironment.SANDBOX -> { check(BuildConfig.DEBUG); sandbox }
        }
        check(endpoint.isNotEmpty()) { "Receipt service is not configured" }
        val payload = JSONObject().put("userId", userId).put("receiptId", receiptId).put("sku", sku).put("environment", environment.name).toString().toByteArray(Charsets.UTF_8)
        val connection = URL(endpoint).openConnection() as HttpsURLConnection
        try {
            connection.requestMethod = "POST"; connection.instanceFollowRedirects = false
            connection.connectTimeout = 10000; connection.readTimeout = 12000; connection.doOutput = true; connection.useCaches = false
            connection.setRequestProperty("Content-Type", "application/json; charset=utf-8")
            connection.setRequestProperty("Accept", "application/json"); connection.setFixedLengthStreamingMode(payload.size)
            connection.outputStream.use { it.write(payload) }
            check(connection.responseCode == 200) { "Receipt verification unavailable" }
            val output = ByteArrayOutputStream()
            connection.inputStream.use { stream ->
                val buffer = ByteArray(1024)
                while (true) { val count = stream.read(buffer); if (count < 0) break; check(output.size() + count <= 8192) { "Invalid verification response" }; output.write(buffer, 0, count) }
            }
            return decodeVerifiedReceipt(output.toString(Charsets.UTF_8.name()), userId, receiptId, sku, environment)
        } finally { connection.disconnect() }
    }
    companion object {
        internal fun validateEndpoint(value: String) {
            val uri = java.net.URI(value)
            require(uri.scheme == "https" && !uri.host.isNullOrBlank() && uri.rawUserInfo == null && uri.rawQuery == null && uri.rawFragment == null && uri.path == "/v1/amazon/verify") { "Invalid receipt endpoint" }
        }
    }
}

internal fun decodeVerifiedReceipt(raw: String, userId: String, receiptId: String, sku: String, environment: AmazonStoreEnvironment): VerifiedAmazonReceipt {
    val result = JSONObject(raw)
    require(result.keys().asSequence().toSet() == setOf("userId", "receiptId", "sku", "environment", "active")) { "Invalid verification response" }
    require(result.get("userId") == userId && result.get("receiptId") == receiptId && result.get("sku") == sku && result.get("environment") == environment.name && result.get("active") is Boolean) { "Receipt binding mismatch" }
    return VerifiedAmazonReceipt(userId, receiptId, sku, result.getBoolean("active"))
}
