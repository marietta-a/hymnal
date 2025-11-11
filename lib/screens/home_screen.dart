// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:hymnal/models/hymn.dart';
import 'package:hymnal/providers/favorites_provider.dart';
import 'package:hymnal/providers/hymn_provider.dart';
import 'package:hymnal/widgets/hymn_list_tile.dart';
import 'package:hymnal/widgets/search_bar.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final Map<String, bool> _expandedCategories = {};
  
  // --- NEW: Keep track of the search query ---
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Set the initial default state (first category expanded)
    _resetExpansionState();
  }

  // --- NEW: Helper method to reset the expansion state ---
  void _resetExpansionState() {
    _expandedCategories.clear();
    if (Hymn.hymns.isNotEmpty) {
      final String firstCategory = Hymn.hymns.first.category ?? 'General';
      _expandedCategories[firstCategory] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use listen: false here because we will manually handle updates in setState
    final hymnProvider = Provider.of<HymnProvider>(context, listen: false); 
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    // Use a Consumer for the part of the UI that needs to rebuild
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cameroon Hymnal'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          // --- UPDATED: The onChanged callback now manages expansion state ---
          child: SearchBarWidget(
            onChanged: (query) {
              // Trigger search in the provider
              hymnProvider.searchHymns(query);

              // Update the UI state
              setState(() {
                _searchQuery = query;
                _expandedCategories.clear(); // Clear all previous expansion states

                if (query.isNotEmpty) {
                  // If searching, find all categories in the results and expand them
                  final categoriesInSearchResults = hymnProvider.filteredHymns
                      .map((hymn) => hymn.category ?? 'General')
                      .toSet(); // Use a Set to get unique categories
                  
                  for (var category in categoriesInSearchResults) {
                    _expandedCategories[category] = true;
                  }
                } else {
                  // If search is cleared, reset to the default state
                  _resetExpansionState();
                }
              });
            },
          ),
        ),
      ),
      // --- UPDATED: Wrap body in a Consumer to get the latest filteredHymns ---
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

    for (final hymn in hymns) {
      final hymnCategory = hymn.category ?? 'General';

      if (hymnCategory != currentCategory) {
        currentCategory = hymnCategory;
        displayList.add(currentCategory);
      }
      
      // Use the class-level map to decide if hymns should be shown
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
            // When user taps, toggle the state
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