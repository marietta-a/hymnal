import 'dart:async';
import 'dart:io' show Platform;
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
import 'package:url_launcher/url_launcher.dart';

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

  bool _showWhatsAppBanner = true;
  Timer? _bannerToggleTimer;

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
      _bannerToggleTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() => _showWhatsAppBanner = !_showWhatsAppBanner);
      });
      // Reschedule daily notification so hymn content refreshes each day
      NotificationService().rescheduleDailyHymnIfEnabled();
    });
  }

  @override
  void dispose() {
    _bannerToggleTimer?.cancel();
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

  Widget _buildWhatsAppBanner() {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('https://chat.whatsapp.com/DtyNctOi2Nc7J6LDvO6kTT');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: const Color(0xFF25D366),
        child: Row(
          children: [
            const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Join our WhatsApp Group',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Cameroon Hymnal Community',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Join Now',
                style: TextStyle(
                  color: Color(0xFF25D366),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerArea() {
    // When no ad is loaded (iOS or before first ad loads), always show the WhatsApp banner.
    if (!_isBannerAdLoaded || _bannerAd == null) return _buildWhatsAppBanner();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _showWhatsAppBanner
          ? KeyedSubtree(key: const ValueKey('wa'), child: _buildWhatsAppBanner())
          : KeyedSubtree(key: const ValueKey('ad'), child: _buildAdWidget()),
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
          // _buildAdWidget(),
          _buildBannerArea(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
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

  Widget _buildBottomNav() {
    final colorScheme = Theme.of(context).colorScheme;

    const items = [
      (
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
        label: 'Hymns',
        color: Color(0xFF00897B), // teal
      ),
      (
        icon: Icons.favorite_border_rounded,
        activeIcon: Icons.favorite_rounded,
        label: 'Favourites',
        color: Color(0xFFE91E63), // pink
      ),
      (
        icon: Icons.extension_outlined,
        activeIcon: Icons.extension_rounded,
        label: 'Quiz',
        color: Color(0xFFF57C00), // orange
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = _currentIndex == i;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (i == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GameScreen()),
                      );
                    } else {
                      setState(() => _currentIndex = i);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? item.color.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            selected ? item.activeIcon : item.icon,
                            key: ValueKey(selected),
                            color: selected
                                ? item.color
                                : colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: selected
                                ? item.color
                                : colorScheme.onSurfaceVariant,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}