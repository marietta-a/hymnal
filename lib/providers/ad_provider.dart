import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdProvider with ChangeNotifier {
  bool _isSubscribed = false;

  /// True only on iOS when the user has an active yearly subscription.
  /// On Android this is always false — ads are always shown.
  bool get isSubscribed => _isSubscribed;

  AdProvider() {
    if (Platform.isIOS) {
      _loadSubscriptionStatus();
    }
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
}
