// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hymnal/providers/favorites_provider.dart';
import 'package:hymnal/providers/hymn_provider.dart';
import 'package:hymnal/providers/theme_provider.dart';
import 'package:hymnal/providers/font_provider.dart'; // Import FontProvider
import 'package:hymnal/screens/home_screen.dart';
import 'package:hymnal/services/notification_service.dart';
import 'package:hymnal/theme/app_theme.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  
  // Ensure Flutter bindings are initialized before using plugins.
  WidgetsFlutterBinding.ensureInitialized();
  
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
        ChangeNotifierProvider(create: (_) => HymnProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontProvider()), // Add FontProvider
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Cameroon Hymnal App',
            themeMode: themeProvider.themeMode,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}