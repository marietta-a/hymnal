import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameProvider with ChangeNotifier {
  static const _highScoreKey = 'hymnal_game_highscore';

  int _highScore = 0;
  int get highScore => _highScore;

  GameProvider() {
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt(_highScoreKey) ?? 0;
    notifyListeners();
  }

  /// Submits a final score; persists it only if it beats the current best.
  Future<void> submitScore(int score) async {
    if (score > _highScore) {
      _highScore = score;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_highScoreKey, _highScore);
    }
  }
}
