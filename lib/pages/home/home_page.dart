import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/models.dart';
import '../../providers/asset_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/widgets.dart';
import '../../main.dart' show handleExportAllData, handleImportAllData;

/// Home page - main landing page of the application
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _dataLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Load data only once - defer to after build completes
    if (!_dataLoaded) {
      _dataLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadData();
        }
      });
    }
  }

  Future<void> _loadData() async {
    final assetProvider = context.read<AssetProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    // Load data in parallel
    await Future.wait([
      categoryProvider.loadCategories(),
      assetProvider.loadFeaturedAssets(limit: 4),
      assetProvider.loadLatestAssets(limit: 8),
    ]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AssetProvider, CategoryProvider>(
      builder: (context, assetProvider, categoryProvider, child) {
        final isLoading = assetProvider.isLoading ||
                          assetProvider.isFeaturedLoading ||
                          assetProvider.isLatestLoading ||
                          categoryProvider.isLoading;

        return AppScaffold(
          currentRoute: '/',
          onNavigate: (route) => context.go(route),
          onUploadTap: () => context.go('/upload'),
          onExportAllData: handleExportAllData,
          onImportAllData: handleImportAllData,
          scrollController: _scrollController,
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero section
                    _buildHeroSection(),
                    const SizedBox(height: AppConstants.spacingXxl),

                    // Categories section
                    if (categoryProvider.categories.isNotEmpty) ...[
                      _buildCategoriesSection(categoryProvider.categories),
                      const SizedBox(height: AppConstants.spacingXxl),
                    ],

                    // Featured assets section
                    if (assetProvider.featuredAssets.isNotEmpty) ...[
                      _buildFeaturedAssetsSection(assetProvider.featuredAssets),
                      const SizedBox(height: AppConstants.spacingXxl),
                    ],

                    // Latest assets section
                    if (assetProvider.latestAssets.isNotEmpty) ...[
                      _buildLatestAssetsSection(assetProvider.latestAssets),
                      const SizedBox(height: AppConstants.spacingXxl),
                    ],

                    // Quick start section
                    _buildQuickStartSection(),
                    const SizedBox(height: AppConstants.spacingXl),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.spacingXxl,
        horizontal: AppConstants.spacingLg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Digital Asset Management',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                Text(
                  'Organize, manage, and access your scripts, templates, themes, and plugins in one place.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLg),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/upload'),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Asset'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/assets'),
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Browse Assets'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spacingXl),
          // Hero illustration
          Container(
            width: 400,
            height: 300,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            ),
            child: Center(
              child: Icon(
                Icons.folder_zip_outlined,
                size: 120,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(List<Category> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Browse Categories',
          subtitle: 'Find what you need',
        ),
        Wrap(
          spacing: AppConstants.spacingMd,
          runSpacing: AppConstants.spacingMd,
          children: categories.map((category) {
            return _CategoryCard(
              category: category,
              onTap: () => context.go('/category/${category.slug}'),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeaturedAssetsSection(List<Asset> featuredAssets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Featured Assets',
          subtitle: 'Handpicked for you',
          viewAllText: 'View All',
          onViewAll: () => context.go('/assets?featured=true'),
        ),
        AssetGrid(
          assets: featuredAssets.take(4).toList(),
          onAssetTap: (asset) => context.go('/asset/${asset.slug}'),
        ),
      ],
    );
  }

  Widget _buildLatestAssetsSection(List<Asset> latestAssets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Latest Assets',
          subtitle: 'Recently added',
          viewAllText: 'View All',
          onViewAll: () => context.go('/assets?sort=latest'),
        ),
        AssetGrid(
          assets: latestAssets.take(8).toList(),
          onAssetTap: (asset) => context.go('/asset/${asset.slug}'),
        ),
      ],
    );
  }

  Widget _buildQuickStartSection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingXl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Start',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            'Get started with GvStorage in a few simple steps',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Row(
            children: [
              Expanded(
                child: _QuickStartCard(
                  icon: Icons.upload_file,
                  title: 'Upload',
                  description: 'Add ZIP files containing your digital assets',
                  onTap: () => context.go('/upload'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: _QuickStartCard(
                  icon: Icons.search,
                  title: 'Search',
                  description: 'Find assets quickly with full-text search',
                  onTap: () => context.go('/assets'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: _QuickStartCard(
                  icon: Icons.folder_zip,
                  title: 'Preview',
                  description: 'View ZIP contents without extracting',
                  onTap: () => context.go('/assets'),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: _QuickStartCard(
                  icon: Icons.download,
                  title: 'Export',
                  description: 'Download full or selected files from ZIPs',
                  onTap: () => context.go('/assets'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Category card widget
class _CategoryCard extends StatefulWidget {
  final Category category;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.category,
    this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.primary : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.border,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCategoryIcon(widget.category.slug),
                color: _isHovered ? AppColors.textOnPrimary : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.category.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: _isHovered
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${widget.category.assetCount} assets',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _isHovered
                          ? AppColors.textOnPrimary.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug) {
      case 'scripts':
        return Icons.code;
      case 'templates':
        return Icons.dashboard;
      case 'themes':
        return Icons.palette;
      case 'plugins':
        return Icons.extension;
      default:
        return Icons.folder;
    }
  }
}

/// Quick start card widget
class _QuickStartCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _QuickStartCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  State<_QuickStartCard> createState() => _QuickStartCardState();
}

class _QuickStartCardState extends State<_QuickStartCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingSm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Icon(
                  widget.icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                widget.title,
                style: AppTextStyles.titleSmall,
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                widget.description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
