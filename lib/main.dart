import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hymnal/providers/ad_provider.dart';
import 'package:hymnal/providers/favorites_provider.dart';
import 'package:hymnal/providers/font_provider.dart';
import 'package:hymnal/providers/game_provider.dart';
import 'package:hymnal/providers/hymn_provider.dart';
import 'package:hymnal/providers/theme_provider.dart';
import 'package:hymnal/screens/home_screen.dart';
import 'package:hymnal/screens/paywall_screen.dart';
import 'package:hymnal/services/notification_service.dart';
import 'package:hymnal/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

Future<void> main() async {

  // Ensure Flutter bindings are initialized before using plugins.
  WidgetsFlutterBinding.ensureInitialized();

  // Initalize ads
  await MobileAds.instance.initialize(); 

  // Initialize the notification service.
  await NotificationService().initialize();

  // Track app opens for iOS trial
  int appOpens = 0;
  if (Platform.isIOS) {
    final prefs = await SharedPreferences.getInstance();
    appOpens = (prefs.getInt('app_opens_count') ?? 0) + 1;
    await prefs.setInt('app_opens_count', appOpens);
  }

  runApp(MyApp(appOpens: appOpens));
}

class MyApp extends StatelessWidget {
  final int appOpens;
  const MyApp({super.key, this.appOpens = 0});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdProvider()), // Add this
        ChangeNotifierProvider(create: (_) => HymnProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Cameroon Hymnal',
            themeMode: themeProvider.themeMode,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            home: Platform.isIOS
                ? Consumer<AdProvider>(
                    builder: (context, adProvider, _) {
                      // Show Paywall on 3rd app open if not subscribed
                      if (appOpens >= 3 && !adProvider.isSubscribed) {
                        return const PaywallScreen();
                      }
                      return const HomeScreen();
                    },
                  )
                : const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}