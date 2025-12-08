import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_service.dart';
import 'storage_service.dart';
import 'zip_service.dart';
import 'asset_service.dart';
import 'category_service.dart';
import 'search_service.dart';
import 'export_service.dart';

/// Service locator for dependency injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late DatabaseService database;
  late StorageService storage;
  late ZipService zip;
  late AssetService asset;
  late CategoryService category;
  late SearchService search;
  late ExportService export;

  bool _initialized = false;

  /// Initialize all services
  Future<void> initialize() async {
    if (_initialized) {
      if (kDebugMode) {
        print('Services already initialized');
      }
      return;
    }

    if (kDebugMode) {
      print('Initializing services...');
    }

    // Initialize SQLite FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Initialize database service
    database = DatabaseService();
    await database.database; // Trigger initialization

    // Initialize storage service
    storage = StorageService();
    await storage.initialize();

    // Initialize ZIP service
    zip = ZipService();

    // Initialize business logic services
    asset = AssetService(database, storage, zip);
    category = CategoryService(database);
    search = SearchService(database);
    export = ExportService(database, storage, zip, asset, category);

    _initialized = true;
    if (kDebugMode) {
      print('Services initialized');
    }
  }

  /// Dispose of all services
  Future<void> dispose() async {
    if (!_initialized) return;

    if (kDebugMode) {
      print('Disposing services...');
    }

    // Close database connection
    await database.close();

    // Clean up temp files
    await storage.cleanupTemp();

    _initialized = false;
    if (kDebugMode) {
      print('Services disposed');
    }
  }

  /// Create a database backup
  Future<void> createBackup() async {
    if (!_initialized) {
      throw Exception('Services not initialized');
    }

    await database.createBackup();
  }

  /// Check if services are initialized
  bool get isInitialized => _initialized;
}

/// Global accessor for services
final services = ServiceLocator();
