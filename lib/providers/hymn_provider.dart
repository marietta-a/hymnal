// lib/providers/hymn_provider.dart
import 'package:flutter/foundation.dart';
import 'package:hymnal/models/hymn.dart';
class HymnProvider with ChangeNotifier {
  List<Hymn> _hymns = [];
  List<Hymn> _filteredHymns = [];

  HymnProvider() {
    loadHymns();
  }

  List<Hymn> get allHymns => _hymns;
  List<Hymn> get filteredHymns => _filteredHymns;

  void loadHymns() {
    _hymns = Hymn.hymns; // In a real app, load from a file or DB
    _filteredHymns = _hymns;
    notifyListeners();
  }

  void searchHymns(String query) {
    if (query.isEmpty) {
      _filteredHymns = _hymns;
    } else {
      _filteredHymns = _hymns.where((hymn) {
        final titleLower = hymn.title.toLowerCase();
        final queryLower = query.toLowerCase();
        final numberString = hymn.number.toString();
        return titleLower.contains(queryLower) || numberString.contains(queryLower);
      }).toList();
    }
    notifyListeners();
  }
}