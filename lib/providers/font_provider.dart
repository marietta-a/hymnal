// lib/providers/font_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider with ChangeNotifier {
  // --- Available Font Families ---
  static const List<String> availableFontFamilies = [
    'Lato', // Default
    'Roboto Slab',
    'Merriweather',
    'Open Sans',
    'Montserrat',
  ];

  // --- Defaults ---
  static const double _defaultHeaderFontSize = 16.0;
  static const String _defaultHeaderFontFamily = 'Lato';
  static const double _defaultLyricsFontSize = 18.0;
  static const String _defaultLyricsFontFamily = 'Lato';

  // --- Private State ---
  double _headerFontSize = _defaultHeaderFontSize;
  String _headerFontFamily = _defaultHeaderFontFamily;
  double _lyricsFontSize = _defaultLyricsFontSize;
  String _lyricsFontFamily = _defaultLyricsFontFamily;

  // --- Keys for SharedPreferences ---
  static const _headerSizeKey = 'header_font_size';
  static const _headerFamilyKey = 'header_font_family';
  static const _lyricsSizeKey = 'lyrics_font_size';
  static const _lyricsFamilyKey = 'lyrics_font_family';

  // --- Getters ---
  double get headerFontSize => _headerFontSize;
  String get headerFontFamily => _headerFontFamily;
  double get lyricsFontSize => _lyricsFontSize;
  String get lyricsFontFamily => _lyricsFontFamily;

  FontProvider() {
    _loadPreferences();
  }

  // --- Update Methods ---
  void setHeaderFontSize(double size) {
    _headerFontSize = size;
    _savePreferences();
    notifyListeners();
  }

  void setHeaderFontFamily(String family) {
    if (availableFontFamilies.contains(family)) {
      _headerFontFamily = family;
      _savePreferences();
      notifyListeners();
    }
  }

  void setLyricsFontSize(double size) {
    _lyricsFontSize = size;
    _savePreferences();
    notifyListeners();
  }

  void setLyricsFontFamily(String family) {
    if (availableFontFamilies.contains(family)) {
      _lyricsFontFamily = family;
      _savePreferences();
      notifyListeners();
    }
  }

  // --- Persistence ---
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_headerSizeKey, _headerFontSize);
    await prefs.setString(_headerFamilyKey, _headerFontFamily);
    await prefs.setDouble(_lyricsSizeKey, _lyricsFontSize);
    await prefs.setString(_lyricsFamilyKey, _lyricsFontFamily);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _headerFontSize = prefs.getDouble(_headerSizeKey) ?? _defaultHeaderFontSize;
    _headerFontFamily = prefs.getString(_headerFamilyKey) ?? _defaultHeaderFontFamily;
    _lyricsFontSize = prefs.getDouble(_lyricsSizeKey) ?? _defaultLyricsFontSize;
    _lyricsFontFamily = prefs.getString(_lyricsFamilyKey) ?? _defaultLyricsFontFamily;
    notifyListeners();
  }
}