import 'package:flutter/foundation.dart';

/// Provider for filtering, sorting, and pagination state
/// Manages filter/sort state shared across listing pages
class FilterProvider extends ChangeNotifier {
  String _sortBy = 'latest';
  int _currentPage = 1;
  int _itemsPerPage = 12;
  String? _categoryId;
  String _viewMode = 'grid'; // 'grid' or 'list'
  final List<String> _selectedTags = [];

  // Getters
  String get sortBy => _sortBy;
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  String? get categoryId => _categoryId;
  String get viewMode => _viewMode;
  List<String> get selectedTags => List.unmodifiable(_selectedTags);

  // Computed getters
  int get offset => (_currentPage - 1) * _itemsPerPage;
  bool get hasFilters => _categoryId != null || _selectedTags.isNotEmpty;

  /// Set sort by
  void setSortBy(String sortBy) {
    if (_sortBy != sortBy) {
      _sortBy = sortBy;
      _currentPage = 1; // Reset to first page when sort changes
      notifyListeners();
    }
  }

  /// Get order by SQL clause based on sortBy
  String get orderBy {
    switch (_sortBy) {
      case 'latest':
        return 'created_at DESC';
      case 'oldest':
        return 'created_at ASC';
      case 'name_asc':
        return 'title ASC';
      case 'name_desc':
        return 'title DESC';
      case 'popular':
        return 'downloads_count DESC';
      case 'size_asc':
        return 'file_size ASC';
      case 'size_desc':
        return 'file_size DESC';
      default:
        return 'created_at DESC';
    }
  }

  /// Set current page
  void setPage(int page) {
    if (_currentPage != page && page > 0) {
      _currentPage = page;
      notifyListeners();
    }
  }

  /// Go to next page
  void nextPage() {
    _currentPage++;
    notifyListeners();
  }

  /// Go to previous page
  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
    }
  }

  /// Set items per page
  void setItemsPerPage(int itemsPerPage) {
    if (_itemsPerPage != itemsPerPage && itemsPerPage > 0) {
      _itemsPerPage = itemsPerPage;
      _currentPage = 1; // Reset to first page when items per page changes
      notifyListeners();
    }
  }

  /// Set category filter
  void setCategory(String? categoryId) {
    if (_categoryId != categoryId) {
      _categoryId = categoryId;
      _currentPage = 1; // Reset to first page when category changes
      notifyListeners();
    }
  }

  /// Clear category filter
  void clearCategory() {
    if (_categoryId != null) {
      _categoryId = null;
      _currentPage = 1;
      notifyListeners();
    }
  }

  /// Set view mode
  void setViewMode(String mode) {
    if (mode == 'grid' || mode == 'list') {
      if (_viewMode != mode) {
        _viewMode = mode;
        notifyListeners();
      }
    }
  }

  /// Toggle view mode
  void toggleViewMode() {
    _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
    notifyListeners();
  }

  /// Add tag filter
  void addTag(String tag) {
    if (!_selectedTags.contains(tag)) {
      _selectedTags.add(tag);
      _currentPage = 1; // Reset to first page when filters change
      notifyListeners();
    }
  }

  /// Remove tag filter
  void removeTag(String tag) {
    if (_selectedTags.remove(tag)) {
      _currentPage = 1;
      notifyListeners();
    }
  }

  /// Clear all tag filters
  void clearTags() {
    if (_selectedTags.isNotEmpty) {
      _selectedTags.clear();
      _currentPage = 1;
      notifyListeners();
    }
  }

  /// Reset all filters
  void resetFilters() {
    bool hasChanges = _categoryId != null ||
                      _selectedTags.isNotEmpty ||
                      _sortBy != 'latest' ||
                      _currentPage != 1;

    if (hasChanges) {
      _categoryId = null;
      _selectedTags.clear();
      _sortBy = 'latest';
      _currentPage = 1;
      notifyListeners();
    }
  }

  /// Reset pagination only (keep filters/sort)
  void resetPagination() {
    if (_currentPage != 1) {
      _currentPage = 1;
      notifyListeners();
    }
  }
}
