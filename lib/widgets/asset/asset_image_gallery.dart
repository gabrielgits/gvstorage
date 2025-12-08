import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/service_locator.dart';

/// Asset image gallery with thumbnail navigation
class AssetImageGallery extends StatefulWidget {
  final List<String> images;
  final double imageSize;
  final double thumbnailSize;

  const AssetImageGallery({
    super.key,
    required this.images,
    this.imageSize = 500,
    this.thumbnailSize = 80,
  });

  @override
  State<AssetImageGallery> createState() => _AssetImageGalleryState();
}

class _AssetImageGalleryState extends State<AssetImageGallery> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return _buildPlaceholder();
    }

    return Column(
      children: [
        // Main image
        _buildMainImage(),
        const SizedBox(height: AppConstants.spacingMd),

        // Thumbnails
        if (widget.images.length > 1) _buildThumbnails(),
      ],
    );
  }

  Widget _buildMainImage() {
    return Container(
      width: widget.imageSize,
      height: widget.imageSize,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            return _buildImage(widget.images[index], BoxFit.contain);
          },
        ),
      ),
    );
  }

  Widget _buildThumbnails() {
    return SizedBox(
      height: widget.thumbnailSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.images.length,
          (index) => _buildThumbnail(index),
        ),
      ),
    );
  }

  Widget _buildThumbnail(int index) {
    final isSelected = index == _selectedIndex;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        _pageController.animateToPage(
          index,
          duration: AppConstants.animationNormal,
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: widget.thumbnailSize,
        height: widget.thumbnailSize,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          child: _buildImage(widget.images[index], BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildImage(String imagePath, BoxFit fit) {
    // Check if the path is a URL (http/https) or a file path
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildImageError(),
      );
    } else {
      // Treat as a file path - convert relative path to absolute
      final absolutePath = services.storage.getAbsolutePath(imagePath);
      return Image.file(
        File(absolutePath),
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildImageError(),
      );
    }
  }

  Widget _buildImageError() {
    return Container(
      color: AppColors.surface,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textHint,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.imageSize,
      height: widget.imageSize,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_zip_outlined,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'No Preview',
              style: TextStyle(
                color: AppColors.textHint.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
