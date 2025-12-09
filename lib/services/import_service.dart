import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:uuid/uuid.dart';
import '../models/import_progress.dart';
import '../models/import_result.dart';
import 'database_service.dart';
import 'storage_service.dart';
import 'zip_service.dart';
import 'asset_service.dart';

/// Service for importing all application data
class ImportService {
  final DatabaseService _db;
  final StorageService _storage;
  final ZipService _zip;
  final AssetService _asset;
// Used for future enhancements
  final Uuid _uuid = const Uuid();

  ImportService(
    this._db,
    this._storage,
    this._zip,
    this._asset,
    );

  /// Import all data with progress tracking
  Stream<ImportProgress> importAllDataWithProgress(
    String archivePath,
    ImportCancellationToken cancellationToken,
    ConflictResolutionCallback onConflictDetected,
  ) async* {
    Directory? extractDir;

    try {
      // Phase 1: Extracting Archive
      yield ImportProgress(
        totalAssets: 0,
        processedAssets: 0,
        totalItems: 0,
        processedItems: 0,
        currentItem: 'Initializing import...',
        phase: ImportPhase.extractingArchive,
      );

      if (cancellationToken.isCancelled) {
        throw ImportCancelledException();
      }

      extractDir = await _extractArchive(archivePath, cancellationToken);

      // Phase 2: Validating Data
      yield ImportProgress(
        totalAssets: 0,
        processedAssets: 0,
        totalItems: 0,
        processedItems: 0,
        currentItem: 'Validating import data...',
        phase: ImportPhase.validatingData,
      );

      if (cancellationToken.isCancelled) {
        throw ImportCancelledException();
      }

      final databaseJson = await _parseAndValidateJson(extractDir);

      // Calculate total items
      final categories = databaseJson['categories'] as List<dynamic>;
      final tags = databaseJson['tags'] as List<dynamic>;
      final assets = databaseJson['assets'] as List<dynamic>;
      final totalItems = categories.length + tags.length + assets.length;
      int processedItems = 0;

      // Phase 3: Importing Categories
      yield ImportProgress(
        totalAssets: assets.length,
        processedAssets: 0,
        totalItems: totalItems,
        processedItems: processedItems,
        currentItem: 'Importing categories...',
        phase: ImportPhase.importingCategories,
      );

      if (cancellationToken.isCancelled) {
        throw ImportCancelledException();
      }

      final categoryIdMap = await _importCategories(categories);
      processedItems += categories.length;

      // Phase 4: Importing Tags
      yield ImportProgress(
        totalAssets: assets.length,
        processedAssets: 0,
        totalItems: totalItems,
        processedItems: processedItems,
        currentItem: 'Importing tags...',
        phase: ImportPhase.importingTags,
      );

      if (cancellationToken.isCancelled) {
        throw ImportCancelledException();
      }

      await _importTags(tags);
      processedItems += tags.length;

      // Phase 5: Importing Assets
      // Track results for statistics (not used in progress tracking but available for extension)

      final Map<String, String> errors = {};

      for (int i = 0; i < assets.length; i++) {
        if (cancellationToken.isCancelled) {
          throw ImportCancelledException();
        }

        final assetData = assets[i] as Map<String, dynamic>;
        final assetTitle = assetData['title'] as String;

        yield ImportProgress(
          totalAssets: assets.length,
          processedAssets: i,
          totalItems: totalItems,
          processedItems: processedItems + i,
          currentItem: assetTitle,
          phase: ImportPhase.importingAssets,
        );

        try {
          await _importAsset(
            assetData,
            categoryIdMap,
            extractDir,
            onConflictDetected,
          );
        } catch (e) {
          errors[assetData['slug'] as String] = e.toString();
        }
      }

      processedItems += assets.length;

      // Phase 6: Finalizing
      yield ImportProgress(
        totalAssets: assets.length,
        processedAssets: assets.length,
        totalItems: totalItems,
        processedItems: processedItems,
        currentItem: 'Finalizing import...',
        phase: ImportPhase.finalizing,
      );

      if (cancellationToken.isCancelled) {
        throw ImportCancelledException();
      }

      // Rebuild FTS index
      await _rebuildFtsIndex();

      // Cleanup temp directory
      await _cleanupTemp(extractDir);

      // Complete
      yield ImportProgress(
        totalAssets: assets.length,
        processedAssets: assets.length,
        totalItems: totalItems,
        processedItems: totalItems,
        currentItem: 'Import completed',
        phase: ImportPhase.completed,
      );

    } catch (e) {
      // Cleanup on error
      if (extractDir != null) {
        await _cleanupTemp(extractDir);
      }
      rethrow;
    }
  }

  /// Extract archive to temp directory
  Future<Directory> _extractArchive(
    String archivePath,
    ImportCancellationToken cancellationToken,
  ) async {
    final archiveFile = File(archivePath);
    if (!archiveFile.existsSync()) {
      throw ImportException('Archive file not found');
    }

    // Validate ZIP file
    final isValid = await _zip.validateZipFile(archiveFile);
    if (!isValid) {
      throw ImportException('Invalid or corrupted archive file');
    }

    // Create temp extraction directory
    final tempDir = Directory(
      path_pkg.join(
        _storage.tempDirectory.path,
        'import_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );

    if (!tempDir.existsSync()) {
      await tempDir.create(recursive: true);
    }

    // Extract ZIP
    try {
      final bytes = await archiveFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive.files) {
        if (cancellationToken.isCancelled) {
          throw ImportCancelledException();
        }

        if (file.isFile) {
          final filePath = path_pkg.join(tempDir.path, file.name);
          final outputFile = File(filePath);
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
        }
      }

      return tempDir;
    } catch (e) {
      // Cleanup temp directory on error
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }

      if (e is ImportCancelledException) {
        rethrow;
      }

      throw ImportException('Failed to extract archive', e);
    }
  }

  /// Parse and validate database.json
  Future<Map<String, dynamic>> _parseAndValidateJson(Directory extractDir) async {
    final jsonFile = File(path_pkg.join(extractDir.path, 'database.json'));

    if (!jsonFile.existsSync()) {
      throw ImportException('database.json not found in archive');
    }

    try {
      final jsonContent = await jsonFile.readAsString();
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      // Validate required fields
      if (!data.containsKey('metadata')) {
        throw ImportException('Invalid database.json: missing metadata');
      }
      if (!data.containsKey('categories')) {
        throw ImportException('Invalid database.json: missing categories');
      }
      if (!data.containsKey('tags')) {
        throw ImportException('Invalid database.json: missing tags');
      }
      if (!data.containsKey('assets')) {
        throw ImportException('Invalid database.json: missing assets');
      }

      return data;
    } catch (e) {
      if (e is ImportException) {
        rethrow;
      }
      throw ImportException('Failed to parse database.json', e);
    }
  }

  /// Import categories with merge logic
  Future<Map<String, String>> _importCategories(
    List<dynamic> categoriesJson,
  ) async {
    final Map<String, String> oldIdToNewIdMap = {};

    if (categoriesJson.isEmpty) {
      return oldIdToNewIdMap;
    }

    // Sort by parent_id (nulls first) to ensure parent categories are created first
    final sortedCategories = List<Map<String, dynamic>>.from(categoriesJson);
    sortedCategories.sort((a, b) {
      if (a['parentId'] == null && b['parentId'] != null) return -1;
      if (a['parentId'] != null && b['parentId'] == null) return 1;
      return 0;
    });

    await _db.transaction((txn) async {
      for (final categoryData in sortedCategories) {
        final slug = categoryData['slug'] as String;
        final oldId = categoryData['id'] as String;

        // Check if category with this slug already exists
        final existing = await txn.query(
          'categories',
          where: 'slug = ?',
          whereArgs: [slug],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          // Use existing category ID (merge strategy)
          final existingId = existing.first['id'] as String;
          oldIdToNewIdMap[oldId] = existingId;
        } else {
          // Create new category with new ID
          final newId = _uuid.v4();

          // Remap parent_id if it exists
          final oldParentId = categoryData['parentId'] as String?;
          final newParentId = oldParentId != null ? oldIdToNewIdMap[oldParentId] : null;

          await txn.insert('categories', {
            'id': newId,
            'name': categoryData['name'],
            'slug': slug,
            'description': categoryData['description'] ?? '',
            'parent_id': newParentId,
            'display_order': categoryData['displayOrder'] ?? 0,
            'asset_count': 0, // Will be updated as assets are imported
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });

          oldIdToNewIdMap[oldId] = newId;
        }
      }
    });

    return oldIdToNewIdMap;
  }

  /// Import tags with deduplication
  Future<void> _importTags(List<dynamic> tagsJson) async {
    if (tagsJson.isEmpty) {
      return;
    }

    await _db.transaction((txn) async {
      for (final tagData in tagsJson) {
        final tagId = _uuid.v4();

        // INSERT OR IGNORE - if tag with this slug exists, it will be ignored
        await txn.rawInsert('''
          INSERT OR IGNORE INTO tags (id, name, slug, created_at)
          VALUES (?, ?, ?, ?)
        ''', [
          tagId,
          tagData['name'],
          tagData['slug'],
          DateTime.now().millisecondsSinceEpoch,
        ]);
      }
    });
  }

  /// Import single asset with conflict detection
  Future<ImportAssetResult> _importAsset(
    Map<String, dynamic> assetJson,
    Map<String, String> categoryIdMap,
    Directory extractDir,
    ConflictResolutionCallback onConflictDetected,
  ) async {
    final slug = assetJson['slug'] as String;
    final title = assetJson['title'] as String;

    // Check for slug conflict
    final existingAsset = await _getExistingAssetBySlug(slug);

    if (existingAsset != null) {
      // Ask user for resolution
      final resolution = await onConflictDetected(
        slug,
        title,
        existingAsset,
        assetJson,
      );

      switch (resolution.action) {
        case ConflictResolutionAction.skip:
          return ImportAssetResult(
            success: false,
            assetId: '',
            slug: slug,
            errorMessage: 'Skipped by user',
          );

        case ConflictResolutionAction.overwrite:
          // Delete existing asset first
          final existingId = existingAsset['id'] as String;
          await _asset.deleteAsset(existingId);
          break;

        case ConflictResolutionAction.rename:
          // Use new slug provided by user
          if (resolution.newSlug == null || resolution.newSlug!.isEmpty) {
            throw ImportException('Rename selected but no new slug provided');
          }
          assetJson['slug'] = resolution.newSlug!;
          break;
      }
    }

    // Generate new asset ID
    final newAssetId = _uuid.v4();

    // Remap category ID
    final oldCategoryId = assetJson['categoryId'] as String;
    final newCategoryId = categoryIdMap[oldCategoryId];

    if (newCategoryId == null) {
      throw ImportException('Category not found for asset: $slug');
    }

    // Get category slug for file path
    final categorySlug = await _getCategorySlug(newCategoryId);
    if (categorySlug == null) {
      throw ImportException('Category slug not found for ID: $newCategoryId');
    }

    // Copy files to temp location first
    final tempAssetFile = await _copyAssetToTemp(assetJson, extractDir, newAssetId);
    File? tempThumbnailFile;

    if (assetJson['thumbnailPath'] != null) {
      try {
        tempThumbnailFile = await _copyThumbnailToTemp(assetJson, extractDir, newAssetId);
      } catch (e) {
        // Thumbnail is optional, continue without it
        if (kDebugMode) {
          print('Warning: Failed to copy thumbnail for $slug: $e');
        }
      }
    }

    try {
      // Import in transaction
      await _db.transaction((txn) async {
        // Insert asset
        await txn.insert('assets', {
          'id': newAssetId,
          'title': assetJson['title'],
          'slug': assetJson['slug'],
          'description': assetJson['description'] ?? '',
          'short_description': assetJson['shortDescription'] ?? '',
          'category_id': newCategoryId,
          'version': assetJson['version'],
          'last_updated': assetJson['lastUpdated'],
          'file_size': assetJson['fileSize'] ?? 0,
          'zip_path': '', // Will be updated after moving file
          'thumbnail_path': null, // Will be updated after moving file
          'is_featured': (assetJson['isFeatured'] as bool? ?? false) ? 1 : 0,
          'downloads_count': assetJson['downloadsCount'] ?? 0,
          'demo_url': assetJson['demoUrl'],
          'created_at': assetJson['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
          'updated_at': assetJson['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
        });

        // Insert ZIP metadata if present
        if (assetJson['zipMetadata'] != null) {
          final zipMeta = assetJson['zipMetadata'] as Map<String, dynamic>;
          await txn.insert('zip_metadata', {
            'id': _uuid.v4(),
            'asset_id': newAssetId,
            'entry_count': zipMeta['entryCount'] ?? 0,
            'compression_ratio': zipMeta['compressionRatio'],
            'has_directory_structure': (zipMeta['hasDirectoryStructure'] as bool? ?? true) ? 1 : 0,
            'original_name': zipMeta['originalName'],
          });
        }

        // Insert tags (with deduplication)
        final tags = assetJson['tags'] as List<dynamic>?;
        if (tags != null && tags.isNotEmpty) {
          for (final tagName in tags) {
            final tagSlug = _generateSlug(tagName as String);

            // Get tag ID by slug
            final tagResult = await txn.query(
              'tags',
              where: 'slug = ?',
              whereArgs: [tagSlug],
            );

            if (tagResult.isNotEmpty) {
              final tagId = tagResult.first['id'] as String;

              // Link asset to tag
              try {
                await txn.insert('asset_tags', {
                  'asset_id': newAssetId,
                  'tag_id': tagId,
                });
              } catch (e) {
                // Ignore duplicate tag assignments
                if (kDebugMode) {
                  print('Warning: Failed to link tag $tagName to asset $slug: $e');
                }
              }
            }
          }
        }

        // Update category asset count
        await txn.rawUpdate(
          'UPDATE categories SET asset_count = asset_count + 1 WHERE id = ?',
          [newCategoryId],
        );
      });

      // Transaction successful, move files to permanent storage
      final zipPath = await _storage.saveAsset(tempAssetFile, newAssetId, categorySlug);

      String? thumbnailPath;
      if (tempThumbnailFile != null) {
        thumbnailPath = await _storage.saveThumbnail(tempThumbnailFile, newAssetId, isMain: true);
      }

      // Update asset paths in database
      await _db.update(
        'assets',
        {
          'zip_path': zipPath,
          'thumbnail_path': thumbnailPath,
        },
        where: 'id = ?',
        whereArgs: [newAssetId],
      );

      // Cleanup temp files
      if (tempAssetFile.existsSync()) {
        await tempAssetFile.delete();
      }
      if (tempThumbnailFile != null && tempThumbnailFile.existsSync()) {
        await tempThumbnailFile.delete();
      }

      return ImportAssetResult(
        success: true,
        assetId: newAssetId,
        slug: assetJson['slug'] as String,
      );

    } catch (e) {
      // Cleanup temp files on error
      if (tempAssetFile.existsSync()) {
        await tempAssetFile.delete();
      }
      if (tempThumbnailFile != null && tempThumbnailFile.existsSync()) {
        await tempThumbnailFile.delete();
      }

      throw ImportException('Failed to import asset: $slug', e);
    }
  }

  /// Check if asset with slug exists
  Future<Map<String, dynamic>?> _getExistingAssetBySlug(String slug) async {
    final results = await _db.query(
      'assets',
      where: 'slug = ?',
      whereArgs: [slug],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first;
  }

  /// Get category slug by ID
  Future<String?> _getCategorySlug(String categoryId) async {
    final results = await _db.query(
      'categories',
      columns: ['slug'],
      where: 'id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return results.first['slug'] as String;
  }

  /// Copy asset ZIP to temp location
  Future<File> _copyAssetToTemp(
    Map<String, dynamic> assetJson,
    Directory extractDir,
    String newAssetId,
  ) async {
    final relativePath = assetJson['zipPath'] as String;
    final sourceFile = File(path_pkg.join(extractDir.path, relativePath));

    if (!sourceFile.existsSync()) {
      throw ImportException('Asset ZIP file not found: $relativePath');
    }

    // Copy to temp location with new ID
    final tempPath = path_pkg.join(_storage.tempDirectory.path, '$newAssetId.zip');
    final tempFile = await sourceFile.copy(tempPath);

    return tempFile;
  }

  /// Copy thumbnail to temp location
  Future<File> _copyThumbnailToTemp(
    Map<String, dynamic> assetJson,
    Directory extractDir,
    String newAssetId,
  ) async {
    final relativePath = assetJson['thumbnailPath'] as String?;
    if (relativePath == null) {
      throw ImportException('Thumbnail path is null');
    }

    final sourceFile = File(path_pkg.join(extractDir.path, relativePath));

    if (!sourceFile.existsSync()) {
      throw ImportException('Thumbnail file not found: $relativePath');
    }

    // Copy to temp location with new ID
    final tempPath = path_pkg.join(_storage.tempDirectory.path, '$newAssetId-thumb.jpg');
    final tempFile = await sourceFile.copy(tempPath);

    return tempFile;
  }

  /// Generate slug from text
  String _generateSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  /// Rebuild FTS index
  Future<void> _rebuildFtsIndex() async {
    try {
      await _db.database.then((db) async {
        await db.rawInsert('INSERT INTO assets_fts(assets_fts) VALUES("rebuild")');
      });
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to rebuild FTS index: $e');
      }
      // Non-critical, continue
    }
  }

  /// Cleanup temp directory
  Future<void> _cleanupTemp(Directory tempDir) async {
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to cleanup temp directory: $e');
      }
      // Non-critical, ignore
    }
  }
}
