package com.scrapsquad.fire

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.AtomicFile
import com.amazon.device.iap.PurchasingListener
import com.amazon.device.iap.PurchasingService
import com.amazon.device.drm.LicensingService
import com.amazon.device.drm.model.LicenseResponse
import com.amazon.device.iap.model.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.concurrent.Executors

/** Implemented by the existing backend adapter, never by trusting a client receipt.
 * The server must call Amazon RVS with its merchant secret and bind all four fields.
 * Network errors must throw; only authoritative invalid/cancelled receipts revoke. */
internal fun interface AmazonReceiptVerifier {
    fun verify(userId: String, receiptId: String, environment: AmazonStoreEnvironment): VerifiedAmazonReceipt
}
internal enum class AmazonStoreEnvironment { SANDBOX, PRODUCTION }
internal data class VerifiedAmazonReceipt(val userId: String, val receiptId: String, val sku: String, val active: Boolean)

/** One listener per process, so activity recreation cannot abandon a transaction.
 * SDK callbacks run on the main thread; receipt validation and disk commits do not. */
internal class AmazonPurchases private constructor(context: Context) : PurchasingListener {
    private val app = context.applicationContext
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private val store = AtomicFile(File(app.filesDir, "amazon-entitlements.json"))
    private val catalog = JSONObject(app.assets.open("generated/StoreConfiguration.json").bufferedReader().use { it.readText() })
    val skus = catalog.getJSONArray("packs").objects().map { it.getString("id") }.toSet()
    private var verifier: AmazonReceiptVerifier? = null
    private var registered = false
    private var licensed = false
    private var environment: AmazonStoreEnvironment? = null
    private var user: String? = null
    private var generation = 0
    private var restoreInFlight = false
    private val products = mutableMapOf<String, Product>()
    private val receipts = linkedMapOf<String, VerifiedAmazonReceipt>()
    private val revokedReceiptIDs = mutableSetOf<String>()
    var changed: (() -> Unit)? = null
    var statusKey = "shop.unavailable"; private set
    val owned: Set<String> get() = receipts.values.filter { it.active }.map { it.sku }.toSet()
    val ready get() = registered && licensed && environment != null && user != null && verifier != null
    val selectionKey get() = user?.let { id -> "selection." + java.security.MessageDigest.getInstance("SHA-256").digest(id.toByteArray()).joinToString("") { "%02x".format(it) } }
    fun price(sku: String): String? = products[sku]?.price

    /** Called only once an actual backend adapter is configured. No default verifier. */
    fun configure(value: AmazonReceiptVerifier) { verifier = value; refresh() }

    fun start() {
        if (registered) return
        if (!runCatching { app.assets.open("AppstoreAuthenticationKey.pem").use { it.read() >= 0 } }.getOrDefault(false)) return
        runCatching {
            PurchasingService.registerListener(app, this)
            PurchasingService.enablePendingPurchases()
            registered = true
        }.onFailure { android.util.Log.e("ScrapIAP", "Amazon SDK initialization failed", it) }
    }
    fun refresh() {
        start()
        if (!registered) return
        status("shop.loading")
        runCatching {
            LicensingService.verifyLicense(app) { response ->
                licensed = response.requestStatus == LicenseResponse.RequestStatus.LICENSED
                environment = AmazonStoreEnvironment.entries.firstOrNull { it.name == LicensingService.getAppstoreSDKMode() }
                if (!BuildConfig.DEBUG && environment == AmazonStoreEnvironment.SANDBOX) licensed = false
                if (licensed && environment != null) runCatching { PurchasingService.getUserData() }.onFailure { status("shop.unavailable") }
                else status("shop.unavailable")
            }
        }.onFailure { licensed = false; status("shop.unavailable") }
    }
    fun restore() {
        if (!ready || restoreInFlight) { if (!ready) status("shop.unavailable"); return }
        restoreInFlight = true; status("shop.loading")
        runCatching { PurchasingService.getPurchaseUpdates(true) }.onFailure { restoreInFlight = false; status("shop.unavailable") }
    }
    fun purchase(sku: String) {
        if (!ready || products[sku]?.productType != ProductType.ENTITLED || !canPurchase(sku)) { status("shop.unavailable"); return }
        status("shop.pending")
        runCatching { PurchasingService.purchase(sku) }.onFailure { status("shop.unavailable") }
    }
    fun canPurchase(sku: String): Boolean {
        val packs = catalog.getJSONArray("packs").objects()
        val effective = owned.toMutableSet()
        repeat(packs.size) { packs.filter { it.getString("id") in effective }.forEach { pack -> pack.optJSONArray("includes")?.strings()?.filter { it in skus }?.let { effective.addAll(it) } } }
        val pack = packs.firstOrNull { it.getString("id") == sku } ?: return false
        return sku !in effective && pack.optJSONArray("includes")?.strings().orEmpty().none { it in effective }
    }
    private fun status(key: String) { statusKey = key; changed?.invoke() }
    private fun switchUser(id: String?) {
        if (id == user) return
        generation++; user = id; receipts.clear(); revokedReceiptIDs.clear(); products.clear(); restoreInFlight = false
        // Never expose another account's cached cosmetics, even while offline.
        if (id != null) runCatching {
            val saved = JSONObject(store.readFully().toString(Charsets.UTF_8))
            if (saved.getString("userId") == id) {
                revokedReceiptIDs.addAll(saved.optJSONArray("revoked")?.strings().orEmpty())
                saved.getJSONArray("receipts").objects().forEach {
                    val sku = it.getString("sku"); val receipt = it.getString("receiptId")
                    if (sku in skus && receipt !in revokedReceiptIDs) receipts[receipt] = VerifiedAmazonReceipt(id, receipt, sku, true)
                }
            }
        }
        changed?.invoke()
    }
    override fun onUserDataResponse(response: UserDataResponse) {
        if (response.requestStatus != UserDataResponse.RequestStatus.SUCCESSFUL) { switchUser(null); status("shop.unavailable"); return }
        switchUser(response.userData.userId)
        runCatching { PurchasingService.getProductData(skus) }.onFailure { status("shop.unavailable") }
        if (verifier != null) {
            // Recheck cached receipts as well as paged updates to detect refunds.
            validate(response.userData.userId, receipts.values.map { it.receiptId to it.sku }, emptySet())
            restore()
        } else status("shop.unavailable")
    }
    override fun onProductDataResponse(response: ProductDataResponse) {
        products.clear()
        if (response.requestStatus == ProductDataResponse.RequestStatus.SUCCESSFUL) products.putAll(response.productData.filter { it.key in skus && it.value.productType == ProductType.ENTITLED })
        changed?.invoke()
    }
    override fun onPurchaseResponse(response: PurchaseResponse) {
        when (response.requestStatus) {
            PurchaseResponse.RequestStatus.SUCCESSFUL -> {
                if (response.userData.userId != user) { refresh(); return }
                process(response.userData.userId, listOf(response.receipt))
            }
            PurchaseResponse.RequestStatus.PENDING -> status("shop.pending") // No entitlement.
            PurchaseResponse.RequestStatus.ALREADY_PURCHASED -> restore()
            else -> status("shop.unavailable")
        }
    }
    override fun onPurchaseUpdatesResponse(response: PurchaseUpdatesResponse) {
        if (response.requestStatus != PurchaseUpdatesResponse.RequestStatus.SUCCESSFUL) { restoreInFlight = false; status("shop.unavailable"); return }
        if (response.userData.userId != user) { restoreInFlight = false; refresh(); return }
        process(response.userData.userId, response.receipts)
        if (response.hasMore()) runCatching { PurchasingService.getPurchaseUpdates(false) }.onFailure { restoreInFlight = false; status("shop.unavailable") }
        else restoreInFlight = false
    }
    private fun process(id: String, values: List<Receipt>) {
        val valid = values.filter { it.sku in skus && it.productType == ProductType.ENTITLED }
        val cancelled = valid.filter { it.isCanceled }.map { it.receiptId }.toSet()
        // Amazon's trusted cancellation callback can remove access immediately;
        // a backend outage must never keep a known-refunded cosmetic active.
        if (cancelled.isNotEmpty()) {
            revokedReceiptIDs.addAll(cancelled)
            cancelled.forEach { receipts.remove(it) }
            runCatching { persist(id, receipts) }.onFailure { android.util.Log.e("ScrapIAP", "Revocation persistence failed", it) }
            status("shop.revoked")
        }
        validate(id, valid.map { it.receiptId to it.sku }, cancelled)
    }
    private fun persist(id: String, next: Map<String, VerifiedAmazonReceipt>) {
        val payload = JSONObject().put("userId", id).put("revoked", JSONArray(revokedReceiptIDs.toList())).put("receipts", JSONArray(next.values.map { JSONObject().put("receiptId", it.receiptId).put("sku", it.sku) }))
        val stream = store.startWrite()
        try { stream.write(payload.toString().toByteArray()); store.finishWrite(stream) } catch (e: Exception) { store.failWrite(stream); throw e }
    }
    private fun validate(id: String, values: List<Pair<String, String>>, cancelled: Set<String>) {
        val validator = verifier ?: return
        val receiptEnvironment = environment ?: return
        val epoch = generation
        worker.execute {
            try {
                val checked = values.distinct().map { (receipt, expectedSku) ->
                    validator.verify(id, receipt, receiptEnvironment).also {
                        require(it.userId == id && it.receiptId == receipt && it.sku == expectedSku && it.sku in skus) { "Receipt binding mismatch" }
                    }
                }
                main.post {
                    if (generation != epoch || user != id || !licensed || environment != receiptEnvironment) return@post
                    val next = LinkedHashMap(receipts)
                    revokedReceiptIDs.addAll(checked.filter { !it.active }.map { it.receiptId })
                    checked.forEach { if (it.active && it.receiptId !in revokedReceiptIDs) next[it.receiptId] = it else next.remove(it.receiptId) }
                    try {
                        // Durably commit before notifying fulfillment. Retry is idempotent.
                        persist(id, next)
                        receipts.clear(); receipts.putAll(next)
                        checked.filter { it.active && it.receiptId !in revokedReceiptIDs }.forEach { PurchasingService.notifyFulfillment(it.receiptId, FulfillmentResult.FULFILLED) }
                        status(if (checked.any { it.receiptId in revokedReceiptIDs }) "shop.revoked" else if (owned.isEmpty()) "shop.restore.empty" else "shop.verified")
                    } catch (e: Exception) { android.util.Log.e("ScrapIAP", "Entitlement commit failed", e); status("shop.unavailable") }
                }
            } catch (e: Exception) {
                // Leave offline, previously verified entitlements intact. Never grant on failure.
                main.post { if (generation == epoch && user == id) status("shop.unavailable") }
                android.util.Log.e("ScrapIAP", "Receipt validation failed", e)
            }
        }
    }
    companion object {
        @Volatile private var instance: AmazonPurchases? = null
        fun get(context: Context): AmazonPurchases = instance ?: synchronized(this) { instance ?: AmazonPurchases(context).also { instance = it } }
    }
}
