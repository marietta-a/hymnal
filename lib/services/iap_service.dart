import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hymnal/providers/ad_provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final AdProvider adProvider;

  // Set in App Store Connect as an auto-renewable subscription
  static const String yearlySubscriptionId = 'cam_hymn_annual_subs';

  IAPService(this.adProvider);

  void initialize() {
    _subscription = _iap.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint('IAP Error: $error'),
    );
  }

  Future<List<ProductDetails>> getProducts() async {
    final bool available = await _iap.isAvailable();
    if (!available) return [];
    const Set<String> ids = {yearlySubscriptionId};
    final ProductDetailsResponse response = await _iap.queryProductDetails(ids);
    return response.productDetails;
  }

  void buySubscription(ProductDetails product) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    // Auto-renewable subscriptions use buyNonConsumable in the plugin
    _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails details in purchaseDetailsList) {
      if (details.status == PurchaseStatus.purchased ||
          details.status == PurchaseStatus.restored) {
        adProvider.setSubscribed(true);
        if (details.pendingCompletePurchase) {
          _iap.completePurchase(details);
        }
      } else if (details.status == PurchaseStatus.error) {
        debugPrint('IAP purchase error: ${details.error}');
      }
    }
  }

  void dispose() => _subscription.cancel();
}
