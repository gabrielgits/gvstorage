import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path_pkg;
import '../models/export_progress.dart';
import 'database_service.dart';
import 'storage_service.dart';
import 'zip_service.dart';
import 'asset_service.dart';
import 'category_service.dart';

/// Service for exporting all application data
class ExportService {
  final DatabaseService _db;
  final StorageService _storage;
  final AssetService _asset;

  ExportService(
    this._db,
    this._storage,
    ZipService zip, // Not used directly but kept for future use
    this._asset,
    CategoryService category, // Not used directly but kept for future use
  );

  /// Export all data with progress tracking
  Stream<ExportProgress> exportAllDataWithProgress(
    String destinationPath,
    ExportCancellationToken cancellationToken,
  ) async* {
    try {
      // Phase 1: Preparing data
      yield ExportProgress(
        totalAssets: 0,
        processedAssets: 0,
        totalFiles: 0,
        processedFiles: 0,
        currentFile: 'Initializing export...',
        phase: ExportPhase.preparingData,
      );

      // Check if cancelled
      if (cancellationToken.isCancelled) {
        throw ExportCancelledException();
      }

      // Get total asset count
      final totalAssets = await _asset.getTotalAssetCount();

      // Calculate total export size and validate disk space
      yield ExportProgress(
        totalAssets: totalAssets,
        processedAssets: 0,
        totalFiles: 0,
        processedFiles: 0,
        currentFile: 'Calculating export size...',
        phase: ExportPhase.preparingData,
      );

      final totalSize = await _calculateTotalExportSize();
      final hasSpace = await _validateDiskSpace(destinationPath, totalSize);

      if (!hasSpace) {
        throw ExportException(
          'Insufficient disk space. Export requires ${_formatBytes(totalSize)}',
        );
      }

      if (cancellationToken.isCancelled) {
        throw ExportCancelledException();
      }

      // Generate database JSON
      yield ExportProgress(
        totalAssets: totalAssets,
        processedAssets: 0,
        totalFiles: 0,
        processedFiles: 0,
        currentFile: 'Generating database export...',
        phase: ExportPhase.preparingData,
      );

      final databaseJson = await _generateDatabaseJson();

      // Phase 2: Collecting files
      yield ExportProgress(
        totalAssets: totalAssets,
        processedAssets: 0,
        totalFiles: 0,
        processedFiles: 0,
        currentFile: 'Collecting asset files...',
        phase: ExportPhase.collectingFiles,
      );

      if (cancellationToken.isCancelled) {
        throw ExportCancelledException();
      }

      final assetFiles = await _collectAssetFiles();

      yield ExportProgress(
        totalAssets: totalAssets,
        processedAssets: 0,
        totalFiles: 0,
        processedFiles: 0,
        currentFile: 'Collecting thumbnail files...',
        phase: ExportPhase.collectingFiles,
      );

      if (cancellationToken.isCancelled) {
        throw ExportCancelledException();
      }

      final thumbnailFiles = await _collectThumbnailFiles();

      // Phase 3: Creating archive - now we know the actual total files
      final totalFiles = assetFiles.length + thumbnailFiles.length + 2; // +2 for database.json and README.txt

      yield* _createMasterZip(
        databaseJson,
        assetFiles,
        thumbnailFiles,
        destinationPath,
        totalAssets,
        totalFiles,
        cancellationToken,
      );

      // Note: Not recording in export_history table since it's designed for individual asset exports
      // and requires a valid asset_id foreign key

      // Final completion
      yield ExportProgress(
        totalAssets: totalAssets,
        processedAssets: totalAssets,
        totalFiles: totalFiles,
        processedFiles: totalFiles,
        currentFile: 'Export completed successfully',
        phase: ExportPhase.completed,
      );
    } on ExportCancelledException {
      // Clean up partial export
      await _cleanupPartialExport(destinationPath);
      rethrow;
    } catch (e) {
      // Clean up on error
      await _cleanupPartialExport(destinationPath);
      throw ExportException('Export failed: ${e.toString()}', e);
    }
  }

  /// Generate complete database export as JSON
  Future<Map<String, dynamic>> _generateDatabaseJson() async {
    final assets = await _exportAssets();
    final categories = await _exportCategories();
    final tags = await _exportTags();
    final exportHistory = await _exportHistory();
    final appSettings = await _exportSettings();

    final totalSize = await _calculateTotalExportSize();

    return {
      'metadata': {
        'exportedAt': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0.0',
        'totalAssets': assets.length,
        'totalCategories': categories.length,
        'totalTags': tags.length,
        'totalSizeBytes': totalSize,
      },
      'categories': categories,
      'tags': tags,
      'assets': assets,
      'exportHistory': exportHistory,
      'appSettings': appSettings,
    };
  }

  /// Export all assets with full metadata
  Future<List<Map<String, dynamic>>> _exportAssets() async {
    // Get all assets with category information
    final results = await _db.rawQuery('''
      SELECT
        assets.*,
        categories.name as category,
        categories.slug as category_slug
      FROM assets
      LEFT JOIN categories ON assets.category_id = categories.id
      ORDER BY assets.created_at DESC
    ''');

    if (results.isEmpty) return [];

    // Batch load all tags
    final assetIds = results.map((a) => a['id'] as String).toList();
    final tagsByAsset = await _asset.loadAllAssetTags(assetIds);

    // Load ZIP metadata for each asset
    final assetsWithMetadata = <Map<String, dynamic>>[];

    for (final assetData in results) {
      final assetId = assetData['id'] as String;
      final tags = tagsByAsset[assetId] ?? [];

      // Load ZIP metadata
      Map<String, dynamic>? zipMetadata;
      try {
        final metadata = await _asset.loadZipMetadata(assetId);
        if (metadata != null) {
          zipMetadata = {
            'id': metadata.id,
            'entryCount': metadata.entryCount,
            'compressionRatio': metadata.compressionRatio,
            'hasDirectoryStructure': metadata.hasDirectoryStructure,
            'originalName': metadata.originalName,
          };
        }
      } catch (e) {
        // Ignore metadata loading errors
        zipMetadata = null;
      }

      // Parse features from JSON
      List<Map<String, dynamic>> features = [];
      final featuresJson = assetData['features'];
      if (featuresJson != null && featuresJson is String && featuresJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(featuresJson) as List<dynamic>;
          features = decoded.map((f) => f as Map<String, dynamic>).toList();
        } catch (e) {
          // Ignore feature parsing errors
        }
      }

      // Gallery images - not stored in database currently
      List<String> galleryImages = [];

      assetsWithMetadata.add({
        'id': assetId,
        'title': assetData['title'],
        'slug': assetData['slug'],
        'description': assetData['description'] ?? '',
        'shortDescription': assetData['short_description'] ?? '',
        'categoryId': assetData['category_id'],
        'categoryName': assetData['category'] ?? '',
        'categorySlug': assetData['category_slug'] ?? '',
        'version': assetData['version'],
        'lastUpdated': assetData['last_updated'],
        'createdAt': assetData['created_at'],
        'updatedAt': assetData['updated_at'],
        'fileSize': assetData['file_size'],
        'zipPath': assetData['zip_path'],
        'thumbnailPath': assetData['thumbnail_path'],
        'galleryImages': galleryImages,
        'isFeatured': assetData['is_featured'] == 1,
        'downloadsCount': assetData['downloads_count'] ?? 0,
        'demoUrl': assetData['demo_url'],
        'tags': tags,
        'features': features,
        'zipMetadata': zipMetadata,
      });
    }

    return assetsWithMetadata;
  }

  /// Export all categories
  Future<List<Map<String, dynamic>>> _exportCategories() async {
    final results = await _db.query('categories', orderBy: 'display_order ASC');

    return results.map((cat) {
      return {
        'id': cat['id'],
        'name': cat['name'],
        'slug': cat['slug'],
        'description': cat['description'],
        'parentId': cat['parent_id'],
        'displayOrder': cat['display_order'],
        'createdAt': cat['created_at'],
      };
    }).toList();
  }

  /// Export all tags
  Future<List<Map<String, dynamic>>> _exportTags() async {
    final results = await _db.query('tags', orderBy: 'name ASC');

    return results.map((tag) {
      return {
        'id': tag['id'],
        'name': tag['name'],
        'slug': tag['slug'],
        'createdAt': tag['created_at'],
      };
    }).toList();
  }

  /// Export export history
  Future<List<Map<String, dynamic>>> _exportHistory() async {
    final results = await _db.query('export_history', orderBy: 'exported_at DESC');

    return results.map((record) {
      return {
        'id': record['id'],
        'assetId': record['asset_id'],
        'exportPath': record['export_path'],
        'exportedAt': record['exported_at'],
        'exportType': record['export_type'],
      };
    }).toList();
  }

  /// Export app settings
  Future<List<Map<String, dynamic>>> _exportSettings() async {
    final results = await _db.query('app_settings');

    return results.map((setting) {
      return {
        'key': setting['key'],
        'value': setting['value'],
        'updatedAt': setting['updated_at'],
      };
    }).toList();
  }

  /// Collect all asset ZIP files
  Future<List<File>> _collectAssetFiles() async {
    final results = await _db.query('assets', columns: ['zip_path']);
    final files = <File>[];

    for (final row in results) {
      final zipPath = row['zip_path'] as String?;
      if (zipPath == null || zipPath.isEmpty) continue;

      try {
        final file = await _storage.getAssetFile(zipPath);
        if (await file.exists()) {
          files.add(file);
        }
      } catch (e) {
        // Skip files that can't be accessed
        continue;
      }
    }

    return files;
  }

  /// Collect all thumbnail files
  Future<List<File>> _collectThumbnailFiles() async {
    final results = await _db.query('assets', columns: ['thumbnail_path']);
    final files = <File>[];

    for (final row in results) {
      // Main thumbnail
      final thumbnailPath = row['thumbnail_path'] as String?;
      if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
        try {
          final file = File(_storage.getAbsolutePath(thumbnailPath));
          if (await file.exists()) {
            files.add(file);
          }
        } catch (e) {
          // Skip files that can't be accessed
        }
      }
    }

    return files;
  }

  /// Create master ZIP archive with progress tracking
  Stream<ExportProgress> _createMasterZip(
    Map<String, dynamic> databaseJson,
    List<File> assetFiles,
    List<File> thumbnailFiles,
    String destinationPath,
    int totalAssets,
    int totalFiles,
    ExportCancellationToken cancellationToken,
  ) async* {
    final archive = Archive();
    int processedFiles = 0;

    // Add database.json
    yield ExportProgress(
      totalAssets: totalAssets,
      processedAssets: 0,
      totalFiles: totalFiles,
      processedFiles: processedFiles,
      currentFile: 'database.json',
      phase: ExportPhase.creatingArchive,
    );

    final jsonString = const JsonEncoder.withIndent('  ').convert(databaseJson);
    final jsonBytes = utf8.encode(jsonString);
    archive.addFile(ArchiveFile('database.json', jsonBytes.length, jsonBytes));
    processedFiles++;

    if (cancellationToken.isCancelled) {
      throw ExportCancelledException();
    }

    // Add README.txt
    final readmeContent = _generateReadmeContent(databaseJson);
    final readmeBytes = utf8.encode(readmeContent);
    archive.addFile(ArchiveFile('README.txt', readmeBytes.length, readmeBytes));
    processedFiles++;

    // Add asset ZIP files
    for (int i = 0; i < assetFiles.length; i++) {
      if (cancellationToken.isCancelled) {
        throw ExportCancelledException();
      }

      final file = assetFiles[i];
      final relativePath = await _getRelativePathForAsset(file);
      final bytes = await file.readAsBytes();

      archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      processedFiles++;

      // Update progress
      yield ExportProgress(
        totalAssets: totalAssets,
        processedAssets: i + 1,
        totalFiles: totalFiles,
        processedFiles: processedFiles,
        currentFile: path_pkg.basename(file.path),
        phase: ExportPhase.creatingArchive,
      );
    }

    // Add thumbnail files
    for (int i = 0; i < thumbnailFiles.length; i++) {
      if (cancellationToken.isCancelled) {
        throw ExportCancelledException();
      }

      final file = thumbnailFiles[i];
      final relativePath = await _getRelativePathForThumbnail(file);
      final bytes = await file.readAsBytes();

      archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      processedFiles++;

      // Update progress
      yield ExportProgress(
        totalAssets: totalAssets,
        processedAssets: totalAssets,
        totalFiles: totalFiles,
        processedFiles: processedFiles,
        currentFile: path_pkg.basename(file.path),
        phase: ExportPhase.creatingArchive,
      );
    }

    // Encode and write archive
    yield ExportProgress(
      totalAssets: totalAssets,
      processedAssets: totalAssets,
      totalFiles: totalFiles,
      processedFiles: processedFiles,
      currentFile: 'Finalizing archive...',
      phase: ExportPhase.creatingArchive,
    );

    final encoder = ZipEncoder();
    final outputFile = File(destinationPath);
    final outputStream = outputFile.openWrite();

    try {
      final zipData = encoder.encode(archive);
      if (zipData != null) {
        outputStream.add(zipData);
      }
      await outputStream.flush();
    } finally {
      await outputStream.close();
    }
  }

  /// Get relative path for asset file in export archive
  Future<String> _getRelativePathForAsset(File file) async {
    // Extract relative path from storage structure
    final storagePath = _storage.storageRoot.path;
    final filePath = file.path;

    if (filePath.startsWith(storagePath)) {
      return filePath.substring(storagePath.length + 1);
    }

    // Fallback: use just the filename
    return 'assets/${path_pkg.basename(file.path)}';
  }

  /// Get relative path for thumbnail file in export archive
  Future<String> _getRelativePathForThumbnail(File file) async {
    // Extract relative path from storage structure
    final storagePath = _storage.storageRoot.path;
    final filePath = file.path;

    if (filePath.startsWith(storagePath)) {
      return filePath.substring(storagePath.length + 1);
    }

    // Fallback: use just the filename
    return 'thumbnails/${path_pkg.basename(file.path)}';
  }

  /// Calculate total size of export
  Future<int> _calculateTotalExportSize() async {
    int totalSize = 0;

    // Asset files
    final assetResults = await _db.query('assets', columns: ['file_size']);
    for (final row in assetResults) {
      final fileSize = row['file_size'] as int? ?? 0;
      totalSize += fileSize;
    }

    // Thumbnail files (estimate)
    final thumbnailCount = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM assets WHERE thumbnail_path IS NOT NULL'
    );
    final count = thumbnailCount.first['count'] as int;
    totalSize += count * 500000; // Estimate 500KB per thumbnail

    // Database JSON (estimate)
    totalSize += 10485760; // Estimate 10MB for database JSON

    return totalSize;
  }

  /// Validate available disk space
  Future<bool> _validateDiskSpace(String destinationPath, int requiredBytes) async {
    try {
      final directory = Directory(path_pkg.dirname(destinationPath));

      // Add 10% buffer for safety
      final requiredWithBuffer = (requiredBytes * 1.1).toInt();

      // Get available space (platform-specific)
      if (Platform.isLinux || Platform.isMacOS) {
        final result = await Process.run('df', ['-k', directory.path]);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          if (lines.length > 1) {
            final parts = lines[1].split(RegExp(r'\s+'));
            if (parts.length > 3) {
              final availableKB = int.tryParse(parts[3]) ?? 0;
              final availableBytes = availableKB * 1024;
              return availableBytes >= requiredWithBuffer;
            }
          }
        }
      } else if (Platform.isWindows) {
        // For Windows, use PowerShell
        final drive = destinationPath.substring(0, 2); // E.g., "C:"
        final result = await Process.run(
          'powershell',
          ['-Command', '(Get-PSDrive ${drive[0]}).Free'],
        );
        if (result.exitCode == 0) {
          final availableBytes = int.tryParse(result.stdout.toString().trim()) ?? 0;
          return availableBytes >= requiredWithBuffer;
        }
      }

      // If we can't determine space, assume it's OK
      return true;
    } catch (e) {
      // If disk space check fails, proceed anyway
      return true;
    }
  }

  // Note: _recordExport method removed because export_history table is designed
  // for individual asset exports and requires a valid asset_id foreign key.
  // "Export All" operations are not tracked in this table.

  /// Clean up partial export on cancellation or error
  Future<void> _cleanupPartialExport(String destinationPath) async {
    try {
      final file = File(destinationPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Generate README content for export
  String _generateReadmeContent(Map<String, dynamic> databaseJson) {
    final metadata = databaseJson['metadata'] as Map<String, dynamic>;
    final exportDate = DateTime.fromMillisecondsSinceEpoch(metadata['exportedAt'] as int);
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    return '''
GvStorage Data Export
=====================

Export Date: ${formatter.format(exportDate)}
Version: ${metadata['version']}

Contents:
---------
- Total Assets: ${metadata['totalAssets']}
- Total Categories: ${metadata['totalCategories']}
- Total Tags: ${metadata['totalTags']}
- Total Size: ${_formatBytes(metadata['totalSizeBytes'] as int)}

Structure:
----------
database.json       - Complete database export with all metadata
assets/             - All asset ZIP files organized by category
thumbnails/         - All thumbnail and gallery images
README.txt          - This file

Import Instructions:
--------------------
To restore this export:
1. Install GvStorage on the target system
2. Use the "Import All Data" feature (if available)
3. Select this export archive
4. The application will restore all assets, categories, tags, and settings

Notes:
------
- All file paths in database.json are relative to the storage root
- Asset ZIPs are organized by category slug
- Thumbnails are organized by asset ID
- Export history and app settings are included for complete restoration

For support, visit: https://github.com/yourusername/gvstorage
''';
  }

  /// Format bytes as human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
