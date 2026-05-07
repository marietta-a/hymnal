import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdProvider with ChangeNotifier {
  bool _isSubscribed = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  /// True only on iOS when the user has an active yearly subscription.
  /// On Android this is always false — ads are always shown.
  bool get isSubscribed => _isSubscribed;

  AdProvider() {
    if (Platform.isIOS) {
      _loadSubscriptionStatus();
    }
    _loadRewardedAd();
  }

  Future<void> _loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = prefs.getBool('isSubscribed') ?? false;
    notifyListeners();
  }

  Future<void> setSubscribed(bool value) async {
    _isSubscribed = value;
    if (Platform.isIOS) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSubscribed', value);
    }
    notifyListeners();
  }

  // ── Rewarded Ads ────────────────────────────────────────────────────────────

  bool get isRewardedAdReady => _rewardedAd != null;

  void _loadRewardedAd() {
    if (_isRewardedAdLoading) return;
    _isRewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-2717868471631453/1992604092'
          : 'ca-app-pub-2717868471631453/8850040920', 
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedAdLoading = false;
          debugPrint('RewardedAd failed to load: $error');
          // Retry loading after a delay
          Future.delayed(const Duration(seconds: 10), _loadRewardedAd);
        },
      ),
    );
  }

  void showRewardedAd({
    required Function() onRewardEarned,
    required Function() onAdDismissed,
    Function()? onAdNotReady,
  }) {
    if (_rewardedAd == null) {
      _loadRewardedAd();
      if (onAdNotReady != null) onAdNotReady();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        if (onAdNotReady != null) onAdNotReady();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      onRewardEarned();
    });
  }
}
