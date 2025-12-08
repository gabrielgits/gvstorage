import '../models/category.dart';
import 'database_service.dart';

/// Service for managing categories
class CategoryService {
  final DatabaseService _db;

  CategoryService(this._db);

  /// Get all categories
  Future<List<Category>> getAllCategories() async {
    final results = await _db.query(
      'categories',
      orderBy: 'display_order ASC, name ASC',
    );
    return results.map((json) => Category.fromJson(json)).toList();
  }

  /// Get categories (optionally filtered by parent)
  Future<List<Category>> getCategories({String? parentId}) async {
    final List<Map<String, dynamic>> results;

    if (parentId != null) {
      results = await _db.query(
        'categories',
        where: 'parent_id = ?',
        whereArgs: [parentId],
        orderBy: 'display_order ASC, name ASC',
      );
    } else {
      results = await _db.query(
        'categories',
        where: 'parent_id IS NULL',
        orderBy: 'display_order ASC, name ASC',
      );
    }

    return results.map((json) => Category.fromJson(json)).toList();
  }

  /// Get a category by ID
  Future<Category?> getCategoryById(String id) async {
    final results = await _db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Category.fromJson(results.first);
  }

  /// Get a category by slug
  Future<Category?> getCategoryBySlug(String slug) async {
    final results = await _db.query(
      'categories',
      where: 'slug = ?',
      whereArgs: [slug],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Category.fromJson(results.first);
  }

  /// Get category tree (hierarchical structure)
  Future<List<Category>> getCategoryTree() async {
    // Get all categories
    final allCategories = await _db.query(
      'categories',
      orderBy: 'display_order ASC, name ASC',
    );

    final categoryMap = <String, Map<String, dynamic>>{};
    final rootCategories = <Map<String, dynamic>>[];

    // First pass: build map and identify root categories
    for (final cat in allCategories) {
      categoryMap[cat['id'] as String] = {
        ...cat,
        'subcategories': <Map<String, dynamic>>[],
      };

      if (cat['parent_id'] == null) {
        rootCategories.add(categoryMap[cat['id'] as String]!);
      }
    }

    // Second pass: build hierarchy
    for (final cat in allCategories) {
      final parentId = cat['parent_id'] as String?;
      if (parentId != null && categoryMap.containsKey(parentId)) {
        (categoryMap[parentId]!['subcategories'] as List).add(
          categoryMap[cat['id'] as String]!,
        );
      }
    }

    // Convert to Category objects
    return rootCategories.map((json) => Category.fromJson(json)).toList();
  }

  /// Create a new category
  Future<Category> createCategory({
    required String id,
    required String name,
    required String slug,
    String? description,
    String? imageUrl,
    String? parentId,
    int displayOrder = 0,
  }) async {
    final now = DateTime.now();

    await _db.insert('categories', {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'parent_id': parentId,
      'display_order': displayOrder,
      'asset_count': 0,
      'created_at': now.millisecondsSinceEpoch,
    });

    return Category(
      id: id,
      name: name,
      slug: slug,
      description: description,
      imageUrl: imageUrl,
      parentId: parentId,
      displayOrder: displayOrder,
      createdAt: now,
    );
  }

  /// Update a category
  Future<Category> updateCategory(
    String id, {
    String? name,
    String? slug,
    String? description,
    String? imageUrl,
    int? displayOrder,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (slug != null) updates['slug'] = slug;
    if (description != null) updates['description'] = description;
    if (displayOrder != null) updates['display_order'] = displayOrder;

    if (updates.isNotEmpty) {
      await _db.update(
        'categories',
        updates,
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    final category = await getCategoryById(id);
    if (category == null) {
      throw Exception('Category not found after update');
    }

    return category;
  }

  /// Delete a category
  Future<void> deleteCategory(
    String id, {
    bool moveAssets = false,
    String? targetCategoryId,
  }) async {
    if (moveAssets && targetCategoryId != null) {
      // Move assets to target category
      await _db.rawUpdate('''
        UPDATE assets
        SET category_id = ?
        WHERE category_id = ?
      ''', [targetCategoryId, id]);

      // Update target category asset count
      await updateAssetCount(targetCategoryId);
    }

    // Delete category (CASCADE will handle child categories if any)
    await _db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update asset count for a category
  Future<void> updateAssetCount(String categoryId) async {
    final result = await _db.rawQuery('''
      SELECT COUNT(*) as count
      FROM assets
      WHERE category_id = ?
    ''', [categoryId]);

    final count = result.first['count'] as int;

    await _db.update(
      'categories',
      {'asset_count': count},
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  /// Get asset count for a category (optionally recursive)
  Future<int> getAssetCount(String categoryId, {bool recursive = false}) async {
    if (!recursive) {
      final result = await _db.rawQuery('''
        SELECT COUNT(*) as count
        FROM assets
        WHERE category_id = ?
      ''', [categoryId]);

      return result.first['count'] as int;
    } else {
      // Get this category and all subcategories
      final subcategoryIds = await _getSubcategoryIds(categoryId);
      subcategoryIds.add(categoryId);

      final placeholders = subcategoryIds.map((_) => '?').join(',');
      final result = await _db.rawQuery('''
        SELECT COUNT(*) as count
        FROM assets
        WHERE category_id IN ($placeholders)
      ''', subcategoryIds);

      return result.first['count'] as int;
    }
  }

  /// Get all subcategory IDs recursively
  Future<List<String>> _getSubcategoryIds(String parentId) async {
    final ids = <String>[];

    final children = await _db.query(
      'categories',
      columns: ['id'],
      where: 'parent_id = ?',
      whereArgs: [parentId],
    );

    for (final child in children) {
      final childId = child['id'] as String;
      ids.add(childId);

      // Recursive call for nested subcategories
      final grandChildren = await _getSubcategoryIds(childId);
      ids.addAll(grandChildren);
    }

    return ids;
  }
}
