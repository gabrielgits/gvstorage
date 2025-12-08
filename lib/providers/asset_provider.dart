import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/asset.dart';
import '../services/service_locator.dart';

/// Provider for asset state management
/// Wraps AssetService and provides caching and reactive state updates
class AssetProvider extends ChangeNotifier {
  // Cache maps
  final Map<String, Asset> _assetCache = {};
  List<Asset>? _allAssets;
  List<Asset>? _featuredAssets;
  List<Asset>? _latestAssets;

  // Loading states
  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  bool _isLatestLoading = false;

  // Error states
  String? _errorMessage;

  // Pagination state
  int? _totalCount;

  // Getters
  bool get isLoading => _isLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;
  bool get isLatestLoading => _isLatestLoading;
  String? get errorMessage => _errorMessage;

  List<Asset> get allAssets => _allAssets ?? [];
  List<Asset> get featuredAssets => _featuredAssets ?? [];
  List<Asset> get latestAssets => _latestAssets ?? [];

  bool get isLoaded => _allAssets != null || _featuredAssets != null || _latestAssets != null;
  int? get totalCount => _totalCount;

  /// Load assets with optional filters
  Future<void> loadAssets({
    int? limit,
    int? offset,
    String? categoryId,
    String? orderBy,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final assets = await services.asset.getAssets(
        limit: limit,
        offset: offset,
        categoryId: categoryId,
        orderBy: orderBy,
      );

      _allAssets = assets;

      // Update cache
      for (final asset in assets) {
        _assetCache[asset.slug] = asset;
      }

      // Load total count if pagination is being used
      if (limit != null || offset != null) {
        _totalCount = await services.asset.getTotalAssetCount();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load featured assets
  Future<void> loadFeaturedAssets({int limit = 6}) async {
    try {
      _isFeaturedLoading = true;
      _errorMessage = null;
      notifyListeners();

      final assets = await services.asset.getFeaturedAssets(limit: limit);
      _featuredAssets = assets;

      // Update cache
      for (final asset in assets) {
        _assetCache[asset.slug] = asset;
      }

      _isFeaturedLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isFeaturedLoading = false;
      notifyListeners();
    }
  }

  /// Load latest assets
  Future<void> loadLatestAssets({int limit = 6}) async {
    try {
      _isLatestLoading = true;
      _errorMessage = null;
      notifyListeners();

      final assets = await services.asset.getLatestAssets(limit: limit);
      _latestAssets = assets;

      // Update cache
      for (final asset in assets) {
        _assetCache[asset.slug] = asset;
      }

      _isLatestLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLatestLoading = false;
      notifyListeners();
    }
  }

  /// Get asset by slug (from cache or load from database)
  Future<Asset?> getAssetBySlug(String slug) async {
    // Check cache first
    if (_assetCache.containsKey(slug)) {
      return _assetCache[slug];
    }

    // Load from database
    try {
      final asset = await services.asset.getAssetBySlug(slug);
      if (asset != null) {
        _assetCache[slug] = asset;
      }
      return asset;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Get asset by ID (from cache or load from database)
  Future<Asset?> getAssetById(String id) async {
    // Check cache first
    final cachedAsset = _assetCache.values.firstWhere(
      (asset) => asset.id == id,
      orElse: () => Asset(
        id: '',
        title: '',
        slug: '',
        description: '',
        imageUrl: '',
        category: '',
        categorySlug: '',
        createdAt: DateTime.now(),
        fileSize: 0,
        zipPath: '',
        updatedAt: DateTime.now(),
      ),
    );

    if (cachedAsset.id.isNotEmpty) {
      return cachedAsset;
    }

    // Load from database
    try {
      final asset = await services.asset.getAssetById(id);
      if (asset != null) {
        _assetCache[asset.slug] = asset;
      }
      return asset;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Upload a new asset
  Future<Asset?> uploadAsset({
    required File zipFile,
    required String title,
    required String categoryId,
    String? description,
    String? shortDescription,
    String? version,
    List<String> tags = const [],
    List<AssetFeature> features = const [],
    File? thumbnail,
    List<File> galleryImages = const [],
    bool isFeatured = false,
  }) async {
    try {
      _errorMessage = null;

      final asset = await services.asset.uploadAsset(
        zipFile: zipFile,
        title: title,
        categoryId: categoryId,
        description: description,
        shortDescription: shortDescription,
        version: version,
        tags: tags,
        features: features,
        thumbnail: thumbnail,
        galleryImages: galleryImages,
        isFeatured: isFeatured,
      );

      // Invalidate caches after upload
      await invalidateCache();

      // Reload featured and latest assets
      await Future.wait([
        loadFeaturedAssets(),
        loadLatestAssets(),
      ]);

      return asset;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update an existing asset
  Future<bool> updateAsset(
    String id, {
    String? title,
    String? description,
    String? shortDescription,
    String? version,
    List<String>? tags,
    bool? isFeatured,
  }) async {
    try {
      _errorMessage = null;

      final updatedAsset = await services.asset.updateAsset(
        id,
        title: title,
        description: description,
        shortDescription: shortDescription,
        version: version,
        tags: tags,
        isFeatured: isFeatured,
      );

      // Update cache
      _assetCache[updatedAsset.slug] = updatedAsset;

      // Invalidate list caches
      _allAssets = null;
      _featuredAssets = null;
      _latestAssets = null;

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete an asset
  Future<bool> deleteAsset(String id) async {
    try {
      _errorMessage = null;

      await services.asset.deleteAsset(id);

      // Invalidate all caches
      await invalidateCache();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Export asset to destination path
  Future<String?> exportAsset(String id, String destinationPath) async {
    try {
      _errorMessage = null;

      final exportPath = await services.asset.exportAsset(id, destinationPath);

      // Increment download count
      await services.asset.incrementDownloadCount(id);

      // Update cached asset if exists
      final cachedAsset = _assetCache.values.firstWhere(
        (asset) => asset.id == id,
        orElse: () => Asset(
          id: '',
          title: '',
          slug: '',
          description: '',
          imageUrl: '',
          category: '',
          categorySlug: '',
          createdAt: DateTime.now(),
          fileSize: 0,
          zipPath: '',
          updatedAt: DateTime.now(),
        ),
      );

      if (cachedAsset.id.isNotEmpty) {
        _assetCache[cachedAsset.slug] = cachedAsset.copyWith(
          downloadsCount: cachedAsset.downloadsCount + 1,
        );
        notifyListeners();
      }

      return exportPath;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Invalidate all caches
  Future<void> invalidateCache() async {
    _assetCache.clear();
    _allAssets = null;
    _featuredAssets = null;
    _latestAssets = null;
    _totalCount = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
