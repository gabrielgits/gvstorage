import 'package:flutter/foundation.dart';

import '../models/asset.dart';
import 'database_service.dart';

/// Service for searching and filtering assets
class SearchService {
  final DatabaseService _db;

  SearchService(this._db);

  /// Search assets with full-text search and filters
  Future<List<Asset>> search(
    String query, {
    String? categoryId,
    List<String> tags = const [],
    DateTime? createdAfter,
    DateTime? createdBefore,
    int? minFileSize,
    int? maxFileSize,
    String sortBy = 'relevance',
    int? limit,
    int? offset,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    // Full-text search
    if (query.isNotEmpty) {
      whereClauses.add('''
        assets.rowid IN (
          SELECT rowid FROM assets_fts
          WHERE assets_fts MATCH ?
        )
      ''');
      whereArgs.add(query);
    }

    // Category filter
    if (categoryId != null) {
      whereClauses.add('assets.category_id = ?');
      whereArgs.add(categoryId);
    }

    // Tag filter
    if (tags.isNotEmpty) {
      final placeholders = tags.map((_) => '?').join(',');
      whereClauses.add('''
        assets.id IN (
          SELECT asset_id FROM asset_tags
          WHERE tag_id IN (
            SELECT id FROM tags WHERE slug IN ($placeholders)
          )
        )
      ''');
      whereArgs.addAll(tags);
    }

    // Date range filters
    if (createdAfter != null) {
      whereClauses.add('assets.created_at >= ?');
      whereArgs.add(createdAfter.millisecondsSinceEpoch);
    }

    if (createdBefore != null) {
      whereClauses.add('assets.created_at <= ?');
      whereArgs.add(createdBefore.millisecondsSinceEpoch);
    }

    // File size filters
    if (minFileSize != null) {
      whereClauses.add('assets.file_size >= ?');
      whereArgs.add(minFileSize);
    }

    if (maxFileSize != null) {
      whereClauses.add('assets.file_size <= ?');
      whereArgs.add(maxFileSize);
    }

    // Build ORDER BY clause
    String orderBy;
    switch (sortBy) {
      case 'date':
      case 'latest':
        orderBy = 'assets.created_at DESC';
        break;
      case 'title':
        orderBy = 'assets.title ASC';
        break;
      case 'downloads':
        orderBy = 'assets.downloads_count DESC';
        break;
      case 'size_asc':
        orderBy = 'assets.file_size ASC';
        break;
      case 'size_desc':
        orderBy = 'assets.file_size DESC';
        break;
      case 'relevance':
      default:
        orderBy = query.isNotEmpty ? 'assets.created_at DESC' : 'assets.created_at DESC';
        break;
    }

    // Build final query
    final whereClause = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : '1=1';

    final sql = '''
      SELECT assets.*,
             categories.name as category,
             categories.slug as category_slug
      FROM assets
      LEFT JOIN categories ON assets.category_id = categories.id
      WHERE $whereClause
      ORDER BY $orderBy
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''';

    final results = await _db.rawQuery(sql, whereArgs);

    // Load tags for each asset
    final assets = <Asset>[];
    for (final result in results) {
      final asset = await _loadAssetWithTags(result);
      assets.add(asset);
    }

    return assets;
  }

  /// Load an asset with its tags
  Future<Asset> _loadAssetWithTags(Map<String, dynamic> assetData) async {
    final assetId = assetData['id'] as String;

    // Load tags
    final tagResults = await _db.rawQuery('''
      SELECT tags.name
      FROM tags
      INNER JOIN asset_tags ON tags.id = asset_tags.tag_id
      WHERE asset_tags.asset_id = ?
    ''', [assetId]);

    final tags = tagResults.map((t) => t['name'] as String).toList();

    // Add tags to asset data
    assetData['tags'] = tags.join(',');

    return Asset.fromJson(assetData);
  }

  /// Get search suggestions based on partial query
  Future<List<String>> getSearchSuggestions(String partialQuery, {int limit = 5}) async {
    if (partialQuery.isEmpty) return [];

    final results = await _db.rawQuery('''
      SELECT DISTINCT title
      FROM assets
      WHERE title LIKE ?
      ORDER BY downloads_count DESC
      LIMIT ?
    ''', ['%$partialQuery%', limit]);

    return results.map((r) => r['title'] as String).toList();
  }

  /// Get tag distribution (tag names with count)
  Future<Map<String, int>> getTagDistribution({String? categoryId}) async {
    String sql;
    List<dynamic> args = [];

    if (categoryId != null) {
      sql = '''
        SELECT tags.name, COUNT(asset_tags.asset_id) as count
        FROM tags
        INNER JOIN asset_tags ON tags.id = asset_tags.tag_id
        INNER JOIN assets ON asset_tags.asset_id = assets.id
        WHERE assets.category_id = ?
        GROUP BY tags.id
        ORDER BY count DESC, tags.name ASC
      ''';
      args = [categoryId];
    } else {
      sql = '''
        SELECT tags.name, COUNT(asset_tags.asset_id) as count
        FROM tags
        INNER JOIN asset_tags ON tags.id = asset_tags.tag_id
        GROUP BY tags.id
        ORDER BY count DESC, tags.name ASC
      ''';
    }

    final results = await _db.rawQuery(sql, args);

    final distribution = <String, int>{};
    for (final result in results) {
      distribution[result['name'] as String] = result['count'] as int;
    }

    return distribution;
  }

  /// Get popular tags (most used)
  Future<List<String>> getPopularTags({int limit = 10}) async {
    final results = await _db.rawQuery('''
      SELECT tags.name, COUNT(asset_tags.asset_id) as count
      FROM tags
      INNER JOIN asset_tags ON tags.id = asset_tags.tag_id
      GROUP BY tags.id
      ORDER BY count DESC
      LIMIT ?
    ''', [limit]);

    return results.map((r) => r['name'] as String).toList();
  }

  /// Get all unique tags
  Future<List<String>> getAllTags() async {
    final results = await _db.query(
      'tags',
      columns: ['name'],
      orderBy: 'name ASC',
    );

    return results.map((r) => r['name'] as String).toList();
  }

  /// Get recent searches (from app_settings if implemented)
  Future<List<String>> getRecentSearches({int limit = 5}) async {
    try {
      final results = await _db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['recent_searches'],
        limit: 1,
      );

      if (results.isEmpty) return [];

      final value = results.first['value'] as String;
      final searches = value.split('|').take(limit).toList();
      return searches;
    } catch (e) {
      return [];
    }
  }

  /// Save a search query to recent searches
  Future<void> saveRecentSearch(String query) async {
    if (query.isEmpty) return;

    try {
      // Get existing searches
      final existing = await getRecentSearches(limit: 10);

      // Remove if already exists
      existing.remove(query);

      // Add to front
      existing.insert(0, query);

      // Keep only last 10
      final searches = existing.take(10).toList();

      // Save back
      final value = searches.join('|');
      final now = DateTime.now().millisecondsSinceEpoch;

      await _db.rawInsert('''
        INSERT OR REPLACE INTO app_settings (key, value, updated_at)
        VALUES ('recent_searches', ?, ?)
      ''', [value, now]);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving recent search: $e');
      }
    }
  }
}
