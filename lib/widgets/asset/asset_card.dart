import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/asset.dart';
import '../../services/service_locator.dart';

/// Asset card widget for grid display
class AssetCard extends StatefulWidget {
  final Asset asset;
  final VoidCallback? onTap;

  const AssetCard({
    super.key,
    required this.asset,
    this.onTap,
  });

  @override
  State<AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<AssetCard> {
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
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppColors.cardShadow.withValues(alpha: 0.2)
                    : AppColors.cardShadow,
                blurRadius: _isHovered ? 12 : 4,
                offset: Offset(0, _isHovered ? 6 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image section
              _buildImageSection(),

              // Content section
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.asset.title,
                      style: AppTextStyles.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.spacingSm),

                    // Category
                    Text(
                      widget.asset.category,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),

                    // Metadata section (file size, version, downloads)
                    _buildMetadataSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Asset thumbnail
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusMd),
          ),
          child: AspectRatio(
            aspectRatio: 1.4,
            child: Container(
              color: AppColors.surface,
              child: widget.asset.thumbnailPath != null
                  ? Image.file(
                      File(services.storage.getAbsolutePath(widget.asset.thumbnailPath!)),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
        ),

        // Featured badge
        if (widget.asset.isFeatured)
          Positioned(
            top: AppConstants.spacingSm,
            left: AppConstants.spacingSm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Featured',
                style: AppTextStyles.badge,
              ),
            ),
          ),

        // ZIP icon indicator
        Positioned(
          top: AppConstants.spacingSm,
          right: AppConstants.spacingSm,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.folder_zip_outlined,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Image.asset(
      'assets/images/asset_placeholder.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if asset image fails to load
        return Center(
          child: Icon(
            Icons.folder_zip_outlined,
            size: 48,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
        );
      },
    );
  }

  Widget _buildMetadataSection() {
    return Row(
      children: [
        // File size badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.asset.fileSizeFormatted,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Version badge
        if (widget.asset.hasVersion)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'v${widget.asset.version}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),

        const Spacer(),

        // Download count
        Row(
          children: [
            Icon(
              Icons.download_outlined,
              size: 14,
              color: AppColors.textHint,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDownloadCount(widget.asset.downloadsCount),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDownloadCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}
