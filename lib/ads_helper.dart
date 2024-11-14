import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdsHelper {
  static const String rewardedAdId = 'ca-app-pub-5423156413875549/1963673225';
  static const String interstitialAdId = 'ca-app-pub-5423156413875549/2606842495';

  static Widget buildAdContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/ad.png',
                  width: 16,
                  height: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Advertisement',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  static Widget buildAdButton({
    required String text,
    required VoidCallback onPressed,
    required double width,
    required double fontSize,
    required double iconSize,
    Color color = Colors.blue,
  }) {
    return Container(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                child: Image.asset(
                  'assets/ad.png',
                  width: iconSize,
                  height: iconSize,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            text,
            style: TextStyle(color: color, fontSize: fontSize),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static Future<RewardedAd?> loadRewardedAd({
    required Function(RewardedAd ad) onAdLoaded,
    required Function(LoadAdError error) onAdFailedToLoad,
  }) async {
    try {
      await RewardedAd.load(
        adUnitId: rewardedAdId,
        request: AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
        ),
      );
    } catch (e) {
      print('Error loading rewarded ad: $e');
      return null;
    }
    return null;
  }

  static Future<InterstitialAd?> loadInterstitialAd({
    required Function(InterstitialAd ad) onAdLoaded,
    required Function(LoadAdError error) onAdFailedToLoad,
  }) async {
    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: onAdLoaded,
          onAdFailedToLoad: onAdFailedToLoad,
        ),
      );
    } catch (e) {
      print('Error loading interstitial ad: $e');
      return null;
    }
    return null;
  }

  static void showRewardedAd(RewardedAd? rewardedAd, {
    required VoidCallback onAdDismissed,
    required Function(AdWithoutView, RewardItem) onUserEarnedReward,
  }) {
    if (rewardedAd == null) return;

    rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        onAdDismissed();
      },
    );

    rewardedAd.show(onUserEarnedReward: onUserEarnedReward);
  }

  static void showInterstitialAd(InterstitialAd? interstitialAd, {
    required VoidCallback onAdDismissed,
  }) {
    if (interstitialAd == null) return;

    interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        onAdDismissed();
      },
    );

    interstitialAd.show();
  }
}