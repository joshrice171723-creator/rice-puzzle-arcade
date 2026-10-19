package com.joshuarice.nightfallproof

import android.util.Log
import com.google.android.gms.ads.*
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.UserMessagingPlatform
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

/** Internal proof only: Google sample identifiers are intentionally not configurable. */
class NightfallAds(godot: Godot) : GodotPlugin(godot) {
    private var initialized = false
    private var busy = false
    private var earned = false
    private var activeRequest: String? = null
    private var showing = false
    override fun getPluginName() = "NightfallAds"
    override fun getPluginSignals() = setOf(
        SignalInfo("ad_state", String::class.java), SignalInfo("reward_earned"),
        SignalInfo("reward_granted", String::class.java),
        SignalInfo("reward_finished", String::class.java, Boolean::class.javaObjectType),
        SignalInfo("reward_error", String::class.java, String::class.java)
    )

    private fun state(message: String) {
        Log.i("NightfallAds", message)
        emitSignal("ad_state", message)
    }

    @UsedByGodot
    fun testRewarded() {
        showRewarded("diagnostic-${System.nanoTime()}")
    }

    @UsedByGodot
    fun cancelRewarded(requestId: String) {
        activity?.runOnUiThread {
            if (activeRequest == requestId && !showing) fail(requestId, "Video request cancelled.")
        }
    }

    private fun fail(requestId: String, message: String) {
        if (activeRequest != requestId) return
        busy = false
        showing = false
        activeRequest = null
        state(message)
        emitSignal("reward_error", requestId, message)
    }

    @UsedByGodot
    fun showRewarded(requestId: String) {
        val host = activity ?: run {
            emitSignal("reward_error", requestId, "Android activity is unavailable.")
            return
        }
        host.runOnUiThread {
            if (busy) {
                emitSignal("reward_error", requestId, "Another video request is already active.")
                return@runOnUiThread
            }
            busy = true
            earned = false
            showing = false
            activeRequest = requestId
            state("Checking consent…")
            val consent = UserMessagingPlatform.getConsentInformation(host)
            val params = ConsentRequestParameters.Builder().build()
            consent.requestConsentInfoUpdate(host, params, {
                if (activeRequest != requestId) return@requestConsentInfoUpdate
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(host) { error ->
                    if (activeRequest != requestId) return@loadAndShowConsentFormIfRequired
                    if (error != null) {
                        fail(requestId, "Consent form: ${error.message}")
                    } else if (consent.canRequestAds()) {
                        if (initialized) loadVideo(requestId) else {
                            MobileAds.setRequestConfiguration(RequestConfiguration.Builder()
                                .setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_T).build())
                            MobileAds.initialize(host) {
                                initialized = true
                                host.runOnUiThread { if (activeRequest == requestId) loadVideo(requestId) }
                            }
                        }
                    } else {
                        fail(requestId, "Ads unavailable for this consent state.")
                    }
                }
            }, { error ->
                fail(requestId, "Consent request: ${error.message}")
            })
        }
    }

    private fun loadVideo(requestId: String) {
        val host = activity ?: run { fail(requestId, "Android activity is unavailable."); return }
        state("Loading Google sample rewarded video…")
        RewardedAd.load(host, "ca-app-pub-3940256099942544/5224354917",
            AdRequest.Builder().build(), object : RewardedAdLoadCallback() {
                override fun onAdFailedToLoad(error: LoadAdError) {
                    fail(requestId, "Load failed ${error.code}: ${error.message}")
                }
                override fun onAdLoaded(ad: RewardedAd) {
                    if (activeRequest != requestId) return
                    ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                        override fun onAdShowedFullScreenContent() {
                            showing = true
                            state("Sample video showing")
                        }
                        override fun onAdDismissedFullScreenContent() {
                            if (activeRequest != requestId) return
                            busy = false
                            showing = false
                            activeRequest = null
                            state(if (earned) "Closed • reward verified" else "Closed • no earned reward")
                            emitSignal("reward_finished", requestId, earned)
                        }
                        override fun onAdFailedToShowFullScreenContent(error: AdError) {
                            fail(requestId, "Show failed ${error.code}: ${error.message}")
                        }
                    }
                    ad.show(host) {
                        if (activeRequest == requestId && !earned) {
                            earned = true
                            emitSignal("reward_earned")
                            emitSignal("reward_granted", requestId)
                            state("Earned callback received once")
                        }
                    }
                }
            })
    }

    @UsedByGodot
    fun privacyOptions() {
        val host = activity ?: return
        host.runOnUiThread {
            if (busy) return@runOnUiThread
            UserMessagingPlatform.showPrivacyOptionsForm(host) { error ->
                state(error?.message ?: "Privacy choices updated")
            }
        }
    }
}
