import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../core/database/migrations/migration_v1.dart';

/// Service for managing SQLite database operations
class DatabaseService {
  static Database? _database;
  static const int _currentVersion = 1;

  /// Get the database instance, initializing if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    // Get the documents directory for database storage
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String dbPath = path_pkg.join(appDocDir.path, 'GvStorage', 'database', 'gvstorage.db');

    // Ensure the directory exists
    final dbDir = Directory(path_pkg.dirname(dbPath));
    if (!dbDir.existsSync()) {
      dbDir.createSync(recursive: true);
    }

    // Open the database
    return await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _currentVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      ),
    );
  }

  /// Called when database is created for the first time
  Future<void> _onCreate(Database db, int version) async {
    if (kDebugMode) {
      print('Creating database v$version...');
    }
    await _runMigrations(db, 0, version);
  }

  /// Called when database needs to be upgraded
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('Upgrading database from v$oldVersion to v$newVersion...');
    }
    await _runMigrations(db, oldVersion, newVersion);
  }

  /// Called when database is opened
  Future<void> _onOpen(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Run migrations from oldVersion to newVersion
  Future<void> _runMigrations(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      if (kDebugMode) {
        print('Running migration for version $version...');
      }
      switch (version) {
        case 1:
          await migrationV1(db);
          break;
        // Future migrations will go here
        default:
          throw Exception('Unknown migration version: $version');
      }
    }
    if (kDebugMode) {
      print('Migrations completed.');
    }
  }

  /// Generic query method
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// Generic insert method
  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await database;
    return await db.insert(
      table,
      values,
      nullColumnHack: nullColumnHack,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// Generic update method
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final db = await database;
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// Generic delete method
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// Execute raw SQL query
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Execute raw SQL insert/update/delete
  Future<int> rawInsert(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }

  /// Execute raw SQL update
  Future<int> rawUpdate(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  /// Execute raw SQL delete
  Future<int> rawDelete(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawDelete(sql, arguments);
  }

  /// Execute a transaction
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  /// Close the database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Create a backup of the database
  Future<void> createBackup() async {
    try {
      final db = await database;
      final dbPath = db.path;

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String backupDir = path_pkg.join(appDocDir.path, 'GvStorage', 'backups');

      // Create backup directory if it doesn't exist
      final backupDirectory = Directory(backupDir);
      if (!backupDirectory.existsSync()) {
        backupDirectory.createSync(recursive: true);
      }

      // Create backup filename with current date
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final backupPath = path_pkg.join(backupDir, 'gvstorage_$dateStr.db');

      // Copy database file to backup location
      final dbFile = File(dbPath);
      await dbFile.copy(backupPath);

      if (kDebugMode) {
        print('Database backup created at $backupPath');
      }

      // Clean old backups (keep last 7)
      await _cleanOldBackups(backupDirectory);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating database backup: $e');
      }
    }
  }

  /// Clean old backup files, keeping only the last 7
  Future<void> _cleanOldBackups(Directory backupDir) async {
    try {
      final List<FileSystemEntity> backups = backupDir
          .listSync()
          .where((entity) => entity is File && entity.path.endsWith('.db'))
          .toList();

      // Sort by modification date (newest first)
      backups.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      // Delete backups beyond the 7th
      if (backups.length > 7) {
        for (int i = 7; i < backups.length; i++) {
          await backups[i].delete();
          if (kDebugMode) {
            print('Deleted old backup: ${backups[i].path}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning old backups: $e');
      }
    }
  }
}