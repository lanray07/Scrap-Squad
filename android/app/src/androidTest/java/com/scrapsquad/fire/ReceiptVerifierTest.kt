package com.scrapsquad.fire

import androidx.test.ext.junit.runners.AndroidJUnit4
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class ReceiptVerifierTest {
    private val sku = "com.ScrapSquad.app.founder"
    private fun payload() = JSONObject().put("userId", "user").put("receiptId", "receipt").put("sku", sku).put("environment", "PRODUCTION").put("active", true)
    private fun decode(value: JSONObject) = decodeVerifiedReceipt(value.toString(), "user", "receipt", sku, AmazonStoreEnvironment.PRODUCTION)
    @Test fun validAndCanceledReceiptsRemainDistinct() {
        assertTrue(decode(payload()).active)
        assertFalse(decode(payload().put("active", false)).active)
    }
    @Test fun mismatchedReceiptUserSkuOrEnvironmentCannotGrant() {
        for (key in listOf("userId", "receiptId", "sku", "environment")) assertTrue(runCatching { decode(payload().put(key, "other")) }.isFailure)
    }
    @Test fun missingOrCoercedActiveFieldsCannotGrant() {
        for (value in listOf("true", 1, JSONObject.NULL)) assertTrue(runCatching { decode(payload().put("active", value)) }.isFailure)
        assertTrue(runCatching { decode(payload().apply { remove("active") }) }.isFailure)
        assertTrue(runCatching { decode(payload().put("unexpected", "field")) }.isFailure)
    }
    @Test fun endpointRequiresHttpsAndExactRouteWithoutCredentialsOrQuery() {
        HttpAmazonReceiptVerifier.validateEndpoint("https://example.workers.dev/v1/amazon/verify")
        for (url in listOf("http://example.test/v1/amazon/verify", "https://user:secret@example.test/v1/amazon/verify", "https://example.test/v1/amazon/verify?secret=key", "https://example.test/v1/amazon/verify#fragment", "https://example.test/other")) assertTrue(runCatching { HttpAmazonReceiptVerifier.validateEndpoint(url) }.isFailure)
    }
}
