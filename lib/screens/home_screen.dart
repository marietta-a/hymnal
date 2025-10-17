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

  @override
  Widget build(BuildContext context) {
    final hymnProvider = Provider.of<HymnProvider>(context);
    final favoritesProvider = Provider.of<FavoritesProvider>(context);

    final List<Widget> pages = [
      _buildHymnListPage(hymnProvider.filteredHymns),
      _buildHymnListPage(_getFavoriteHymns(hymnProvider, favoritesProvider)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Hymnal'),
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
            icon: Icon(Icons.music_note),
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
      return const Center(child: Text('No hymns found.'));
    }
    return ListView.separated(
      itemCount: hymns.length,
      itemBuilder: (context, index) {
        return HymnListTile(hymn: hymns[index]);
      },
      separatorBuilder: (context, index) => const Divider(height: 1),
    );
  }
}