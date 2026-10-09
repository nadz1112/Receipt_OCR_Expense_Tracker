import 'package:uuid/uuid.dart';

/// Supported expense categories in the VKU Expense Tracker
enum ExpenseCategory {
  food,
  transport,
  shopping,
  utilities,
  entertainment,
  other;

  /// Display label in Vietnamese/English
  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Ăn uống';
      case ExpenseCategory.transport:
        return 'Di chuyển';
      case ExpenseCategory.shopping:
        return 'Mua sắm';
      case ExpenseCategory.utilities:
        return 'Hóa đơn';
      case ExpenseCategory.entertainment:
        return 'Giải trí';
      case ExpenseCategory.other:
        return 'Khác';
    }
  }

  /// Factory from string for SQLite deserialization
  static ExpenseCategory fromString(String value) {
    final lower = value.toLowerCase().trim();
    return ExpenseCategory.values.firstWhere(
      (e) => e.name == lower || e.displayName.toLowerCase() == lower,
      orElse: () => ExpenseCategory.other,
    );
  }
}

/// Core domain entity representing a single expense/receipt record.
///
/// Supports full SQLite serialization via [toMap] / [fromMap].
/// Immutable value object — mutations produce new instances via [copyWith].
class ExpenseItem {
  /// Unique identifier (UUID v4)
  final String id;

  /// Merchant or store name extracted from receipt
  final String merchant;

  /// Total amount paid in Vietnamese Dong
  final double amount;

  /// Transaction timestamp
  final DateTime timestamp;

  /// Expense category for visual grouping and analytics
  final String category;

  /// Optional path to the captured receipt image
  final String? imagePath;

  const ExpenseItem({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.timestamp,
    required this.category,
    this.imagePath,
  });

  /// Factory constructor: creates a new expense with auto-generated UUID
  factory ExpenseItem.create({
    required String merchant,
    required double amount,
    required DateTime timestamp,
    required String category,
    String? imagePath,
  }) {
    return ExpenseItem(
      id: const Uuid().v4(),
      merchant: merchant,
      amount: amount,
      timestamp: timestamp,
      category: category,
      imagePath: imagePath,
    );
  }

  /// Serialize to SQLite-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
      'imagePath': imagePath,
    };
  }

  /// Deserialize from SQLite Map
  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as String,
      merchant: map['merchant'] as String,
      amount: (map['amount'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      category: map['category'] as String,
      imagePath: map['imagePath'] as String?,
    );
  }

  /// Immutable copy with selective field overrides
  ExpenseItem copyWith({
    String? id,
    String? merchant,
    double? amount,
    DateTime? timestamp,
    String? category,
    String? imagePath,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ExpenseItem(id: $id, merchant: $merchant, amount: $amount, '
      'timestamp: $timestamp, category: $category)';
}
