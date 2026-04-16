// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // 1. Import AdMob
// import 'package:hymnal/models/hymn.dart';
// import 'package:hymnal/providers/favorites_provider.dart';
// import 'package:hymnal/providers/font_provider.dart';
// import 'package:hymnal/providers/hymn_provider.dart';
// import 'package:hymnal/providers/theme_provider.dart';
// import 'package:hymnal/screens/settings_screen.dart';
// import 'package:hymnal/services/notification_service.dart';
// import 'package:hymnal/widgets/hymn_list_tile.dart';
// import 'package:hymnal/widgets/search_bar.dart';
// import 'package:in_app_update/in_app_update.dart';
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'dart:io' show Platform;

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _currentIndex = 0;
//   final Map<String, bool> _expandedCategories = {};
//   String _searchQuery = '';

//   // --- ADMOB PROPERTIES ---
//   BannerAd? _bannerAd;
//   bool _isBannerAdLoaded = false;

//   // Replace these with your REAL Ad Unit IDs (the ones with the "/")
//   final String _adUnitId = Platform.isAndroid
//       ? 'ca-app-pub-2717868471631453/2339502385'
//       : 'ca-app-pub-2717868471631453/2339502385'; // iOS Test Banner ID TODO

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _resetExpansionState();
//       _loadAd(); 
//       _checkForUpdate();
//     });
//   }

//   @override
//   void dispose() {
//     _bannerAd?.dispose(); // Dispose Ad to free memory
//     super.dispose();
//   }

//   void _loadAd() async {
//     // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
//     final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
//       MediaQuery.sizeOf(context).width.truncate(),
//     );

//     if (size == null) {
//       // Unable to get width of anchored banner.
//       return;
//     }

//     BannerAd(
//       adUnitId: _adUnitId,
//       request: const AdRequest(),
//       size: size,
//       listener: BannerAdListener(
//         onAdLoaded: (ad) {
//           // Called when an ad is successfully received.
//           debugPrint("Ad was loaded.");
          
//           setState(() {
//             _bannerAd = ad as BannerAd;
//             _isBannerAdLoaded = true;
//           });
//         },
//         onAdFailedToLoad: (ad, err) {
//           // Called when an ad request failed.
//           debugPrint("Ad failed to load with error: $err");
//           ad.dispose();
//         },
//       ),
//     ).load();
//   }

//   /// Helper widget to display the ad safely
//   Widget _buildAdWidget() {
//     if (_isBannerAdLoaded && _bannerAd != null) {
//       return Container(
//         alignment: Alignment.center,
//         width: _bannerAd!.size.width.toDouble(),
//         height: _bannerAd!.size.height.toDouble(),
//         margin: const EdgeInsets.symmetric(vertical: 16.0),
//         child: AdWidget(ad: _bannerAd!),
//       );
//     }
//     return const SizedBox.shrink();
//   }

//   // ==================== IN-APP UPDATE LOGIC ====================
//   Future<void> _checkForUpdate() async {
//     if (!Platform.isAndroid) return;
//     try {
//       final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
//       if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
//         await InAppUpdate.startFlexibleUpdate();
//         InAppUpdate.installUpdateListener.listen((InstallStatus status) {
//           if (status == InstallStatus.downloaded) {
//             NotificationService().showUpdateDownloadedNotification();
//           }
//         });
//       }
//     } catch (e) {
//       debugPrint('Failed to check for in-app update: $e');
//     }
//   }

//   void _resetExpansionState() {
//     _expandedCategories.clear();
//     final allHymns = Provider.of<HymnProvider>(context, listen: false).allHymns;
//     if (allHymns.isNotEmpty) {
//       final String firstCategory = allHymns.first.category ?? 'General';
//       setState(() {
//         _expandedCategories[firstCategory] = true;
//       });
//     }
//   }

//   void _shareApp() {
//     const String appName = "Cameroon Hymnal";
//     const String playStoreUrl = "https://play.google.com/store/apps/details?id=com.hymnal.cameroon";
//     const String appStoreUrl = "https://apps.apple.com/app/your-app-name/idYOUR_APP_ID";
//     final String url = Platform.isAndroid ? playStoreUrl : appStoreUrl;
//     final String message = "Download the new edition of $appName here: \n\n$url";
//     Share.share(message, subject: 'Download $appName');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final hymnProvider = Provider.of<HymnProvider>(context, listen: false);
//     final favoritesProvider = Provider.of<FavoritesProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Cameroon Hymnal'),
//         actions: [
//           Consumer<ThemeProvider>(
//             builder: (context, themeProvider, child) {
//               final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
//               return IconButton(
//                 icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
//                 onPressed: () => themeProvider.toggleTheme(!isDarkMode),
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.settings),
//             onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen())),
//           ),
//           IconButton(
//             icon: const Icon(Icons.share),
//             onPressed: _shareApp,
//           ),
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(kToolbarHeight),
//           child: SearchBarWidget(
//             onChanged: (query) {
//               hymnProvider.searchHymns(query);
//               setState(() {
//                 _searchQuery = query;
//                 _expandedCategories.clear();
//                 if (query.isNotEmpty) {
//                   final categoriesInSearchResults = hymnProvider.filteredHymns
//                       .map((hymn) => hymn.category ?? 'General')
//                       .toSet();
//                   for (var category in categoriesInSearchResults) {
//                     _expandedCategories[category] = true;
//                   }
//                 } else {
//                   _resetExpansionState();
//                 }
//               });
//             },
//           ),
//         ),
//       ),
//       body: Consumer<HymnProvider>(
//         builder: (context, hymnDataProvider, child) {
//           if (_currentIndex == 0) {
//             return _buildGroupedHymnList(hymnDataProvider.filteredHymns);
//           } else {
//             return _buildHymnListPage(_getFavoriteHymns(hymnDataProvider, favoritesProvider));
//           }
//         },
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) => setState(() => _currentIndex = index),
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.notes), label: 'All Hymns'),
//           BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
//         ],
//       ),
//     );
//   }

//   List<Hymn> _getFavoriteHymns(HymnProvider hymnProvider, FavoritesProvider favoritesProvider) {
//     return hymnProvider.allHymns
//         .where((hymn) => favoritesProvider.isFavorite(hymn.number))
//         .toList();
//   }

//   /// Favorites Page with Ad at the end
//   Widget _buildHymnListPage(List<Hymn> hymns) {
//     if (hymns.isEmpty) return const Center(child: Text('No favorites yet.'));
    
//     // Add 1 to length for the ad
//     int itemCount = hymns.length + (_isBannerAdLoaded ? 1 : 0);

//     return ListView.separated(
//       itemCount: itemCount,
//       itemBuilder: (context, index) {
//         if (index == hymns.length) return _buildAdWidget(); // Ad at bottom
//         return HymnListTile(hymn: hymns[index]);
//       },
//       separatorBuilder: (context, index) {
//         if (index == hymns.length - 1 && _isBannerAdLoaded) return const SizedBox.shrink();
//         return const Divider(height: 1);
//       },
//     );
//   }

//   /// Main Hymn List with Ad at the end of search results
//   Widget _buildGroupedHymnList(List<Hymn> hymns) {
//     if (hymns.isEmpty && _searchQuery.isNotEmpty) {
//       return const Center(child: Text('No hymns found for your search.'));
//     }

//     final allHymns = Provider.of<HymnProvider>(context).allHymns;
//     if (allHymns.isEmpty) return const Center(child: CircularProgressIndicator());

//     final List<dynamic> displayList = [];
//     String? currentCategory;

//     for (final hymn in hymns) {
//       final hymnCategory = hymn.category ?? 'General';
//       if (hymnCategory != currentCategory) {
//         currentCategory = hymnCategory;
//         displayList.add(currentCategory);
//       }
//       if (_expandedCategories[currentCategory] ?? false) {
//         displayList.add(hymn);
//       }
//     }

//     // Add 1 to length for the ad
//     int itemCount = displayList.length + (_isBannerAdLoaded ? 1 : 0);

//     return ListView.builder(
//       itemCount: itemCount,
//       itemBuilder: (context, index) {
//         // If this is the extra slot at the end, show the ad
//         if (index == displayList.length) {
//           return _buildAdWidget();
//         }

//         final item = displayList[index];
//         if (item is String) {
//           return _buildCategoryHeader(item, _expandedCategories[item] ?? false);
//         } else if (item is Hymn) {
//           return Column(
//             children: [
//               HymnListTile(hymn: item),
//               const Divider(height: 1, indent: 16),
//             ],
//           );
//         }
//         return const SizedBox.shrink();
//       },
//     );
//   }

//   Widget _buildCategoryHeader(String category, bool isExpanded) {
//     return Consumer<FontProvider>(
//       builder: (context, fontProvider, child) {
//         return Material(
//           color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
//           child: InkWell(
//             onTap: () => setState(() => _expandedCategories[category] = !isExpanded),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       category.toUpperCase(),
//                       overflow: TextOverflow.ellipsis,
//                       maxLines: 1,
//                       style: GoogleFonts.getFont(
//                         fontProvider.headerFontFamily,
//                         fontSize: fontProvider.headerFontSize,
//                         fontWeight: FontWeight.bold,
//                         color: Theme.of(context).colorScheme.primary,
//                         letterSpacing: 1.2,
//                       ),
//                     ),
//                   ),
//                   Icon(
//                     isExpanded ? Icons.expand_less : Icons.expand_more,
//                     color: Theme.of(context).colorScheme.primary,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }