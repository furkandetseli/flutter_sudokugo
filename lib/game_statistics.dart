class GameStatistics {
  int gamesPlayed;
  int gamesWon;
  int gamesLost;
  int bestTime;
  int totalHintsUsed;
  int totalCorrectMoves;
  int totalMistakes;

  GameStatistics({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.bestTime = 0,
    this.totalHintsUsed = 0,
    this.totalCorrectMoves = 0,
    this.totalMistakes = 0,
  });

  factory GameStatistics.fromMap(Map<String, int> map) {
    return GameStatistics(
      gamesPlayed: map['gamesPlayed'] ?? 0,
      gamesWon: map['gamesWon'] ?? 0,
      gamesLost: map['gamesLost'] ?? 0,
      bestTime: map['bestTime'] ?? 0,
      totalHintsUsed: map['totalHintsUsed'] ?? 0,
      totalCorrectMoves: map['totalCorrectMoves'] ?? 0,
      totalMistakes: map['totalMistakes'] ?? 0,
    );
  }

  Map<String, int> toMap() {
    return {
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'gamesLost': gamesLost,
      'bestTime': bestTime,
      'totalHintsUsed': totalHintsUsed,
      'totalCorrectMoves': totalCorrectMoves,
      'totalMistakes': totalMistakes,
    };
  }
}