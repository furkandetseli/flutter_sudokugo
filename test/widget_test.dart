import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('SudokuApp widget test', (WidgetTester tester) async {
    // Uygulamanın çalışıp çalışmadığını test ediyoruz.
    await tester.pumpWidget(SudokuApp());

    // "Sudoku" yazısının ekranda olup olmadığını kontrol ediyoruz.
    expect(find.text('Sudoku'), findsOneWidget);
  });
}
