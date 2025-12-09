import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/asset.dart';
import '../../models/category.dart';
import '../../providers/asset_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/asset/asset_grid.dart';
import '../../widgets/common/common.dart';
import '../../widgets/layout/layout.dart';
import '../../main.dart' show handleExportAllData, handleImportAllData;

/// Asset listing page with filters and pagination
class AssetListingPage extends StatefulWidget {
  final String? categorySlug;

  const AssetListingPage({
    super.key,
    this.categorySlug,
  });

  @override
  State<AssetListingPage> createState() => _AssetListingPageState();
}

class _AssetListingPageState extends State<AssetListingPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Category? _currentCategory;
  bool _dataLoaded = false;
  bool _isSearchMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Load data only once or when category changes - defer to after build completes
    if (!_dataLoaded) {
      _dataLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadData();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AssetListingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categorySlug != widget.categorySlug) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<FilterProvider>().resetPagination();
          _loadData();
        }
      });
    }
  }

  Future<void> _loadData() async {
    final assetProvider = context.read<AssetProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final filterProvider = context.read<FilterProvider>();

    // Load categories if not already loaded
    if (categoryProvider.categories.isEmpty) {
      await categoryProvider.loadCategories();
    }

    // Get current category by slug
    if (widget.categorySlug != null) {
      _currentCategory = await categoryProvider.getCategoryBySlug(widget.categorySlug!);
      filterProvider.setCategory(_currentCategory?.id);
    } else {
      _currentCategory = null;
      filterProvider.clearCategory();
    }

    // Load assets with current filters
    await assetProvider.loadAssets(
      limit: filterProvider.itemsPerPage,
      offset: filterProvider.offset,
      categoryId: filterProvider.categoryId,
      orderBy: filterProvider.orderBy,
    );
  }

  void _performSearch(String query) async {
    final searchProvider = context.read<SearchProvider>();
    final filterProvider = context.read<FilterProvider>();

    if (query.isEmpty) {
      setState(() => _isSearchMode = false);
      searchProvider.clearSearch();
      await _loadData();
      return;
    }

    setState(() => _isSearchMode = true);
    await searchProvider.search(
      query,
      categoryId: filterProvider.categoryId,
      sortBy: filterProvider.sortBy,
      limit: filterProvider.itemsPerPage,
      offset: filterProvider.offset,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    final searchProvider = context.read<SearchProvider>();
    searchProvider.clearSearch();
    setState(() => _isSearchMode = false);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<AssetProvider, CategoryProvider, FilterProvider, SearchProvider>(
      builder: (context, assetProvider, categoryProvider, filterProvider, searchProvider, child) {
        // Determine which assets to display (search results or regular listing)
        final displayAssets = _isSearchMode && searchProvider.hasQuery
            ? searchProvider.searchResults
            : assetProvider.allAssets;

        final isLoading = _isSearchMode
            ? searchProvider.isSearching
            : assetProvider.isLoading;
        return AppScaffold(
          currentRoute: widget.categorySlug != null
              ? '/category/${widget.categorySlug}'
              : '/assets',
          onNavigate: (route) => context.go(route),
          onExportAllData: handleExportAllData,
          onImportAllData: handleImportAllData,
          scrollController: _scrollController,
          sidebar: _buildSidebar(categoryProvider.categories),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumbs
              _buildBreadcrumbs(),
              const SizedBox(height: AppConstants.spacingMd),

              // Page header
              _buildPageHeader(displayAssets),
              const SizedBox(height: AppConstants.spacingLg),

              // Search bar
              _buildSearchBar(searchProvider),
              const SizedBox(height: AppConstants.spacingMd),

              // Toolbar (sort, view mode)
              _buildToolbar(displayAssets, filterProvider),
              const SizedBox(height: AppConstants.spacingLg),

              // Assets grid
              isLoading
                ? _buildLoadingState()
                : _buildAssetsGrid(displayAssets, filterProvider.viewMode),
              const SizedBox(height: AppConstants.spacingXl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreadcrumbs() {
    final items = [
      BreadcrumbItem(
        label: 'Home',
        onTap: () => context.go('/'),
      ),
      if (_currentCategory != null)
        BreadcrumbItem(
          label: 'Assets',
          onTap: () => context.go('/assets'),
        ),
      BreadcrumbItem(
        label: _currentCategory?.name ?? 'All Assets',
      ),
    ];

    return Breadcrumbs(items: items);
  }

  Widget _buildSearchBar(SearchProvider searchProvider) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search assets by title or description...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textHint),
                        onPressed: _clearSearch,
                        tooltip: 'Clear search',
                      )
                    : null,
              ),
              style: AppTextStyles.bodyMedium,
              onSubmitted: _performSearch,
              onChanged: (value) {
                setState(() {}); // Rebuild to show/hide clear button
              },
            ),
          ),
          const SizedBox(width: AppConstants.spacingSm),
          ElevatedButton.icon(
            onPressed: () => _performSearch(_searchController.text),
            icon: const Icon(Icons.search, size: 20),
            label: const Text('Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingMd,
                vertical: AppConstants.spacingSm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(List<Asset> assets) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentCategory?.name ?? 'All Assets',
                style: AppTextStyles.headlineLarge,
              ),
              if (assets.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _isSearchMode
                        ? '${assets.length} search results'
                        : '${assets.length} assets found',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Upload button
        ElevatedButton.icon(
          onPressed: () => context.go('/upload'),
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Asset'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(List<Asset> assets, FilterProvider filterProvider) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Row(
        children: [
          // View mode toggle
          ViewModeToggle(
            currentMode: filterProvider.viewMode == 'grid'
              ? ViewMode.grid
              : ViewMode.list,
            onChanged: (mode) {
              filterProvider.setViewMode(
                mode == ViewMode.grid ? 'grid' : 'list'
              );
            },
          ),
          const SizedBox(width: AppConstants.spacingMd),

          // Results count
          Expanded(
            child: Text(
              'Showing ${assets.length} results',
              style: AppTextStyles.bodyMedium,
            ),
          ),

          // Sort dropdown
          SortDropdown(
            selectedValue: filterProvider.sortBy,
            onChanged: (value) {
              filterProvider.setSortBy(value);
              _loadData();
            },
            options: AppConstants.assetSortOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(List<Category> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories filter
        _buildCategoriesFilter(categories),
      ],
    );
  }

  Widget _buildCategoriesFilter(List<Category> categories) {
    // Calculate total asset count from all categories
    final totalAssetCount = categories.fold<int>(
      0,
      (sum, category) => sum + category.assetCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categories', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppConstants.spacingSm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // All assets option
              _CategoryFilterItem(
                name: 'All Assets',
                count: totalAssetCount,
                isSelected: widget.categorySlug == null,
                onTap: () => context.go('/assets'),
              ),
              const Divider(height: 1),
              // Category list
              ...categories.map((category) {
                return _CategoryFilterItem(
                  name: category.name,
                  count: category.assetCount,
                  isSelected: category.slug == widget.categorySlug,
                  onTap: () => context.go('/category/${category.slug}'),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
            ),
            SizedBox(height: AppConstants.spacingMd),
            Text(
              'Loading assets...',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsGrid(List<Asset> assets, String viewMode) {
    if (assets.isEmpty) {
      return _buildEmptyState();
    }

    final isListMode = viewMode == 'list';

    return AssetGrid(
      assets: assets,
      onAssetTap: (asset) => context.go('/asset/${asset.slug}'),
      crossAxisCount: isListMode ? 1 : null,
      childAspectRatio: isListMode ? 3.5 : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXxl),
        child: Column(
          children: [
            Icon(
              _isSearchMode ? Icons.search_off : Icons.folder_zip_outlined,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              _isSearchMode ? 'No search results' : 'No assets found',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              _isSearchMode
                  ? 'Try different search terms or clear your search'
                  : 'Try adjusting your filters or upload a new asset',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            if (_isSearchMode)
              OutlinedButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => context.go('/upload'),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Asset'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Category filter item
class _CategoryFilterItem extends StatefulWidget {
  final String name;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;

  const _CategoryFilterItem({
    required this.name,
    this.count = 0,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<_CategoryFilterItem> createState() => _CategoryFilterItemState();
}

class _CategoryFilterItemState extends State<_CategoryFilterItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          color: widget.isSelected || _isHovered
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: widget.isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              Text(
                '(${widget.count})',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
