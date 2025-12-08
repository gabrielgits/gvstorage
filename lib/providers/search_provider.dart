import 'package:flutter/foundation.dart';
import '../models/asset.dart';
import '../services/service_locator.dart';

/// Provider for search state management
/// Wraps SearchService and provides reactive search functionality
class SearchProvider extends ChangeNotifier {
  String _query = '';
  List<Asset> _searchResults = [];
  List<String> _suggestions = [];
  List<String> _recentSearches = [];
  Map<String, int> _tagDistribution = {};
  List<String> _popularTags = [];

  // Loading states
  bool _isSearching = false;
  bool _isLoadingSuggestions = false;

  // Error states
  String? _errorMessage;

  // Getters
  String get query => _query;
  List<Asset> get searchResults => _searchResults;
  List<String> get suggestions => _suggestions;
  List<String> get recentSearches => _recentSearches;
  Map<String, int> get tagDistribution => _tagDistribution;
  List<String> get popularTags => _popularTags;
  bool get isSearching => _isSearching;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  String? get errorMessage => _errorMessage;
  bool get hasQuery => _query.isNotEmpty;
  bool get hasResults => _searchResults.isNotEmpty;

  /// Perform search
  Future<void> search(
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
    try {
      _query = query;
      _isSearching = true;
      _errorMessage = null;
      notifyListeners();

      final results = await services.search.search(
        query,
        categoryId: categoryId,
        tags: tags,
        createdAfter: createdAfter,
        createdBefore: createdBefore,
        minFileSize: minFileSize,
        maxFileSize: maxFileSize,
        sortBy: sortBy,
        limit: limit,
        offset: offset,
      );

      _searchResults = results;

      // Save to recent searches if query is not empty
      if (query.isNotEmpty) {
        await services.search.saveRecentSearch(query);
        await loadRecentSearches();
      }

      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Get search suggestions (autocomplete)
  Future<void> getSuggestions(String partialQuery, {int limit = 5}) async {
    try {
      _isLoadingSuggestions = true;
      _errorMessage = null;
      notifyListeners();

      final suggestions = await services.search.getSearchSuggestions(
        partialQuery,
        limit: limit,
      );

      _suggestions = suggestions;

      _isLoadingSuggestions = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingSuggestions = false;
      notifyListeners();
    }
  }

  /// Load recent searches
  Future<void> loadRecentSearches({int limit = 5}) async {
    try {
      final recent = await services.search.getRecentSearches(limit: limit);
      _recentSearches = recent;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load tag distribution
  Future<void> loadTagDistribution({String? categoryId}) async {
    try {
      final distribution = await services.search.getTagDistribution(
        categoryId: categoryId,
      );
      _tagDistribution = distribution;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load popular tags
  Future<void> loadPopularTags({int limit = 10}) async {
    try {
      final tags = await services.search.getPopularTags(limit: limit);
      _popularTags = tags;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _query = '';
    _searchResults = [];
    _suggestions = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear suggestions only
  void clearSuggestions() {
    _suggestions = [];
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
