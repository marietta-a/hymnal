import 'package:flutter/material.dart';
import 'package:hymnal/providers/ad_provider.dart';
import 'package:hymnal/screens/font_settings_screen.dart';
import 'package:hymnal/services/iap_service.dart';
import 'package:hymnal/services/notification_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late IAPService _iapService;
  final InAppReview _inAppReview = InAppReview.instance;

  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    final adProvider = Provider.of<AdProvider>(context, listen: false);
    _iapService = IAPService(adProvider);
    _iapService.initialize();
    _loadNotificationPrefs();
  }

  Future<void> _loadNotificationPrefs() async {
    final enabled = await NotificationService().isDailyNotificationEnabled();
    final time = await NotificationService().getSavedNotificationTime();
    if (mounted) setState(() { _notificationsEnabled = enabled; _notificationTime = time; });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (mounted) setState(() => _notificationsEnabled = !_notificationsEnabled);
    if (_notificationsEnabled) {
      await NotificationService().scheduleDailyHymnNotification(_notificationTime);
    } else {
      await NotificationService().cancelDailyHymnNotification();
    }
    // if (mounted) setState(() => _notificationsEnabled = !_notificationsEnabled);
  }

  Future<void> _pickNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      helpText: 'Choose daily reminder time',
    );
    if (picked == null || !mounted) return;
    setState(() => _notificationTime = picked);
    if (_notificationsEnabled) {
      await NotificationService().scheduleDailyHymnNotification(picked);
    }
  }

  @override
  void dispose() {
    _iapService.dispose();
    super.dispose();
  }

  void _shareApp() {
    const String appName = "Cameroon Hymnal";
    final String url = Platform.isAndroid
        ? "https://play.google.com/store/apps/details?id=com.hymnal.cameroon"
        : "https://apps.apple.com/app/your-app-id"; // Update with real Apple ID
    Share.share("Download the $appName here: \n\n$url");
  }

  Future<void> _rateApp() async {
    // if (await _inAppReview.isAvailable()) {
    //   await _inAppReview.requestReview();
    // } else 
    if (Platform.isIOS) {
      await _inAppReview.openStoreListing(
        appStoreId: 'your-app-store-id', // Update with real App Store ID
      );
    } else {
      // Android: openStoreListing uses the app's package name automatically
      await _inAppReview.openStoreListing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final adProvider = Provider.of<AdProvider>(context);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // --- APP SECTION ---
          _sectionLabel('App'),
          _settingsCard([
            _tile(
              icon: Icons.star_rounded,
              iconColor: Colors.amber.shade700,
              title: 'Rate the App',
              subtitle: 'Enjoying the hymnal? Leave us a review',
              onTap: _rateApp,
            ),
            _divider(),
            if(!Platform.isIOS)
            _tile(
              icon: Icons.share_rounded,
              iconColor: colorScheme.primary,
              title: 'Share App',
              subtitle: 'Tell others about Cameroon Hymnal',
              onTap: _shareApp,
            ),
          ]),

          // --- APPEARANCE SECTION ---
          _sectionLabel('Appearance'),
          _settingsCard([
            _tile(
              icon: Icons.text_fields_rounded,
              iconColor: colorScheme.tertiary,
              title: 'Font Settings',
              subtitle: 'Customize text style and size',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FontSettingsScreen()),
              ),
            ),
          ]),

          // --- NOTIFICATIONS SECTION ---
          // _sectionLabel('Notifications'),
          // _settingsCard([
          //   SwitchListTile(
          //     secondary: _iconBox(Icons.notifications_rounded, colorScheme.primary),
          //     title: const Text('Daily Hymn Reminder',
          //         style: TextStyle(fontWeight: FontWeight.w500)),
          //     subtitle: const Text('Get a hymn delivered every day',
          //         style: TextStyle(fontSize: 12)),
          //     value: _notificationsEnabled,
          //     onChanged: _toggleNotifications,
          //     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          //   ),
          //   if (_notificationsEnabled) ...[
          //     _divider(),
          //     ListTile(
          //       leading: _iconBox(Icons.schedule_rounded, colorScheme.secondary),
          //       title: const Text('Reminder Time',
          //           style: TextStyle(fontWeight: FontWeight.w500)),
          //       subtitle: Text(_notificationTime.format(context),
          //           style: const TextStyle(fontSize: 12)),
          //       trailing: Icon(Icons.chevron_right_rounded,
          //           size: 20, color: colorScheme.outline),
          //       onTap: _pickNotificationTime,
          //       contentPadding:
          //           const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          //     ),
          //   ],
          // ]),

          // // --- PREMIUM SECTION (iOS Only) ---
          // if (Platform.isIOS) ...[
          //   _sectionLabel('Premium'),
          //   _settingsCard([
          //     if (!adProvider.isSubscribed)
          //       FutureBuilder<List<ProductDetails>>(
          //         future: _iapService.getProducts(),
          //         builder: (context, snapshot) {
          //           if (snapshot.connectionState == ConnectionState.waiting) {
          //             return ListTile(
          //               leading: _iconBox(Icons.hourglass_top_rounded, colorScheme.primary),
          //               title: const Text('Loading...'),
          //               trailing: const SizedBox(
          //                 width: 20,
          //                 height: 20,
          //                 child: CircularProgressIndicator(strokeWidth: 2),
          //               ),
          //               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          //             );
          //           }
          //           if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          //             final product = snapshot.data!.first;
          //             return _tile(
          //               icon: Icons.workspace_premium_rounded,
          //               iconColor: Colors.amber.shade700,
          //               title: 'Yearly Subscription (${product.price}/yr)',
          //               subtitle: 'Support the app with an ad-free experience',
          //               onTap: () => _iapService.buySubscription(product),
          //             );
          //           }
          //           return _tile(
          //             icon: Icons.block_rounded,
          //             iconColor: colorScheme.outline,
          //             title: 'Subscription Unavailable',
          //             subtitle: 'Please try again later',
          //           );
          //         },
          //       ),
          //     if (adProvider.isSubscribed) ...[
          //       _tile(
          //         icon: Icons.check_circle_rounded,
          //         iconColor: Colors.green,
          //         title: 'Subscribed',
          //         subtitle: 'Thank you for your support!',
          //       ),
          //       _divider(),
          //     ],
              // _tile(
              //   icon: Icons.restore_rounded,
              //   iconColor: colorScheme.primary,
              //   title: 'Restore Purchases',
              //   subtitle: 'Recover a previous purchase',
              //   onTap: () => _iapService.restorePurchases(),
              // ),
          //   ]),
          // ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: _iconBox(icon, iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_right_rounded, size: 20,
              color: Theme.of(context).colorScheme.outline)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 68);
}
