// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hymnal/models/hymn.dart';
import 'package:hymnal/providers/favorites_provider.dart';
import 'package:hymnal/providers/hymn_provider.dart';
import 'package:hymnal/widgets/hymn_list_tile.dart';
import 'package:hymnal/widgets/search_bar.dart';
import 'package:provider/provider.dart';

// --- 1. Import necessary packages ---
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform; // Used to check the operating system

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
    _resetExpansionState();
  }

  void _resetExpansionState() {
    _expandedCategories.clear();
    // Assuming Hymn model has a static list for initial category
    // You might need to adjust this if your data is loaded asynchronously.
    final allHymns = Provider.of<HymnProvider>(context, listen: false).allHymns;
    if (allHymns.isNotEmpty) {
      final String firstCategory = allHymns.first.category ?? 'General';
      _expandedCategories[firstCategory] = true;
    }
  }
  
  // --- 3. Add the _shareApp method ---
  void _shareApp() {
    const String appName = "Cameroon Hymnal";
    const String message = "Check out the new edition of $appName! Download it here:";
    
    // IMPORTANT: Replace these with your actual app store links once published!
    const String playStoreUrl = "https://play.google.com/store/apps/details?id=com.hymnal.cameroon";
    const String appStoreUrl = "https://apps.apple.com/app/your-app-name/idYOUR_APP_ID";

    // Select the appropriate URL based on the platform
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
          // --- 2. Add a Share button to the AppBar ---
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
            _buildHymnListPage(_getFavoriteHymns(hymnDataProvider, favoritesProvider)),
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

  List<Hymn> _getFavoriteHymns(HymnProvider hymnProvider, FavoritesProvider favoritesProvider) {
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

    final List<dynamic> displayList = [];
    String? currentCategory;

    // A small fix to ensure the hymn provider is read within the build method scope
    final allHymns = Provider.of<HymnProvider>(context).allHymns;
    if (allHymns.isEmpty) return const Center(child: CircularProgressIndicator());


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

  Widget _buildCategoryHeader(String category, bool isExpanded) {
    return Material(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedCategories[category] = !isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}