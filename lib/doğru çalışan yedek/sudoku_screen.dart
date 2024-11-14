import 'package:flutter/material.dart';
import 'dart:math';

class Move {
  final int row;
  final int col;
  final int? value;

  Move(this.row, this.col, this.value);
}

class SudokuScreen extends StatefulWidget {
  @override
  _SudokuScreenState createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  List<List<int?>> sudokuBoard = List.generate(9, (_) => List.filled(9, null));
  List<List<int>> solution = List.generate(9, (_) => List.filled(9, 0));
  List<List<bool>> isSystemGenerated = List.generate(9, (_) => List.filled(9, false));
  int? selectedRow;
  int? selectedCol;
  int errorCount = 0;
  String lastError = '';
  List<Move> moveHistory = [];

  @override
  void initState() {
    super.initState();
    _generateFullSudoku();
    _removeRandomCells();
  }

  void _generateFullSudoku() {
    List<int> baseNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    baseNumbers.shuffle();

    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        solution[i][j] = baseNumbers[(i * 3 + i ~/ 3 + j) % 9];
      }
    }
  }

  void _removeRandomCells() {
    Random random = Random();
    int cellsToRemove = 40 + random.nextInt(21); // Remove between 40 to 60 cells

    while (cellsToRemove > 0) {
      int row = random.nextInt(9);
      int col = random.nextInt(9);

      if (sudokuBoard[row][col] == null) {
        sudokuBoard[row][col] = solution[row][col];
        isSystemGenerated[row][col] = true;
        cellsToRemove--;
      }
    }
  }

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
        lastError = '';
      });
    }
  }

  void _onNumberSelected(int number) {
    if (selectedRow != null && selectedCol != null) {
      setState(() {
        if (sudokuBoard[selectedRow!][selectedCol!] == null || !isSystemGenerated[selectedRow!][selectedCol!]) {
          if (number == solution[selectedRow!][selectedCol!]) {
            sudokuBoard[selectedRow!][selectedCol!] = number;
            moveHistory.add(Move(selectedRow!, selectedCol!, number));
            lastError = '';
          } else if (sudokuBoard[selectedRow!][selectedCol!] != solution[selectedRow!][selectedCol!]) {
            errorCount++;
            lastError = 'Hata: ${selectedRow! + 1}. satır, ${selectedCol! + 1}. sütunda yanlış sayı!';
          }
        }
      });
    }
  }

  Widget _buildNumberButton(int number, double size) {
    return Container(
      margin: EdgeInsets.all(4),
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: () => _onNumberSelected(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          number.toString(),
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
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
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: List.generate(9, (row) {
              return Row(
                children: List.generate(9, (col) {
                  bool isRightBorder = (col + 1) % 3 == 0 && col != 8;
                  bool isBottomBorder = (row + 1) % 3 == 0 && row != 8;
                  bool isSelected = row == selectedRow && col == selectedCol;
                  bool isSameRow = row == selectedRow;
                  bool isSameCol = col == selectedCol;
                  bool isSameBox = (row ~/ 3 == selectedRow! ~/ 3) && (col ~/ 3 == selectedCol! ~/ 3);
                  bool isSameNumber = sudokuBoard[row][col] != null &&
                      selectedRow != null &&
                      selectedCol != null &&
                      sudokuBoard[selectedRow!][selectedCol!] != null &&
                      sudokuBoard[row][col] == sudokuBoard[selectedRow!][selectedCol!];

                  Color cellColor;
                  Color textColor = Colors.black;
                  if (isSelected) {
                    cellColor = Colors.blue[300]!;
                  } else if (isSameRow || isSameCol || isSameBox) {
                    cellColor = Colors.blue[100]!;
                  } else if (isSameNumber) {
                    cellColor = Colors.green[300]!;
                  } else if (isSystemGenerated[row][col]) {
                    cellColor = Colors.grey[200]!;
                  } else {
                    cellColor = Colors.white;
                  }

                  if (sudokuBoard[row][col] != null) {
                    if (sudokuBoard[row][col] == solution[row][col] && !isSystemGenerated[row][col]) {
                      textColor = Colors.blue;
                    } else if (sudokuBoard[row][col] != solution[row][col]) {
                      cellColor = Colors.red[100]!;
                    }
                  }

                  return GestureDetector(
                    onTap: () => _onCellTapped(row, col),
                    child: Container(
                      width: cellSize,
                      height: cellSize,
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
                  );
                }),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sudoku'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final maxBoardSize = constraints.maxWidth * 0.9;
            final boardSize = maxBoardSize.clamp(0.0, availableHeight * 0.6);

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Center(
                          child: _buildSudokuBoard(boardSize),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.undo),
                                onPressed: _undoLastMove,
                                tooltip: 'Son hamleyi geri al',
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hata: $errorCount',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  lastError,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60), // Rakam paneli ile üstteki elemanlar arasında biraz boşluk
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: availableHeight * 0.3,
                          ),
                          child: _buildNumberConsole(
                            constraints.maxWidth,
                            availableHeight * 0.3,
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
}