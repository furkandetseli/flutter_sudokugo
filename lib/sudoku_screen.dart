import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'game_statistics.dart';
import 'statistics_service.dart';
import 'dart:async';
import 'dart:convert';
import 'ads_helper.dart';

String saniyeToDakika(int saniye) {
  int dakika = saniye ~/ 60;  // Tam sayı bölme işlemi
  int kalanSaniye = saniye % 60;  // Kalan saniyeleri bulmak için mod işlemi
  if(kalanSaniye>-1 && kalanSaniye < 10){
    return '$dakika:0$kalanSaniye';
  }else{
    return '$dakika:$kalanSaniye';
  }

}

class Move {

  final int row;
  final int col;
  final int number;

  Move(this.row, this.col, this.number);

  Map<String, dynamic> toJson() => {
    'row': row,
    'col': col,
    'number': number,
  };

  factory Move.fromJson(Map<String, dynamic> json) => Move(
    json['row'],
    json['col'],
    json['number'],
  );
}

class SudokuScreen extends StatefulWidget {
  final bool continueGame;

  SudokuScreen({this.continueGame = false});
  @override
  _SudokuScreenState createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  List<List<int?>> sudokuBoard = List.generate(9, (_) => List.filled(9, null));
  List<List<int>> solution = List.generate(9, (_) => List.filled(9, 0));
  List<List<bool>> isSystemGenerated = List.generate(9, (_) => List.filled(9, false));
  List<List<bool>> isError = List.generate(9, (_) => List.filled(9, false));
  int? selectedRow;
  int? selectedCol;
  int errorCount = 0;
  List<Move> moveHistory = [];
  Map<int, int> numberUsageCount = {};
  int hintCount = 1;
  int highScore = 0;
  int currentScore = 0;
  String rewardType = '';

  late GameStatistics _statistics;

  late Timer _timer;
  int _elapsedSeconds = 0;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

  // init - dispose
  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _loadRewardedAd();
    _loadInterstitialAd();
    if (widget.continueGame) {
      _loadGame();
    } else {
      _startNewGame();
    }
    _loadStatistics();
    _startTimer(); // Timer'ı başlat
  }

  @override
  void dispose() {
    _timer.cancel(); // Timer'ı durdur
    saveGameState();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  //admob
  void _showRewardedAdForHint() {
    rewardType = 'hint';  // İpucu ödülü için
    _showRewardedAd();
  }

  void _showRewardedAdForError() {
    rewardType = 'error';  // Hata azaltma ödülü için
    _showRewardedAd();
  }

// Reklam yükleme
  void _loadRewardedAd() {
    AdsHelper.loadRewardedAd(
      onAdLoaded: (ad) {
        setState(() => _rewardedAd = ad);
      },
      onAdFailedToLoad: (error) {
        print('RewardedAd failed to load: $error');
      },
    );
  }

  void _loadInterstitialAd() {
    AdsHelper.loadInterstitialAd(
      onAdLoaded: (ad) {
        setState(() => _interstitialAd = ad);
      },
      onAdFailedToLoad: (error) {
        print('InterstitialAd failed to load: $error');
      },
    );
  }

// Reklam gösterme
  void _showRewardedAd() {
    AdsHelper.showRewardedAd(
      _rewardedAd,
      onAdDismissed: () {
        _loadRewardedAd();
      },
      onUserEarnedReward: (_, reward) {
        setState(() {
          if (rewardType == 'error') {
            errorCount--;
            if (errorCount < 0) errorCount = 0;
          } else if (rewardType == 'hint') {
            hintCount++;
          }
        });
      },
    );
  }

  void _showInterstitialAd() {
    AdsHelper.showInterstitialAd(
      _interstitialAd,
      onAdDismissed: () {
        _loadInterstitialAd();
      },
    );
  }

  //statistics
  Future<void> _loadStatistics() async {
    _statistics = await StatisticsService.loadStatistics();
    setState(() {}); // Yükleme tamamlandığında UI'ı güncelle
  }

  void _updateStatistics({bool isCorrect = false, bool isGameWon = false, bool isGameLost = false}) {
    if (isCorrect) {
      _statistics.totalCorrectMoves++;
    } else {
      _statistics.totalMistakes++;
    }

    if (isGameWon) {
      _statistics.gamesWon++;
    } else if (isGameLost) {
      _statistics.gamesLost++;
    }

    StatisticsService.saveStatistics(_statistics);
  }

  //Oyun başlatma yeri
  void _startNewGame() {
    clearGameState();
    setState(() {
      sudokuBoard = List.generate(9, (_) => List.filled(9, null));
      isSystemGenerated = List.generate(9, (_) => List.filled(9, false));
      isError = List.generate(9, (_) => List.filled(9, false));
      errorCount = 0;
      moveHistory = [];
      selectedRow = null;
      selectedCol = null;
      _elapsedSeconds = 0;
      hintCount = 1;
      currentScore = 0;
      numberUsageCount = {
        1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0
      };
      _generateFullSudoku();
      _removeRandomCells();
      _updateNumberUsage();
      StatisticsService.incrementGamesPlayed();
    });
    saveGameState();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  Future<void> saveGameState() async {
    final prefs = await SharedPreferences.getInstance();

    // 2 boyutlu listeleri ve Map'i JSON'a uygun formata dönüştür
    final gameState = {
      'sudokuBoard': sudokuBoard.map((row) =>
          row.map((cell) => cell).toList()
      ).toList(),

      'isSystemGenerated': isSystemGenerated.map((row) =>
          row.map((cell) => cell).toList()
      ).toList(),

      'isError': isError.map((row) =>
          row.map((cell) => cell).toList()
      ).toList(),

      'errorCount': errorCount,
      'moveHistory': moveHistory.map((move) => move.toJson()).toList(),
      'selectedRow': selectedRow,
      'selectedCol': selectedCol,
      'hintCount': hintCount,
      'currentScore': currentScore,
      'numberUsageCount': numberUsageCount.map((key, value) =>
          MapEntry(key.toString(), value)
      ),
      'elapsedSeconds': _elapsedSeconds,
    };

    await prefs.setString('gameState', jsonEncode(gameState));
  }

  Future<bool> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final gameStateString = prefs.getString('gameState');

    if (gameStateString != null) {
      try {
        final gameState = jsonDecode(gameStateString);

        setState(() {
          // 2 boyutlu listeleri geri dönüştür
          sudokuBoard = List<List<int?>>.from(
              gameState['sudokuBoard'].map((row) =>
              List<int?>.from(row.map((cell) => cell as int?))
              )
          );

          isSystemGenerated = List<List<bool>>.from(
              gameState['isSystemGenerated'].map((row) =>
              List<bool>.from(row.map((cell) => cell as bool))
              )
          );

          isError = List<List<bool>>.from(
              gameState['isError'].map((row) =>
              List<bool>.from(row.map((cell) => cell as bool))
              )
          );

          errorCount = gameState['errorCount'] as int;

          moveHistory = (gameState['moveHistory'] as List)
              .map((move) => Move.fromJson(move as Map<String, dynamic>))
              .toList();

          selectedRow = gameState['selectedRow'] as int?;
          selectedCol = gameState['selectedCol'] as int?;
          hintCount = gameState['hintCount'] as int;
          currentScore = gameState['currentScore'] as int;

          // numberUsageCount'u geri dönüştür
          numberUsageCount = Map<int, int>.from(
              (gameState['numberUsageCount'] as Map<String, dynamic>).map(
                      (key, value) => MapEntry(int.parse(key), value as int)
              )
          );

          _elapsedSeconds = gameState['elapsedSeconds'] as int;
        });

        return true;
      } catch (e) {
        print('Error loading game state: $e');
        return false;
      }
    }
    return false;
  }

  Future<void> _loadGame() async {
    bool loaded = await loadGameState();
    if (!loaded) {
      _startNewGame();
    }
    _startTimer();
  }

  Future<void> clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gameState');
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _updateHighScore(int score) async {
    if (score > highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', score);
      setState(() {
        highScore = score;
      });
    }
  }

  // sudoku mantığı
  void _updateNumberUsage() {
    numberUsageCount = {
      1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0
    };

    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        final currentNumber = sudokuBoard[i][j];
        if (currentNumber != null) {
          numberUsageCount[currentNumber] = (numberUsageCount[currentNumber] ?? 0) + 1;
        }
      }
    }
  }

  bool isNumberFullyUsed(int number) {
    return (numberUsageCount[number] ?? 0) >= 9;
  }

  void _generateFullSudoku() {
    // Önce tahtayı temizle
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        solution[i][j] = 0;
      }
    }

    // Recursive olarak sudoku çöz
    _solveSudoku(0, 0);
  }

  bool _solveSudoku(int row, int col) {
    // Eğer son sütunun sonuna geldiysek, bir sonraki satıra geç
    if (col == 9) {
      row++;
      col = 0;
    }

    // Eğer son satırın sonuna geldiysek, sudoku tamamlandı
    if (row == 9) return true;

    // Eğer hücre zaten doluysa, bir sonraki hücreye geç
    if (solution[row][col] != 0) {
      return _solveSudoku(row, col + 1);
    }

    // 1-9 arası rakamları karıştır
    List<int> numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    numbers.shuffle();

    // Her rakamı dene
    for (int num in numbers) {
      // Eğer rakam geçerliyse
      if (_isValidMove(row, col, num)) {
        solution[row][col] = num;

        // Recursive olarak devam et
        if (_solveSudoku(row, col + 1)) {
          return true;
        }

        // Eğer çözüm bulunamadıysa geri al
        solution[row][col] = 0;
      }
    }

    return false;
  }

  bool _isValidMove(int row, int col, int num) {
    // Satır kontrolü
    for (int x = 0; x < 9; x++) {
      if (solution[row][x] == num) return false;
    }

    // Sütun kontrolü
    for (int x = 0; x < 9; x++) {
      if (solution[x][col] == num) return false;
    }

    // 3x3 kutu kontrolü
    int startRow = row - row % 3;
    int startCol = col - col % 3;

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (solution[i + startRow][j + startCol] == num) return false;
      }
    }

    return true;
  }

  List<int> findAllPossibleNumbers(List<List<int?>> board, int row, int col) {
    Set<int> possibilities = Set.from([1, 2, 3, 4, 5, 6, 7, 8, 9]);

    // Satır kontrolü
    for (int x = 0; x < 9; x++) {
      if (board[row][x] != null) {
        possibilities.remove(board[row][x]);
      }
    }

    // Sütun kontrolü
    for (int x = 0; x < 9; x++) {
      if (board[x][col] != null) {
        possibilities.remove(board[x][col]);
      }
    }

    // 3x3 kutu kontrolü
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[i + startRow][j + startCol] != null) {
          possibilities.remove(board[i + startRow][j + startCol]);
        }
      }
    }

    return possibilities.toList();
  }

  List<Map<String, int>> findAllPossiblePositionsForNumber(List<List<int?>> board, int number) {
    List<Map<String, int>> positions = [];

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == null) {
          List<int> possibilities = findAllPossibleNumbers(board, row, col);
          if (possibilities.contains(number)) {
            positions.add({'row': row, 'col': col});
          }
        }
      }
    }

    return positions;
  }

  bool isBoardValid(List<List<int?>> board) {
    // Satır kontrolü
    for (int row = 0; row < 9; row++) {
      Set<int> seen = {};
      for (int col = 0; col < 9; col++) {
        if (board[row][col] != null) {
          if (seen.contains(board[row][col])) return false;
          seen.add(board[row][col]!);
        }
      }
    }

    // Sütun kontrolü
    for (int col = 0; col < 9; col++) {
      Set<int> seen = {};
      for (int row = 0; row < 9; row++) {
        if (board[row][col] != null) {
          if (seen.contains(board[row][col])) return false;
          seen.add(board[row][col]!);
        }
      }
    }

    // 3x3 kutu kontrolü
    for (int block = 0; block < 9; block++) {
      Set<int> seen = {};
      int startRow = (block ~/ 3) * 3;
      int startCol = (block % 3) * 3;

      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          if (board[startRow + i][startCol + j] != null) {
            if (seen.contains(board[startRow + i][startCol + j])) return false;
            seen.add(board[startRow + i][startCol + j]!);
          }
        }
      }
    }

    return true;
  }

  bool isSolutionValid(List<List<int>> solution) {
    // Tüm hücrelerin dolu olduğunu kontrol et
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (solution[i][j] == 0 || solution[i][j] == null) return false;
      }
    }

    // Board geçerliliğini kontrol et
    return isBoardValid(solution.map((row) =>
        row.map((cell) => cell as int?).toList()).toList());
  }

  void printDebugInfo(List<List<int?>> board, List<List<int>> solution, int number, int row, int col) {
    print('\nDebug Info for position ($row, $col) and number $number:');

    // Mevcut pozisyon için olası tüm sayıları bul
    List<int> possibleNumbers = findAllPossibleNumbers(board, row, col);
    print('Possible numbers for this cell: $possibleNumbers');

    // Bu sayı için olası tüm pozisyonları bul
    List<Map<String, int>> possiblePositions = findAllPossiblePositionsForNumber(board, number);
    print('Possible positions for number $number: $possiblePositions');

    // Çözümdeki değeri kontrol et
    print('Value in solution: ${solution[row][col]}');

    // Board ve çözüm geçerliliğini kontrol et
    print('Current board is valid: ${isBoardValid(board)}');
    print('Solution is valid: ${isSolutionValid(solution)}');
  }

  void _removeRandomCells() {
    Random random = Random();
    int cellsToRemove = 40 + random.nextInt(21);

    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        sudokuBoard[i][j] = solution[i][j];
        isSystemGenerated[i][j] = true;
      }
    }

    while (cellsToRemove > 0) {
      int row = random.nextInt(9);
      int col = random.nextInt(9);

      if (sudokuBoard[row][col] != null) {
        sudokuBoard[row][col] = null;
        isSystemGenerated[row][col] = false;
        cellsToRemove--;
      }
    }
    _updateNumberUsage();
  }

  // numara ekleme, ipucu gibi bölümler
  void _onCellTapped(int row, int col) {
    setState(() {
      selectedRow = row;
      selectedCol = col;
    });
  }

  void _undoLastMove() {
    if (moveHistory.isNotEmpty) {
      setState(() {
        Move lastMove = moveHistory.removeLast();
        sudokuBoard[lastMove.row][lastMove.col] = null;
        isError[lastMove.row][lastMove.col] = false;
        _updateNumberUsage();
      });
      saveGameState();
    }
  }

  void _giveHint() {
    if (isError.any((row) => row.contains(true))) {  // Herhangi bir hata varsa
      return;  // Fonksiyondan çık
    }

    if (hintCount > 0) {
      // Eğer ipucu varsa, doğrudan ipucu ver
      _provideHint();
    } else {
      // Eğer ipucu yoksa, ödüllü reklam izlet
      _showRewardedAdForHint();
    }
  }

  void _provideHint() {
    setState(() {
      List<List<int>> emptyCells = [];
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          if (sudokuBoard[row][col] == null) {
            emptyCells.add([row, col]);
          }
        }
      }
      if (emptyCells.isNotEmpty) {
        final random = Random();
        final randomIndex = random.nextInt(emptyCells.length);
        final selectedCell = emptyCells[randomIndex];
        final row = selectedCell[0];
        final col = selectedCell[1];

        sudokuBoard[row][col] = solution[row][col];
        isSystemGenerated[row][col] = true;
        hintCount--;
        _updateNumberUsage();
      }
    });
    StatisticsService.incrementHintsUsed();
    saveGameState();
  }

  void _onNumberSelected(int number) {
    if (selectedRow != null && selectedCol != null && !isNumberFullyUsed(number)) {
      if (sudokuBoard[selectedRow!][selectedCol!] == null || !isSystemGenerated[selectedRow!][selectedCol!]) {
        setState(() {
          sudokuBoard[selectedRow!][selectedCol!] = number;
          moveHistory.add(Move(selectedRow!, selectedCol!, number));
          _updateNumberUsage();

          bool isCorrect = number == solution[selectedRow!][selectedCol!];
          isError[selectedRow!][selectedCol!] = !isCorrect;

          if (isCorrect) {
            currentScore += 10;
            if(currentScore > highScore){
              highScore = currentScore;
            }
            _updateStatistics(isCorrect: true);
          } else {
            errorCount++;
            currentScore -= 5;
            if (currentScore < 0) currentScore = 0;
            _updateStatistics(isCorrect: false);

            if (errorCount >= 3) {
              _showGameOverWithAdDialog();
            }
          }

          if (_isGameCompleted()) {
            _showGameCompletedDialog();
          }
        });
        saveGameState();
      }
    }
  }

  //başarılı - başarısız mesajlar
  void _showGameCompletedDialog() {
    _timer.cancel();
    final currentScore = 1000 - (errorCount * 50);
    _updateHighScore(currentScore);
    StatisticsService.incrementGamesWon();
    StatisticsService.updateBestTime(_elapsedSeconds);
    _updateStatistics(isGameWon: true);
    _showInterstitialAd();

    // Get screen dimensions and text scale factor
    final screenSize = MediaQuery.of(context).size;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final isLargeDevice = screenSize.width > 400;

    // Calculate responsive font sizes
    final double titleFontSize = (isLargeDevice ? 24.0 : 20.0) / textScaleFactor;
    final double contentFontSize = (isLargeDevice ? 16.0 : 14.0) / textScaleFactor;
    final double buttonFontSize = (isLargeDevice ? 16.0 : 14.0) / textScaleFactor;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.congratulations,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            width: screenSize.width * 0.8,
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: screenSize.height * 0.4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.gameCompletedMessage,
                  style: TextStyle(fontSize: contentFontSize),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!.yourScore(currentScore),
                  style: TextStyle(
                    fontSize: contentFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!.highScoreLabel(highScore),
                  style: TextStyle(fontSize: contentFontSize),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.playAgain,
                style: TextStyle(fontSize: buttonFontSize),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _startNewGame();
              },
            ),
          ],
        );
      },
    );
  }

  void _showGameOverWithAdDialog() {
    // Get screen dimensions and text scale factor
    final screenSize = MediaQuery.of(context).size;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final isLargeDevice = screenSize.width > 400;

    // Calculate responsive font sizes
    final double titleFontSize = (isLargeDevice ? 24.0 : 20.0) / textScaleFactor;
    final double contentFontSize = (isLargeDevice ? 16.0 : 14.0) / textScaleFactor;
    final double buttonFontSize = (isLargeDevice ? 14.0 : 12.0) / textScaleFactor;

    // Calculate button sizes
    final double buttonPadding = screenSize.width * 0.02;
    final double buttonSpacing = screenSize.width * 0.02;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.gameOver,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            width: screenSize.width * 0.8,
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: screenSize.height * 0.4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.gameOverMessage,
                  style: TextStyle(fontSize: contentFontSize),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 300) {
                      // For very small screens, stack buttons vertically
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGameOverButton(
                            'Watch Ad Video\nRemove 1 Error',
                                () {
                              Navigator.of(context).pop();
                              _showRewardedAdForError();
                            },
                            buttonFontSize,
                            buttonPadding,
                          ),
                          SizedBox(height: buttonSpacing),
                          _buildGameOverButton(
                            AppLocalizations.of(context)!.playAgain,
                                () {
                              Navigator.of(context).pop();
                              _startNewGame();
                            },
                            buttonFontSize,
                            buttonPadding,
                          ),
                        ],
                      );
                    } else {
                      // For larger screens, keep buttons in a row
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildGameOverButton(
                              'Watch Ad Video\nRemove 1 Error',
                                  () {
                                Navigator.of(context).pop();
                                _showRewardedAdForError();
                              },
                              buttonFontSize,
                              buttonPadding,
                            ),
                          ),
                          SizedBox(width: buttonSpacing),
                          Expanded(
                            child: _buildGameOverButton(
                              AppLocalizations.of(context)!.playAgain,
                                  () {
                                Navigator.of(context).pop();
                                _startNewGame();
                              },
                              buttonFontSize,
                              buttonPadding,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameOverButton(String text, VoidCallback onPressed, double fontSize, double padding) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(padding),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize),
        textAlign: TextAlign.center,
      ),
    );
  }

  bool _isGameCompleted() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (sudokuBoard[i][j] != solution[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  // oyundaki görüntü ayarları
  Widget _buildNumberButton(int number, double size) {
    bool isFullyUsed = isNumberFullyUsed(number);
    bool hasError = isError.any((row) => row.contains(true));  // Hata kontrolü

    return Container(
      margin: EdgeInsets.all(4),
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: (isFullyUsed || hasError) ? null : () => _onNumberSelected(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFullyUsed ? Colors.grey[300] : Colors.white,
          foregroundColor: isFullyUsed ? Colors.grey[500] : Colors.black,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              number.toString(),
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
                color: isFullyUsed ? Colors.grey[500] : Colors.black,
              ),
            ),
            if (isFullyUsed)
              Container(
                height: 2,
                color: Colors.grey[500],
                margin: EdgeInsets.symmetric(horizontal: 4),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberConsole(double parentWidth, double maxHeight) {
    double buttonSize = (parentWidth - 32) / 3;
    buttonSize = buttonSize.clamp(40.0, maxHeight / 4);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => _buildNumberButton(index + 1, buttonSize)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => _buildNumberButton(index + 4, buttonSize)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => _buildNumberButton(index + 7, buttonSize)),
          ),
        ],
      ),
    );
  }

  Widget _buildSudokuBoard(double boardSize) {
    double cellSize = boardSize / 9;

    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (TapDownDetails details) {
              final box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final row = (localPosition.dy / (constraints.maxHeight / 9)).floor();
              final col = (localPosition.dx / (constraints.maxWidth / 9)).floor();
              if (row >= 0 && row < 9 && col >= 0 && col < 9) {
                _onCellTapped(row, col);
              }
            },
            onPanUpdate: (DragUpdateDetails details) {
              final box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final row = (localPosition.dy / (constraints.maxHeight / 9)).floor();
              final col = (localPosition.dx / (constraints.maxWidth / 9)).floor();
              if (row >= 0 && row < 9 && col >= 0 && col < 9) {
                _onCellTapped(row, col);
              }
            },
            child: Column(
              children: List.generate(9, (row) {
                return Expanded(
                  child: Row(
                    children: List.generate(9, (col) {
                      bool isRightBorder = (col + 1) % 3 == 0 && col != 8;
                      bool isBottomBorder = (row + 1) % 3 == 0 && row != 8;
                      bool isSelected = row == selectedRow && col == selectedCol;
                      bool isSameRow = row == selectedRow;
                      bool isSameCol = col == selectedCol;
                      bool isSameBox = selectedRow != null && selectedCol != null &&
                          (row ~/ 3 == selectedRow! ~/ 3) && (col ~/ 3 == selectedCol! ~/ 3);
                      bool isSameNumber = sudokuBoard[row][col] != null &&
                          selectedRow != null &&
                          selectedCol != null &&
                          sudokuBoard[selectedRow!][selectedCol!] != null &&
                          sudokuBoard[row][col] == sudokuBoard[selectedRow!][selectedCol!];

                      Color cellColor;
                      Color textColor = Colors.black;
                      if (isSelected) {
                        cellColor = Colors.blue[300]!;
                      } else if (isSameNumber) {
                        cellColor = Colors.blue[200]!;
                      } else if (isSameRow || isSameCol || isSameBox) {
                        cellColor = Colors.blue[100]!;
                      } else if (isSystemGenerated[row][col]) {
                        cellColor = Colors.grey[200]!;
                      } else {
                        cellColor = Colors.white;
                      }

                      if (sudokuBoard[row][col] != null) {
                        if (isError[row][col]) {
                          textColor = Colors.red;
                        } else if (!isSystemGenerated[row][col]) {
                          textColor = Colors.blue;
                        }
                      }

                      return Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cellColor,
                              border: Border(
                                right: BorderSide(
                                  width: isRightBorder ? 2.0 : 1.0,
                                  color: isRightBorder ? Colors.black : Colors.black.withOpacity(0.1),
                                ),
                                bottom: BorderSide(
                                  width: isBottomBorder ? 2.0 : 1.0,
                                  color: isBottomBorder ? Colors.black : Colors.black.withOpacity(0.1),
                                ),
                              ),
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Padding(
                                  padding: EdgeInsets.all(cellSize * 0.1),
                                  child: Text(
                                    sudokuBoard[row][col]?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: cellSize * 0.5,
                                      fontWeight: isSystemGenerated[row][col]
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.sudoku),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;
            final isLargeDevice = screenWidth > 400;

            final maxBoardSize = screenWidth * 0.9;
            final boardSize = maxBoardSize.clamp(0.0, availableHeight * (isLargeDevice ? 0.65 : 0.55));

            // Dinamik spacing değerleri
            final verticalSpacing = isLargeDevice ? 12.0 : 8.0;
            final buttonWidth = isLargeDevice ? 85.0 : 70.0;
            final fontSize = isLargeDevice ? 12.0 : 10.0;
            final iconSize = isLargeDevice ? 24.0 : 22.0;

            return SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeDevice ? 16.0 : 8.0,
                      vertical: isLargeDevice ? 8.0 : 4.0,
                    ),
                    child: Column(
                      children: [
                        // Score Panel
                        Container(
                          width: boardSize,
                          margin: EdgeInsets.only(bottom: verticalSpacing),
                          padding: EdgeInsets.symmetric(
                            vertical: isLargeDevice ? 8.0 : 6.0,
                            horizontal: isLargeDevice ? 12.0 : 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 8, // yatay boşluk
                            runSpacing: 4, // dikey boşluk
                            children: [
                              MediaQuery(
                                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                                child: Text(
                                  "${AppLocalizations.of(context)!.time}: ${saniyeToDakika(_elapsedSeconds)}",
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.035,
                                    fontWeight: FontWeight.w500,
                                  ).copyWith(
                                    fontSize: (MediaQuery.of(context).size.width * 0.035)
                                        .clamp(14.0, 18.0), // minimum 14, maximum 18 punto
                                  ),
                                ),
                              ),
                              MediaQuery(
                                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                                child: Text(
                                  '${AppLocalizations.of(context)!.highScoreLabel(highScore)}',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.035,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[700],
                                  ).copyWith(
                                    fontSize: (MediaQuery.of(context).size.width * 0.035)
                                        .clamp(14.0, 18.0), // minimum 14, maximum 18 punto
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: _buildSudokuBoard(boardSize),
                        ),
                        SizedBox(height: verticalSpacing),
                        _buildActionButtons(
                          context,
                          buttonWidth: buttonWidth,
                          fontSize: fontSize,
                          iconSize: iconSize,
                          isLargeDevice: isLargeDevice,
                        ),
                        SizedBox(height: verticalSpacing),
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: availableHeight * (isLargeDevice ? 0.3 : 0.28),
                          ),
                          child: _buildNumberConsole(
                            constraints.maxWidth,
                            availableHeight * (isLargeDevice ? 0.3 : 0.28),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, {
        required double buttonWidth,
        required double fontSize,
        required double iconSize,
        required bool isLargeDevice,
      }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeDevice ? 16.0 : 8.0,
        vertical: isLargeDevice ? 8.0 : 4.0,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.undo,
            label: AppLocalizations.of(context)!.undo,
            onPressed: _undoLastMove,
            buttonWidth: buttonWidth,
            fontSize: fontSize,
            iconSize: iconSize,
          ),
          _buildActionButton(
            icon: Icons.error_outline,
            label: AppLocalizations.of(context)!.errorCount(errorCount),
            color: Colors.red,
            buttonWidth: buttonWidth,
            fontSize: fontSize,
            iconSize: iconSize,
          ),
          _buildActionButton(
            icon: Icons.lightbulb_outline,
            label: AppLocalizations.of(context)!.hintCount(hintCount),
            onPressed: hintCount > 0 ? _giveHint : _showRewardedAdForHint,
            hintCount: hintCount,
            buttonWidth: buttonWidth,
            fontSize: fontSize,
            iconSize: iconSize,
          ),
          _buildActionButton(
            icon: Icons.emoji_events,
            label: AppLocalizations.of(context)!.scoreLabel(currentScore, highScore),
            color: Colors.amber,
            buttonWidth: buttonWidth,
            fontSize: fontSize,
            iconSize: iconSize,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    int? hintCount,
    VoidCallback? onPressed,
    Color color = Colors.blue,
    required double buttonWidth,
    required double fontSize,
    required double iconSize,
  }) {
    return Container(
      width: buttonWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(  // Yeni eklenen Container
            width: buttonWidth,
            height: iconSize + 16,  // İkon + padding için yeterli yükseklik
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(icon, color: color, size: iconSize),
                  onPressed: onPressed,
                  padding: EdgeInsets.all(8),
                ),
                if (hintCount != null && hintCount == 0)
                  Positioned(
                    top: 0,
                    right: buttonWidth * 0.15, // Sağ kenardan biraz içeri
                    child: Image.asset(
                      'assets/ad.png',
                      width: iconSize * 0.8,
                      height: iconSize * 0.8,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            label,
            style: TextStyle(color: color, fontSize: fontSize),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
