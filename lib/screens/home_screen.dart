// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hymnal/models/hymn.dart';
import 'package:hymnal/providers/favorites_provider.dart';
import 'package:hymnal/providers/font_provider.dart';
import 'package:hymnal/providers/hymn_provider.dart';
import 'package:hymnal/providers/theme_provider.dart';
import 'package:hymnal/screens/settings_screen.dart';
import 'package:hymnal/widgets/hymn_list_tile.dart';
import 'package:hymnal/widgets/search_bar.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final Map<String, bool> _expandedCategories = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetExpansionState();
      _checkForUpdate(); // Call the update check when the screen loads
    });
  }

  

  // ==================== NEW: IN-APP UPDATE LOGIC ====================
  Future<void> _checkForUpdate() async {
    // In-app updates are only supported on Android.
    if (!Platform.isAndroid) return;

    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      // Check if an update is available and if a flexible update is allowed.
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          updateInfo.flexibleUpdateAllowed) {
        
        // Start the flexible update flow. This will show a dialog to the user.
        await InAppUpdate.startFlexibleUpdate();
        
        // Listen for the update to finish downloading.
        InAppUpdate.installUpdateListener.listen((InstallStatus status) {
          if (status == InstallStatus.downloaded) {
            // When the download is complete, show a SnackBar to prompt the user to restart.
            _showUpdateDownloadedSnackbar();
          }
        });
      }
    } catch (e) {
      print('Failed to check for in-app update: $e');
    }
  }

  void _showUpdateDownloadedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('A new update has been downloaded.'),
        // Keep the SnackBar visible indefinitely until the user acts on it.
        duration: const Duration(days: 365), 
        action: SnackBarAction(
          label: 'RESTART',
          onPressed: () {
            // This will complete the installation and restart the app.
            InAppUpdate.completeFlexibleUpdate();
          },
        ),
      ),
    );
  }

  void _resetExpansionState() {
    _expandedCategories.clear();
    final allHymns = Provider.of<HymnProvider>(context, listen: false).allHymns;
    if (allHymns.isNotEmpty) {
      final String firstCategory = allHymns.first.category ?? 'General';
      setState(() {
        _expandedCategories[firstCategory] = true;
      });
    }
  }

  void _shareApp() {
    const String appName = "Cameroon Hymnal";
    const String message =
        "Check out the new edition of $appName! Download it here:";
    const String playStoreUrl =
        "https://play.google.com/store/apps/details?id=com.hymnal.cameroon";
    const String appStoreUrl =
        "https://apps.apple.com/app/your-app-name/idYOUR_APP_ID";
    final String url = Platform.isAndroid ? playStoreUrl : appStoreUrl;
    Share.share(
      '$message\n\n$url',
      subject: 'Download the $appName',
    );
  }

  @override
  Widget build(BuildContext context) {
    final hymnProvider = Provider.of<HymnProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cameroon Hymnal'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeProvider.toggleTheme(!isDarkMode);
                },
                tooltip: 'Toggle Theme',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareApp,
            tooltip: 'Share App',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: SearchBarWidget(
            onChanged: (query) {
              hymnProvider.searchHymns(query);
              setState(() {
                _searchQuery = query;
                _expandedCategories.clear();
                if (query.isNotEmpty) {
                  final categoriesInSearchResults = hymnProvider.filteredHymns
                      .map((hymn) => hymn.category ?? 'General')
                      .toSet();
                  for (var category in categoriesInSearchResults) {
                    _expandedCategories[category] = true;
                  }
                } else {
                  _resetExpansionState();
                }
              });
            },
          ),
        ),
      ),
      body: Consumer<HymnProvider>(
        builder: (context, hymnDataProvider, child) {
          final List<Widget> pages = [
            _buildGroupedHymnList(hymnDataProvider.filteredHymns),
            _buildHymnListPage(
                _getFavoriteHymns(hymnDataProvider, favoritesProvider)),
          ];
          return pages[_currentIndex];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notes),
            label: 'All Hymns',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }

  List<Hymn> _getFavoriteHymns(
      HymnProvider hymnProvider, FavoritesProvider favoritesProvider) {
    return hymnProvider.allHymns
        .where((hymn) => favoritesProvider.isFavorite(hymn.number))
        .toList();
  }

  Widget _buildHymnListPage(List<Hymn> hymns) {
    if (hymns.isEmpty) {
      return const Center(child: Text('No favorites yet.'));
    }
    return ListView.separated(
      itemCount: hymns.length,
      itemBuilder: (context, index) {
        return HymnListTile(hymn: hymns[index]);
      },
      separatorBuilder: (context, index) => const Divider(height: 1),
    );
  }

  Widget _buildGroupedHymnList(List<Hymn> hymns) {
    if (hymns.isEmpty && _searchQuery.isNotEmpty) {
      return const Center(child: Text('No hymns found for your search.'));
    }

    final allHymns = Provider.of<HymnProvider>(context).allHymns;
    if (allHymns.isEmpty) return const Center(child: CircularProgressIndicator());

    final List<dynamic> displayList = [];
    String? currentCategory;

    for (final hymn in hymns) {
      final hymnCategory = hymn.category ?? 'General';
      if (hymnCategory != currentCategory) {
        currentCategory = hymnCategory;
        displayList.add(currentCategory);
      }
      if (_expandedCategories[currentCategory] ?? false) {
        displayList.add(hymn);
      }
    }

    return ListView.builder(
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final item = displayList[index];
        if (item is String) {
          final isExpanded = _expandedCategories[item] ?? false;
          return _buildCategoryHeader(item, isExpanded);
        } else if (item is Hymn) {
          return Column(
            children: [
              HymnListTile(hymn: item),
              const Divider(height: 1, indent: 16),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
  
  // ==================== FIX IS HERE ====================
  Widget _buildCategoryHeader(String category, bool isExpanded) {
    return Consumer<FontProvider>(
      builder: (context, fontProvider, child) {
        return Material(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
          child: InkWell(
            onTap: () {
              setState(() {
                _expandedCategories[category] = !isExpanded;
              });
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Wrap the Text widget with Expanded. This tells the text to take up
                  // all available space and prevents it from pushing the icon off-screen.
                  Expanded(
                    child: Text(
                      category.toUpperCase(),
                      // 2. Add overflow handling as a safeguard for very long text.
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.getFont(
                        fontProvider.headerFontFamily,
                        fontSize: fontProvider.headerFontSize,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  // The Icon is not expanded, so it takes up its natural, fixed width.
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  // ==================== END OF FIX ====================
}