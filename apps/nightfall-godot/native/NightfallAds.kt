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
    override fun getPluginName() = "NightfallAds"
    override fun getPluginSignals() = setOf(
        SignalInfo("ad_state", String::class.java), SignalInfo("reward_earned")
    )

    private fun state(message: String) {
        Log.i("NightfallAds", message)
        emitSignal("ad_state", message)
    }

    @UsedByGodot
    fun testRewarded() {
        val host = activity ?: return
        host.runOnUiThread {
            if (busy) return@runOnUiThread
            busy = true
            earned = false
            state("Checking consent…")
            val consent = UserMessagingPlatform.getConsentInformation(host)
            val params = ConsentRequestParameters.Builder().build()
            consent.requestConsentInfoUpdate(host, params, {
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(host) { error ->
                    if (error != null) {
                        busy = false
                        state("Consent form: ${error.message}")
                    } else if (consent.canRequestAds()) {
                        if (initialized) loadVideo() else {
                            MobileAds.setRequestConfiguration(RequestConfiguration.Builder()
                                .setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_T).build())
                            MobileAds.initialize(host) {
                                initialized = true
                                host.runOnUiThread { loadVideo() }
                            }
                        }
                    } else {
                        busy = false
                        state("Ads unavailable for this consent state.")
                    }
                }
            }, { error ->
                busy = false
                state("Consent request: ${error.message}")
            })
        }
    }

    private fun loadVideo() {
        val host = activity ?: run { busy = false; return }
        state("Loading Google sample rewarded video…")
        RewardedAd.load(host, "ca-app-pub-3940256099942544/5224354917",
            AdRequest.Builder().build(), object : RewardedAdLoadCallback() {
                override fun onAdFailedToLoad(error: LoadAdError) {
                    busy = false
                    state("Load failed ${error.code}: ${error.message}")
                }
                override fun onAdLoaded(ad: RewardedAd) {
                    ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                        override fun onAdShowedFullScreenContent() { state("Sample video showing") }
                        override fun onAdDismissedFullScreenContent() {
                            busy = false
                            state(if (earned) "Closed • reward verified" else "Closed • no earned reward")
                        }
                        override fun onAdFailedToShowFullScreenContent(error: AdError) {
                            busy = false
                            state("Show failed ${error.code}: ${error.message}")
                        }
                    }
                    ad.show(host) {
                        if (!earned) {
                            earned = true
                            emitSignal("reward_earned")
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
