import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hymnal/providers/ad_provider.dart';
import 'package:hymnal/services/iap_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late IAPService _iapService;
  late Future<List<ProductDetails>> _productsFuture;

  @override
  void initState() {
    super.initState();
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    _iapService = IAPService(adProvider);
    _iapService.initialize();
    _productsFuture = _iapService.getProducts();
  }

  @override
  void dispose() {
    _iapService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // --- Branding ---
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.library_music_rounded,
                  size: 44,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cameroon Hymnal',
                style: GoogleFonts.montserrat(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Access the full hymnal with\na yearly subscription.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // --- Feature list ---
              _featureRow(context, Icons.menu_book_rounded, 'All Hymns',
                  'Browse and search the complete hymnal'),
              const SizedBox(height: 16),
              _featureRow(context, Icons.text_fields_rounded, 'Custom Fonts',
                  'Adjust text size and style to your preference'),
              const SizedBox(height: 16),
              _featureRow(context, Icons.favorite_rounded, 'Favourites',
                  'Save hymns for quick access'),
              const SizedBox(height: 16),
              _featureRow(context, Icons.block_rounded, 'No Ads',
                  'Completely ad-free experience'),

              const Spacer(flex: 3),

              // --- Subscribe button ---
              FutureBuilder<List<ProductDetails>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  final loading = snapshot.connectionState == ConnectionState.waiting;
                  final product = snapshot.hasData && snapshot.data!.isNotEmpty
                      ? snapshot.data!.first
                      : null;

                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: loading || product == null
                              ? null
                              : () => _iapService.buySubscription(product),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                )
                              : Text(
                                  product != null
                                      ? 'Subscribe — ${product.price}/year'
                                      : 'Subscribe',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => _iapService.restorePurchases(),
                        child: Text(
                          'Restore Purchase',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),
              Text(
                'Payment will be charged to your Apple ID.\nSubscription renews automatically each year.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.outline,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(
      BuildContext context, IconData icon, String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Icon(Icons.check_circle_rounded,
            size: 20, color: colorScheme.primary),
      ],
    );
  }
}
