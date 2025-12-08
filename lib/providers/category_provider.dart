import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../services/service_locator.dart';

/// Provider for category state management
/// Wraps CategoryService and provides caching and reactive state updates
class CategoryProvider extends ChangeNotifier {
  // Cache maps
  final Map<String, Category> _categoryCache = {};
  List<Category>? _allCategories;
  List<Category>? _categoryTree;

  // Loading states
  bool _isLoading = false;

  // Error states
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Category> get categories => _allCategories ?? [];
  List<Category> get categoryTree => _categoryTree ?? [];
  bool get isLoaded => _allCategories != null;

  /// Load all categories
  Future<void> loadCategories({String? parentId}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final categories = parentId != null
          ? await services.category.getCategories(parentId: parentId)
          : await services.category.getAllCategories();

      if (parentId == null) {
        _allCategories = categories;
      }

      // Update cache
      for (final category in categories) {
        _categoryCache[category.slug] = category;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load category tree (hierarchical structure)
  Future<void> loadCategoryTree() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final tree = await services.category.getCategoryTree();
      _categoryTree = tree;

      // Also update cache with all categories in tree (flattened)
      void cacheCategories(List<Category> categories) {
        for (final category in categories) {
          _categoryCache[category.slug] = category;
          if (category.hasSubcategories) {
            cacheCategories(category.subcategories);
          }
        }
      }

      cacheCategories(tree);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get category by slug (from cache or load from database)
  Future<Category?> getCategoryBySlug(String slug) async {
    // Check cache first
    if (_categoryCache.containsKey(slug)) {
      return _categoryCache[slug];
    }

    // Load from database
    try {
      final category = await services.category.getCategoryBySlug(slug);
      if (category != null) {
        _categoryCache[slug] = category;
      }
      return category;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get category by ID (from cache or load from database)
  Future<Category?> getCategoryById(String id) async {
    // Check cache first
    final cachedCategory = _categoryCache.values.firstWhere(
      (category) => category.id == id,
      orElse: () => Category(
        id: '',
        name: '',
        slug: '',
      ),
    );

    if (cachedCategory.id.isNotEmpty) {
      return cachedCategory;
    }

    // Load from database
    try {
      final category = await services.category.getCategoryById(id);
      if (category != null) {
        _categoryCache[category.slug] = category;
      }
      return category;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Create a new category
  Future<Category?> createCategory({
    required String id,
    required String name,
    required String slug,
    String? description,
    String? imageUrl,
    String? parentId,
    int displayOrder = 0,
  }) async {
    try {
      _errorMessage = null;

      final category = await services.category.createCategory(
        id: id,
        name: name,
        slug: slug,
        description: description,
        imageUrl: imageUrl,
        parentId: parentId,
        displayOrder: displayOrder,
      );

      // Invalidate caches after creation
      await invalidateCache();

      // Reload categories
      await loadCategories();

      return category;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update an existing category
  Future<bool> updateCategory(
    String id, {
    String? name,
    String? slug,
    String? description,
    String? imageUrl,
    int? displayOrder,
  }) async {
    try {
      _errorMessage = null;

      final updatedCategory = await services.category.updateCategory(
        id,
        name: name,
        slug: slug,
        description: description,
        imageUrl: imageUrl,
        displayOrder: displayOrder,
      );

      // Update cache
      _categoryCache[updatedCategory.slug] = updatedCategory;

      // Invalidate list caches
      _allCategories = null;
      _categoryTree = null;

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(
    String id, {
    bool moveAssets = false,
    String? targetCategoryId,
  }) async {
    try {
      _errorMessage = null;

      await services.category.deleteCategory(
        id,
        moveAssets: moveAssets,
        targetCategoryId: targetCategoryId,
      );

      // Invalidate all caches
      await invalidateCache();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get asset count for a category
  Future<int> getAssetCount(String categoryId, {bool recursive = false}) async {
    try {
      return await services.category.getAssetCount(
        categoryId,
        recursive: recursive,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return 0;
    }
  }

  /// Invalidate all caches
  Future<void> invalidateCache() async {
    _categoryCache.clear();
    _allCategories = null;
    _categoryTree = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
