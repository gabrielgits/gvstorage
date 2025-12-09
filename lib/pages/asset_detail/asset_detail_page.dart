import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/asset.dart';
import '../../providers/asset_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/asset/asset_grid.dart';
import '../../widgets/asset/asset_image_gallery.dart';
import '../../widgets/common/common.dart';
import '../../widgets/layout/layout.dart';
import '../../main.dart' show handleExportAllData, handleImportAllData;

/// Asset detail page with full asset information
class AssetDetailPage extends StatefulWidget {
  final String slug;

  const AssetDetailPage({
    super.key,
    required this.slug,
  });

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  Asset? _asset;
  List<Asset> _relatedAssets = [];
  bool _dataLoaded = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

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

    // Get asset from cache or load
    _asset = await assetProvider.getAssetBySlug(widget.slug);

    // Load ZIP metadata if not already loaded (lightweight, without entries)
    if (_asset != null && _asset!.zipMetadata == null) {
      final zipMetadata = await services.asset.loadZipMetadata(_asset!.id);
      if (zipMetadata != null) {
        _asset = _asset!.copyWith(zipMetadata: zipMetadata);
      }
    }

    // Load related assets (from cache if available)
    if (assetProvider.latestAssets.isEmpty) {
      await assetProvider.loadLatestAssets(limit: 4);
    }
    _relatedAssets = assetProvider.latestAssets.take(4).toList();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleDownload() async {
    if (_asset == null || _isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      // Use original filename if available, otherwise fall back to slug
      String defaultFileName = '${_asset!.slug}.zip';
      if (_asset!.zipMetadata?.originalName != null) {
        defaultFileName = _asset!.zipMetadata!.originalName!;
      }

      // Let user choose where to save the file with modal barrier
      final result = await _showModalSaveFilePicker(defaultFileName);

      if (result == null) {
        // User cancelled
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
        }
        return;
      }

      // Export the asset to the chosen location
      await services.storage.exportAsset(_asset!.zipPath, result);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Asset downloaded successfully to: $result'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download asset: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AssetProvider>(
      builder: (context, assetProvider, child) {
        final isLoading = assetProvider.isLoading || _asset == null;

        if (isLoading && !_dataLoaded) {
          return const AppScaffold(
            onExportAllData: handleExportAllData,
          onImportAllData: handleImportAllData,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_asset == null) {
          return AppScaffold(
            onExportAllData: handleExportAllData,
          onImportAllData: handleImportAllData,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Asset not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          );
        }

        return AppScaffold(
            onExportAllData: handleExportAllData,
          onImportAllData: handleImportAllData,
          currentRoute: '/asset/${_asset!.slug}',
          onNavigate: (route) => context.go(route),
          scrollController: _scrollController,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumbs
              _buildBreadcrumbs(),
              const SizedBox(height: AppConstants.spacingLg),

              // Asset main section
              _buildAssetMainSection(),
              const SizedBox(height: AppConstants.spacingXxl),

              // Tabs section (Description, Contents)
              _buildTabsSection(),
              const SizedBox(height: AppConstants.spacingXxl),

              // Related assets
              if (_relatedAssets.isNotEmpty) _buildRelatedAssets(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreadcrumbs() {
    return Breadcrumbs(
      items: [
        BreadcrumbItem(
          label: 'Home',
          onTap: () => context.go('/'),
        ),
        BreadcrumbItem(
          label: _asset!.category,
          onTap: () => context.go('/category/${_asset!.categorySlug}'),
        ),
        BreadcrumbItem(label: _asset!.title),
      ],
    );
  }

  Widget _buildAssetMainSection() {
    // Build list of images to display
    final List<String> images = [];

    // Add thumbnail path if available
    if (_asset!.thumbnailPath != null && _asset!.thumbnailPath!.isNotEmpty) {
      images.add(_asset!.thumbnailPath!);
    }

    // Add gallery images if any
    if (_asset!.galleryImages.isNotEmpty) {
      images.addAll(_asset!.galleryImages);
    }

    // Fallback to imageUrl if nothing else is available
    if (images.isEmpty && _asset!.imageUrl.isNotEmpty) {
      images.add(_asset!.imageUrl);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image gallery
        Expanded(
          flex: 5,
          child: AssetImageGallery(
            images: images,
          ),
        ),
        const SizedBox(width: AppConstants.spacingXl),

        // Asset info
        Expanded(
          flex: 5,
          child: _buildAssetInfo(),
        ),
      ],
    );
  }

  Widget _buildAssetInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          _asset!.title,
          style: AppTextStyles.headlineLarge,
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // Tags
        if (_asset!.tags.isNotEmpty) ...[
          _buildTagsList(),
          const SizedBox(height: AppConstants.spacingMd),
        ],

        // Features / bullet points
        if (_asset!.features.isNotEmpty) ...[
          _buildFeaturesList(),
          const SizedBox(height: AppConstants.spacingLg),
        ],

        // File info panel
        _buildFileInfoPanel(),
        const SizedBox(height: AppConstants.spacingLg),

        const Divider(),
        const SizedBox(height: AppConstants.spacingLg),

        // Download section
        _buildDownloadSection(),
        const SizedBox(height: AppConstants.spacingLg),

        // Category tag
        _buildCategoryTag(),
      ],
    );
  }

  Widget _buildTagsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _asset!.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            tag,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _asset!.features.take(5).map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature.title,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFileInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Column(
        children: [
          _buildInfoRow('File Size', _asset!.fileSizeFormatted),
          _buildInfoRow('Format', 'ZIP Archive'),
          _buildInfoRow('Created', _formatDate(_asset!.createdAt)),
          if (_asset!.lastUpdated != null)
            _buildInfoRow('Updated', _formatDate(_asset!.lastUpdated!)),
          if (_asset!.version != null)
            _buildInfoRow('Version', _asset!.version!),
          _buildInfoRow('Downloads', _asset!.downloadsCount.toString()),
          if (_asset!.zipMetadata != null)
            _buildInfoRow(
              'Files',
              '${_asset!.zipMetadata!.entryCount} items',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSection() {
    return Column(
      children: [
        // Download full ZIP
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isDownloading ? null : _handleDownload,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            label: Text(_isDownloading ? 'Downloading...' : 'Download ZIP'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingSm),
      ],
    );
  }

  Widget _buildCategoryTag() {
    return Row(
      children: [
        Text(
          'Category: ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/category/${_asset!.categorySlug}'),
            child: Text(
              _asset!.category,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabsSection() {
    return Column(
      children: [
        // Tab bar
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Description'),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spacingLg),

        // Tab content
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDescriptionTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _asset!.description,
            style: AppTextStyles.bodyLarge.copyWith(height: 1.8),
          ),
          if (_asset!.features.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingLg),
            Text('Features', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppConstants.spacingMd),
            ..._asset!.features.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.title,
                            style: AppTextStyles.titleSmall,
                          ),
                          if (feature.description != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                feature.description!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedAssets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Related Assets',
          subtitle: 'You might also like',
        ),
        AssetGrid(
          assets: _relatedAssets.take(4).toList(),
          onAssetTap: (asset) => context.go('/asset/${asset.slug}'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Shows a modal save file picker that prevents interaction with the main window
  Future<String?> _showModalSaveFilePicker(String defaultFileName) async {
    String? result;

    // Show a transparent barrier dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (BuildContext context) {
        // Launch the file picker immediately
        FilePicker.platform
            .saveFile(
          dialogTitle: 'Save ZIP file',
          fileName: defaultFileName,
          type: FileType.custom,
          allowedExtensions: ['zip'],
        )
            .then((value) {
          result = value;
          // Close the barrier dialog once picker returns
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });

        // Show a semi-transparent overlay with loading indicator
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Choosing save location...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result;
  }
}
