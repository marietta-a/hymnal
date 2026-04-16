import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hymnal/models/hymn.dart';
import 'package:hymnal/providers/favorites_provider.dart';
import 'package:hymnal/providers/font_provider.dart';
import 'package:hymnal/providers/hymn_provider.dart';
import 'package:hymnal/providers/theme_provider.dart';
import 'package:hymnal/screens/game_screen.dart';
import 'package:hymnal/screens/settings_screen.dart';
import 'package:hymnal/services/notification_service.dart';
import 'package:hymnal/widgets/hymn_list_tile.dart';
import 'package:hymnal/widgets/search_bar.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:provider/provider.dart';
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

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-2717868471631453/2339502385'
      : 'ca-app-pub-3940256099942544/2934735716'; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetExpansionState();
      // Banner ads are Android-only; iOS uses a subscription model with no ads
      if (Platform.isAndroid) {
        _loadAd();
      }
      _checkForUpdate();
      // Reschedule daily notification so hymn content refreshes each day
      NotificationService().rescheduleDailyHymnIfEnabled();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() async {
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.sizeOf(context).width.truncate(),
    );

    if (size == null) return;

    BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    ).load();
  }

  Widget _buildAdWidget() {
    if (!_isBannerAdLoaded || _bannerAd == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  Future<void> _checkForUpdate() async {
    if (!Platform.isAndroid) return;
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        InAppUpdate.installUpdateListener.listen((InstallStatus status) {
          if (status == InstallStatus.downloaded) {
            NotificationService().showUpdateDownloadedNotification();
          }
        });
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
  }

  void _resetExpansionState() {
    _expandedCategories.clear();
    final allHymns = Provider.of<HymnProvider>(context, listen: false).allHymns;
    if (allHymns.isNotEmpty) {
      final String firstCategory = allHymns.first.category ?? 'General';
      setState(() => _expandedCategories[firstCategory] = true);
    }
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
                onPressed: () => themeProvider.toggleTheme(!isDarkMode),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen())),
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
      body: Column(
        children: [
          Expanded(
            child: Consumer<HymnProvider>(
              builder: (context, hymnDataProvider, child) {
                if (_currentIndex == 0) {
                  return _buildGroupedHymnList(hymnDataProvider.filteredHymns);
                } else {
                  return _buildHymnListPage(_getFavoriteHymns(hymnDataProvider, favoritesProvider));
                }
              },
            ),
          ),
          _buildAdWidget(), 
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GameScreen()),
            );
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notes), label: 'All Hymns'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz_rounded), label: 'Quiz'),
        ],
      ),
    );
  }

  List<Hymn> _getFavoriteHymns(HymnProvider hymnProvider, FavoritesProvider favoritesProvider) {
    return hymnProvider.allHymns.where((hymn) => favoritesProvider.isFavorite(hymn.number)).toList();
  }

  Widget _buildHymnListPage(List<Hymn> hymns) {
    if (hymns.isEmpty) return const Center(child: Text('No favorites yet.'));
    return ListView.separated(
      itemCount: hymns.length,
      itemBuilder: (context, index) => HymnListTile(hymn: hymns[index]),
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
      if (_expandedCategories[currentCategory] ?? false) displayList.add(hymn);
    }

    return ListView.builder(
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final item = displayList[index];
        if (item is String) {
          return _buildCategoryHeader(item, _expandedCategories[item] ?? false);
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

  Widget _buildCategoryHeader(String category, bool isExpanded) {
    return Consumer<FontProvider>(
      builder: (context, fontProvider, child) {
        return Material(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
          child: InkWell(
            onTap: () => setState(() => _expandedCategories[category] = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      category.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.getFont(
                        fontProvider.headerFontFamily,
                        fontSize: fontProvider.headerFontSize,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                       color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}