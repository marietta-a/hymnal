// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hymnal/models/hymn.dart';
import 'package:hymnal/providers/favorites_provider.dart';
import 'package:hymnal/providers/hymn_provider.dart';
import 'package:hymnal/widgets/hymn_list_tile.dart';
import 'package:hymnal/widgets/search_bar.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final Map<String, bool> _expandedCategories = {};

  // --- NEW: Add initState to set the default expanded state ---
  @override
  void initState() {
    super.initState();
    // Since Hymn.hymns is a static list, we can access it before the widget builds.
    // This sets the very first category to be expanded by default.
    if (Hymn.hymns.isNotEmpty) {
      final String firstCategory = Hymn.hymns.first.category ?? 'General';
      _expandedCategories[firstCategory] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hymnProvider = Provider.of<HymnProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    final List<Widget> pages = [
      _buildGroupedHymnList(hymnProvider.filteredHymns),
      _buildHymnListPage(_getFavoriteHymns(hymnProvider, favoritesProvider)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cameroon Hymnal'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: SearchBarWidget(
            onChanged: (query) {
              hymnProvider.searchHymns(query);
            },
          ),
        ),
      ),
      body: pages[_currentIndex],
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
    if (hymns.isEmpty) {
      return const Center(child: Text('No hymns found.'));
    }

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