import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/widgets/expense_summary_card.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';

void main() {
  // ─── ExpenseSummaryCard Tests ──────────────────────────────────────────────
  group('ExpenseSummaryCard', () {
    testWidgets('renders merchant name correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSummaryCard(
              merchant: 'Coffee House',
              amount: 75000,
              date: DateTime(2024, 12, 25),
              category: 'food',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Coffee House'), findsOneWidget);
    });

    testWidgets('formats date as dd/MM/yyyy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSummaryCard(
              merchant: 'Test Store',
              amount: 100000,
              date: DateTime(2024, 1, 5),
              category: 'shopping',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('05/01/2024'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSummaryCard(
              merchant: 'Grab',
              amount: 45000,
              date: DateTime.now(),
              category: 'transport',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });
  });

  // ─── ReceiptParser Tests ───────────────────────────────────────────────────
  group('ReceiptParser', () {
    test('extracts amount with dot thousands separator', () {
      const text = 'Tong tien: 150.000d';
      final result = ReceiptParser.parse(text);
      expect(result.totalAmount, equals(150000.0));
    });

    test('extracts amount with comma thousands separator', () {
      const text = 'Total: 250,000 VND';
      final result = ReceiptParser.parse(text);
      expect(result.totalAmount, equals(250000.0));
    });

    test('extracts date in dd/MM/yyyy format', () {
      const text = 'Ngay: 25/12/2024\nTotal: 50000';
      final result = ReceiptParser.parse(text);
      expect(result.date, equals(DateTime(2024, 12, 25)));
    });

    test('extracts date in yyyy-MM-dd format', () {
      const text = 'Date: 2024-06-15\nAmount: 80000';
      final result = ReceiptParser.parse(text);
      expect(result.date, equals(DateTime(2024, 6, 15)));
    });

    test('returns zero confidence for empty text', () {
      final result = ReceiptParser.parse('');
      expect(result.confidence, equals(0.0));
    });

    test('confidence increases with more parsed fields', () {
      const fullText = '''
COFFEE HOUSE
25/12/2024
Tong tien: 75.000d
''';
      final result = ReceiptParser.parse(fullText);
      expect(result.confidence, greaterThan(0.5));
    });

    test('handles million VND amounts', () {
      const text = 'Thanh toan: 1.500.000d';
      final result = ReceiptParser.parse(text);
      expect(result.totalAmount, equals(1500000.0));
    });
  });
}
