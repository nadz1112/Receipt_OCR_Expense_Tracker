import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense_item.dart';

/// SQLite database service for the VKU Expense Tracker.
///
/// Implements the Singleton pattern to ensure a single database connection
/// throughout the app lifecycle.
///
/// Database: `expenses.db`
/// Table: `expenses`
class DatabaseHelper {
  DatabaseHelper._internal();

  /// Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  /// Public accessor for the singleton
  static DatabaseHelper get instance => _instance;

  /// Cached database reference
  Database? _database;

  /// Database file name
  static const String _dbName = 'expenses.db';

  /// Database version — increment on schema changes
  static const int _dbVersion = 1;

  /// Table name
  static const String _tableName = 'expenses';

  // ─── Column Names ────────────────────────────────────────────────────────────
  static const String colId = 'id';
  static const String colMerchant = 'merchant';
  static const String colAmount = 'amount';
  static const String colTimestamp = 'timestamp';
  static const String colCategory = 'category';
  static const String colImagePath = 'imagePath';

  // ─── Database Initialization ─────────────────────────────────────────────────

  /// Lazily initializes and returns the database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Opens (or creates) the SQLite database file and runs migrations
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the expenses table schema on first launch
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $colId        TEXT PRIMARY KEY,
        $colMerchant  TEXT NOT NULL,
        $colAmount    REAL NOT NULL,
        $colTimestamp TEXT NOT NULL,
        $colCategory  TEXT NOT NULL,
        $colImagePath TEXT
      )
    ''');
  }

  /// Handles schema migrations for future version bumps
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Placeholder for future migrations
    // if (oldVersion < 2) { ... }
  }

  // ─── CRUD Operations ─────────────────────────────────────────────────────────

  /// Insert a new [ExpenseItem] into the database.
  /// Returns the rowid of the inserted record.
  Future<int> insertExpense(ExpenseItem expense) async {
    final db = await database;
    return db.insert(
      _tableName,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve all expenses ordered by timestamp descending (most recent first).
  Future<List<ExpenseItem>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: '$colTimestamp DESC',
    );
    return maps.map(ExpenseItem.fromMap).toList();
  }

  /// Retrieve a single expense by its [id].
  /// Returns null if not found.
  Future<ExpenseItem?> getExpenseById(String id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: '$colId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ExpenseItem.fromMap(maps.first);
  }

  /// Update an existing [ExpenseItem] in the database.
  /// Returns the number of rows affected.
  Future<int> updateExpense(ExpenseItem expense) async {
    final db = await database;
    return db.update(
      _tableName,
      expense.toMap(),
      where: '$colId = ?',
      whereArgs: [expense.id],
    );
  }

  /// Delete an expense by [id].
  /// Returns the number of rows deleted.
  Future<int> deleteExpense(String id) async {
    final db = await database;
    return db.delete(
      _tableName,
      where: '$colId = ?',
      whereArgs: [id],
    );
  }

  /// Retrieve all expenses within a date range (inclusive).
  Future<List<ExpenseItem>> getExpensesByDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: '$colTimestamp BETWEEN ? AND ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: '$colTimestamp DESC',
    );
    return maps.map(ExpenseItem.fromMap).toList();
  }

  /// Retrieve all expenses for a specific [category].
  Future<List<ExpenseItem>> getExpensesByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: '$colCategory = ?',
      whereArgs: [category],
      orderBy: '$colTimestamp DESC',
    );
    return maps.map(ExpenseItem.fromMap).toList();
  }

  /// Get total amount spent across all expenses
  Future<double> getTotalAmount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM($colAmount) as total FROM $_tableName',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Close the database connection (call on app dispose if needed)
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
