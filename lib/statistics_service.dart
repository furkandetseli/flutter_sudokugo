import 'package:shared_preferences/shared_preferences.dart';
import 'game_statistics.dart';

class StatisticsService {
  static const String _gamesPlayedKey = 'gamesPlayed';
  static const String _gamesWonKey = 'gamesWon';
  static const String _gamesLostKey = 'gamesLost';
  static const String _bestTimeKey = 'bestTime';
  static const String _totalHintsUsedKey = 'totalHintsUsed';
  static const String _totalCorrectMovesKey = 'totalCorrectMoves';
  static const String _totalMistakesKey = 'totalMistakes';

  static Future<void> incrementGamesPlayed() async {
    final stats = await loadStatistics();
    stats.gamesPlayed++;
    await saveStatistics(stats);
  }

  static Future<void> incrementGamesWon() async {
    final stats = await loadStatistics();
    stats.gamesWon++;
    await saveStatistics(stats);
  }

  static Future<void> incrementGamesLost() async {
    final stats = await loadStatistics();
    stats.gamesLost++;
    await saveStatistics(stats);
  }

  static Future<void> updateBestTime(int seconds) async {
    final stats = await loadStatistics();
    if (seconds < stats.bestTime || stats.bestTime == 0) {
      stats.bestTime = seconds;
      await saveStatistics(stats);
    }
  }

  static Future<void> incrementHintsUsed() async {
    final stats = await loadStatistics();
    stats.totalHintsUsed++;
    await saveStatistics(stats);
  }

  static Future<void> incrementCorrectMoves() async {
    final stats = await loadStatistics();
    stats.totalCorrectMoves++;
    await saveStatistics(stats);
  }

  static Future<void> incrementMistakes() async {
    final stats = await loadStatistics();
    stats.totalMistakes++;
    await saveStatistics(stats);
  }

  static Future<GameStatistics> loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    return GameStatistics(
      gamesPlayed: prefs.getInt(_gamesPlayedKey) ?? 0,
      gamesWon: prefs.getInt(_gamesWonKey) ?? 0,
      gamesLost: prefs.getInt(_gamesLostKey) ?? 0,
      bestTime: prefs.getInt(_bestTimeKey) ?? 0,
      totalHintsUsed: prefs.getInt(_totalHintsUsedKey) ?? 0,
      totalCorrectMoves: prefs.getInt(_totalCorrectMovesKey) ?? 0,
      totalMistakes: prefs.getInt(_totalMistakesKey) ?? 0,
    );
  }

  static Future<void> saveStatistics(GameStatistics stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_gamesPlayedKey, stats.gamesPlayed);
    await prefs.setInt(_gamesWonKey, stats.gamesWon);
    await prefs.setInt(_gamesLostKey, stats.gamesLost);
    await prefs.setInt(_bestTimeKey, stats.bestTime);
    await prefs.setInt(_totalHintsUsedKey, stats.totalHintsUsed);
    await prefs.setInt(_totalCorrectMovesKey, stats.totalCorrectMoves);
    await prefs.setInt(_totalMistakesKey, stats.totalMistakes);
  }
}