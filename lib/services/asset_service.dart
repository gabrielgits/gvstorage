import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/asset.dart';
import '../models/export_record.dart';
import '../models/zip_metadata.dart';
import 'database_service.dart';
import 'storage_service.dart';
import 'zip_service.dart';

/// Service for high-level asset management
class AssetService {
  final DatabaseService _db;
  final StorageService _storage;
  final ZipService _zip;
  final _uuid = const Uuid();

  AssetService(this._db, this._storage, this._zip);

  /// Upload a new asset
  Future<Asset> uploadAsset({
    required File zipFile,
    required String title,
    required String categoryId,
    String? description,
    String? shortDescription,
    String? version,
    DateTime? lastUpdated,
    String? demoUrl,
    List<String> tags = const [],
    List<AssetFeature> features = const [],
    File? thumbnail,
    List<File> galleryImages = const [],
    bool isFeatured = false,
  }) async {
    // Validate ZIP file
    final isValid = await _zip.validateZipFile(zipFile);
    if (!isValid) {
      throw Exception('Invalid or corrupted ZIP file');
    }

    // Generate unique ID and slug
    final assetId = _uuid.v4();
    final slug = _generateSlug(title);

    // Get category for storage path
    final categoryResults = await _db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );

    if (categoryResults.isEmpty) {
      throw Exception('Category not found');
    }

    final categorySlug = categoryResults.first['slug'] as String;
    final categoryName = categoryResults.first['name'] as String;

    // Store ZIP file
    final zipPath = await _storage.saveAsset(zipFile, assetId, categorySlug);

    // Extract original filename from the uploaded file
    final originalFileName = zipFile.path.split('/').last;

    // Extract ZIP metadata
    final storedZip = await _storage.getAssetFile(zipPath);
    final zipMetadata = await _zip.extractMetadata(storedZip, assetId, originalName: originalFileName);

    // Handle thumbnails
    String? thumbnailPath;
    final List<String> galleryPaths = [];

    if (thumbnail != null) {
      thumbnailPath = await _storage.saveThumbnail(thumbnail, assetId, isMain: true);
    } else {
      // Try to auto-extract thumbnail from ZIP
      final autoThumbnailBytes = await _zip.extractThumbnailImage(storedZip);
      if (autoThumbnailBytes != null) {
        final tempFile = File('${_storage.tempDirectory.path}/$assetId.jpg');
        await tempFile.writeAsBytes(autoThumbnailBytes);
        thumbnailPath = await _storage.saveThumbnail(tempFile, assetId, isMain: true);
        await tempFile.delete(); // Clean up temp file
      }
    }

    // Save gallery images
    if (galleryImages.isNotEmpty) {
      final paths = await _storage.saveGalleryImages(galleryImages, assetId);
      galleryPaths.addAll(paths);
    }

    final now = DateTime.now();
    final fileSize = zipFile.lengthSync();

    // Start database transaction
    await _db.transaction((txn) async {
      // Insert asset
      await txn.insert('assets', {
        'id': assetId,
        'title': title,
        'slug': slug,
        'description': description ?? '',
        'short_description': shortDescription ?? '',
        'category_id': categoryId,
        'version': version,
        'created_at': now.millisecondsSinceEpoch,
        'last_updated': lastUpdated?.millisecondsSinceEpoch,
        'file_size': fileSize,
        'zip_path': zipPath,
        'thumbnail_path': thumbnailPath,
        'is_featured': isFeatured ? 1 : 0,
        'downloads_count': 0,
        'demo_url': demoUrl,
        'updated_at': now.millisecondsSinceEpoch,
      });

      // Insert ZIP metadata
      await txn.insert('zip_metadata', zipMetadata.toJson());

      // Insert tags
      for (final tagName in tags) {
        final tagSlug = _generateSlug(tagName);
        final tagId = _uuid.v4();

        // Insert or ignore tag (might already exist)
        await txn.rawInsert('''
          INSERT OR IGNORE INTO tags (id, name, slug, created_at)
          VALUES (?, ?, ?, ?)
        ''', [tagId, tagName, tagSlug, now.millisecondsSinceEpoch]);

        // Get actual tag ID (in case it already existed)
        final tagResult = await txn.query(
          'tags',
          where: 'slug = ?',
          whereArgs: [tagSlug],
          limit: 1,
        );

        final actualTagId = tagResult.first['id'] as String;

        // Link asset to tag
        await txn.insert('asset_tags', {
          'asset_id': assetId,
          'tag_id': actualTagId,
        });
      }

      // Update category asset count
      await txn.rawUpdate('''
        UPDATE categories
        SET asset_count = asset_count + 1
        WHERE id = ?
      ''', [categoryId]);
    });

    // Return the created asset
    return Asset(
      id: assetId,
      title: title,
      slug: slug,
      description: description ?? '',
      shortDescription: shortDescription ?? '',
      imageUrl: thumbnailPath ?? '',
      galleryImages: galleryPaths,
      category: categoryName,
      categorySlug: categorySlug,
      version: version,
      lastUpdated: lastUpdated,
      tags: tags,
      features: features,
      isFeatured: isFeatured,
      createdAt: now,
      fileSize: fileSize,
      zipPath: zipPath,
      thumbnailPath: thumbnailPath,
      downloadsCount: 0,
      zipMetadata: zipMetadata,
      demoUrl: demoUrl,
      updatedAt: now,
    );
  }

  /// Get assets with optional filters
  Future<List<Asset>> getAssets({
    String? categoryId,
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    String sql = '''
      SELECT assets.*,
             categories.name as category,
             categories.slug as category_slug
      FROM assets
      LEFT JOIN categories ON assets.category_id = categories.id
    ''';

    final whereArgs = <dynamic>[];

    if (categoryId != null) {
      sql += ' WHERE assets.category_id = ?';
      whereArgs.add(categoryId);
    }

    sql += ' ORDER BY ${orderBy ?? 'assets.created_at DESC'}';

    if (limit != null) {
      sql += ' LIMIT $limit';
    }

    if (offset != null) {
      sql += ' OFFSET $offset';
    }

    final results = await _db.rawQuery(sql, whereArgs);

    final assets = <Asset>[];
    for (final result in results) {
      final asset = await _loadAssetWithTags(result);
      assets.add(asset);
    }

    return assets;
  }

  /// Get a single asset by ID
  Future<Asset?> getAssetById(String id) async {
    final results = await _db.rawQuery('''
      SELECT assets.*,
             categories.name as category,
             categories.slug as category_slug
      FROM assets
      LEFT JOIN categories ON assets.category_id = categories.id
      WHERE assets.id = ?
    ''', [id]);

    if (results.isEmpty) return null;

    return await _loadAssetWithTags(results.first);
  }

  /// Get asset by slug
  Future<Asset?> getAssetBySlug(String slug) async {
    final results = await _db.rawQuery('''
      SELECT assets.*,
             categories.name as category,
             categories.slug as category_slug
      FROM assets
      LEFT JOIN categories ON assets.category_id = categories.id
      WHERE assets.slug = ?
    ''', [slug]);

    if (results.isEmpty) return null;

    return await _loadAssetWithTags(results.first);
  }

  /// Get featured assets
  Future<List<Asset>> getFeaturedAssets({int limit = 10}) async {
    final results = await _db.rawQuery('''
      SELECT assets.*,
             categories.name as category,
             categories.slug as category_slug
      FROM assets
      LEFT JOIN categories ON assets.category_id = categories.id
      WHERE assets.is_featured = 1
      ORDER BY assets.downloads_count DESC, assets.created_at DESC
      LIMIT ?
    ''', [limit]);

    final assets = <Asset>[];
    for (final result in results) {
      final asset = await _loadAssetWithTags(result);
      assets.add(asset);
    }

    return assets;
  }

  /// Get latest assets
  Future<List<Asset>> getLatestAssets({int limit = 10}) async {
    return await getAssets(
      limit: limit,
      orderBy: 'assets.created_at DESC',
    );
  }

  /// Load asset with tags from database result
  Future<Asset> _loadAssetWithTags(Map<String, dynamic> assetData) async {
    final assetId = assetData['id'] as String;

    // Load tags
    final tagResults = await _db.rawQuery('''
      SELECT tags.name
      FROM tags
      INNER JOIN asset_tags ON tags.id = asset_tags.tag_id
      WHERE asset_tags.asset_id = ?
      ORDER BY tags.name ASC
    ''', [assetId]);

    final tags = tagResults.map((t) => t['name'] as String).toList();

    // Create a mutable copy of assetData and add tags
    final mutableData = Map<String, dynamic>.from(assetData);
    mutableData['tags'] = tags.join(',');

    return Asset.fromJson(mutableData);
  }

  /// Load tags for multiple assets in a single query (batch optimization)
  /// Returns a map of asset IDs to their list of tag names
  Future<Map<String, List<String>>> loadAllAssetTags(List<String> assetIds) async {
    if (assetIds.isEmpty) return {};

    // Create placeholders for SQL IN clause
    final placeholders = assetIds.map((_) => '?').join(',');

    final tagResults = await _db.rawQuery('''
      SELECT asset_tags.asset_id, tags.name
      FROM asset_tags
      INNER JOIN tags ON tags.id = asset_tags.tag_id
      WHERE asset_tags.asset_id IN ($placeholders)
      ORDER BY tags.name ASC
    ''', assetIds);

    // Group tags by asset ID
    final Map<String, List<String>> tagsByAsset = {};
    for (final row in tagResults) {
      final assetId = row['asset_id'] as String;
      final tagName = row['name'] as String;
      tagsByAsset.putIfAbsent(assetId, () => []).add(tagName);
    }

    return tagsByAsset;
  }

  /// Update an asset
  Future<Asset> updateAsset(
    String id, {
    String? title,
    String? description,
    String? shortDescription,
    String? version,
    DateTime? lastUpdated,
    String? demoUrl,
    List<String>? tags,
    bool? isFeatured,
  }) async {
    final updates = <String, dynamic>{};

    if (title != null) {
      updates['title'] = title;
      updates['slug'] = _generateSlug(title);
    }
    if (description != null) updates['description'] = description;
    if (shortDescription != null) updates['short_description'] = shortDescription;
    if (version != null) updates['version'] = version;
    if (isFeatured != null) updates['is_featured'] = isFeatured ? 1 : 0;
    if (lastUpdated != null) updates['last_updated'] = lastUpdated.millisecondsSinceEpoch;
    if (demoUrl != null) updates['demo_url'] = demoUrl;
    // Note: updated_at is managed by SQLite trigger

    await _db.transaction((txn) async {
      if (updates.isNotEmpty) {
        await txn.update(
          'assets',
          updates,
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      // Update tags if provided
      if (tags != null) {
        // Delete existing tag associations
        await txn.delete(
          'asset_tags',
          where: 'asset_id = ?',
          whereArgs: [id],
        );

        // Insert new tags
        for (final tagName in tags) {
          final tagSlug = _generateSlug(tagName);
          final tagId = _uuid.v4();
          final now = DateTime.now().millisecondsSinceEpoch;

          await txn.rawInsert('''
            INSERT OR IGNORE INTO tags (id, name, slug, created_at)
            VALUES (?, ?, ?, ?)
          ''', [tagId, tagName, tagSlug, now]);

          final tagResult = await txn.query(
            'tags',
            where: 'slug = ?',
            whereArgs: [tagSlug],
            limit: 1,
          );

          final actualTagId = tagResult.first['id'] as String;

          await txn.insert('asset_tags', {
            'asset_id': id,
            'tag_id': actualTagId,
          });
        }
      }
    });

    final asset = await getAssetById(id);
    if (asset == null) throw Exception('Asset not found after update');

    return asset;
  }

  /// Delete an asset
  Future<void> deleteAsset(String id) async {
    final asset = await getAssetById(id);
    if (asset == null) throw Exception('Asset not found');

    await _db.transaction((txn) async {
      // Delete ZIP metadata
      await txn.delete('zip_metadata', where: 'asset_id = ?', whereArgs: [id]);

      // Delete tag associations
      await txn.delete('asset_tags', where: 'asset_id = ?', whereArgs: [id]);

      // Delete export history
      await txn.delete('export_history', where: 'asset_id = ?', whereArgs: [id]);

      // Delete asset
      await txn.delete('assets', where: 'id = ?', whereArgs: [id]);

      // Update category asset count
      await txn.rawUpdate('''
        UPDATE categories
        SET asset_count = asset_count - 1
        WHERE id = ?
      ''', [asset.category]);
    });

    // Delete files from storage
    await _storage.deleteAsset(asset.zipPath);
    await _storage.deleteThumbnails(id);
  }

  /// Export asset (full download)
  Future<String> exportAsset(String id, String destinationPath) async {
    final asset = await getAssetById(id);
    if (asset == null) throw Exception('Asset not found');

    // Copy ZIP to destination
    final exportPath = await _storage.exportAsset(asset.zipPath, destinationPath);

    // Record export history
    await _db.insert('export_history', {
      'id': _uuid.v4(),
      'asset_id': id,
      'export_path': exportPath,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'export_type': ExportType.full.value,
    });

    // Increment download count
    await incrementDownloadCount(id);

    return exportPath;
  }

  /// Increment download count
  Future<void> incrementDownloadCount(String id) async {
    await _db.rawUpdate('''
      UPDATE assets
      SET downloads_count = downloads_count + 1
      WHERE id = ?
    ''', [id]);
  }

  /// Get total asset count
  Future<int> getTotalAssetCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) as count FROM assets');
    return result.first['count'] as int;
  }

  /// Get asset count by category
  Future<int> getAssetCountByCategory(String categoryId) async {
    final result = await _db.rawQuery('''
      SELECT COUNT(*) as count
      FROM assets
      WHERE category_id = ?
    ''', [categoryId]);

    return result.first['count'] as int;
  }

  /// Get category distribution
  Future<Map<String, int>> getCategoryDistribution() async {
    final results = await _db.rawQuery('''
      SELECT categories.name, COUNT(assets.id) as count
      FROM categories
      LEFT JOIN assets ON categories.id = assets.category_id
      GROUP BY categories.id
      ORDER BY count DESC
    ''');

    final distribution = <String, int>{};
    for (final result in results) {
      distribution[result['name'] as String] = result['count'] as int;
    }

    return distribution;
  }

  /// Load ZIP metadata for an asset
  Future<ZipMetadata?> loadZipMetadata(String assetId) async {
    final results = await _db.query(
      'zip_metadata',
      where: 'asset_id = ?',
      whereArgs: [assetId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    return ZipMetadata.fromJson(results.first);
  }

  /// Generate a slug from a title
  String _generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }
}
