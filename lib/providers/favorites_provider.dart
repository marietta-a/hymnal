// lib/providers/favorites_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider with ChangeNotifier {
  List<int> _favoriteHymnNumbers = [];
  static const _favoritesKey = 'favoriteHymns';

  FavoritesProvider() {
    loadFavorites();
  }

  List<int> get favoriteHymnNumbers => _favoriteHymnNumbers;

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_favoritesKey) ?? [];
    _favoriteHymnNumbers = favs.map((e) => int.parse(e)).toList();
    notifyListeners();
  }

  bool isFavorite(int hymnNumber) {
    return _favoriteHymnNumbers.contains(hymnNumber);
  }

  Future<void> toggleFavorite(int hymnNumber) async {
    if (isFavorite(hymnNumber)) {
      _favoriteHymnNumbers.remove(hymnNumber);
    } else {
      _favoriteHymnNumbers.add(hymnNumber);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = _favoriteHymnNumbers.map((e) => e.toString()).toList();
    await prefs.setStringList(_favoritesKey, favs);
  }
}