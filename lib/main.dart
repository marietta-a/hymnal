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
import 'dart:io';

Future<void> main() async {
  
  // Ensure Flutter bindings are initialized before using plugins.
  WidgetsFlutterBinding.ensureInitialized();

  // Initalize ads
  await MobileAds.instance.initialize(); 
  
  // Initialize the notification service.
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            home: 
            Platform.isIOS
                ? Consumer<AdProvider>(
                    builder: (context, adProvider, _) => adProvider.isSubscribed
                        ? const HomeScreen()
                        : const PaywallScreen(),
                  )
                : 
                const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}