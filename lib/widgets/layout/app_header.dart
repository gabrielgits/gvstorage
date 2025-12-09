import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/category.dart';
import '../../services/service_locator.dart';

/// Main application header with navigation and search
class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onUploadTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onExportAllData;
  final VoidCallback? onImportAllData;
  final String? currentRoute;
  final Function(String)? onNavigate;

  const AppHeader({
    super.key,
    this.onMenuTap,
    this.onUploadTap,
    this.onSearchTap,
    this.onExportAllData,
    this.onImportAllData,
    this.currentRoute,
    this.onNavigate,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(AppConstants.headerHeight);
}

class _AppHeaderState extends State<AppHeader> {
  List<Category> _topCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopCategories();
  }

  Future<void> _loadTopCategories() async {
    try {
      final categories = await services.category.getCategories();
      if (mounted) {
        setState(() {
          _topCategories = categories.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool get _isUploadRoute => widget.currentRoute == '/upload';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.headerHeight,
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
        child: Row(
          children: [
            // Logo
            _buildLogo(),
            const SizedBox(width: AppConstants.spacingXl),

            // Navigation
            Expanded(child: _buildNavigation()),

            // File menu
            _buildFileMenu(),
            const SizedBox(width: AppConstants.spacingSm),

            // Upload button
            _buildUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileMenu() {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.menu,
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
      tooltip: 'File Menu',
      onSelected: (value) {
        if (value == 'export_all') {
          widget.onExportAllData?.call();
        } else if (value == 'import_all') {
          widget.onImportAllData?.call();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'import_all',
          child: Row(
            children: [
              Icon(Icons.download, size: 20, color: AppColors.primary),
              SizedBox(width: AppConstants.spacingSm),
              Text('Import All Data'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'export_all',
          child: Row(
            children: [
              Icon(Icons.backup, size: 20, color: AppColors.primary),
              SizedBox(width: AppConstants.spacingSm),
              Text('Export All Data'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'settings',
          enabled: false,
          child: Row(
            children: [
              Icon(Icons.settings, size: 20, color: AppColors.textHint),
              SizedBox(width: AppConstants.spacingSm),
              Text('Settings', style: TextStyle(color: AppColors.textHint)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onNavigate?.call('/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.folder_zip,
                color: AppColors.textOnPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'GvStorage',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // All Assets link
        _NavItem(
          title: 'All Assets',
          isActive: widget.currentRoute == '/assets',
          onTap: () => widget.onNavigate?.call('/assets'),
        ),
        // First 3 categories
        ..._topCategories.map((category) {
          final route = '/category/${category.slug}';
          return _NavItem(
            title: category.name,
            isActive: widget.currentRoute == route,
            onTap: () => widget.onNavigate?.call(route),
          );
        }),
      ],
    );
  }

  Widget _buildUploadButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isUploadRoute ? null : widget.onUploadTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingSm,
          ),
          decoration: BoxDecoration(
            gradient: _isUploadRoute ? null : AppColors.primaryGradient,
            color: _isUploadRoute ? AppColors.surface : null,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: _isUploadRoute
                ? Border.all(color: AppColors.primary)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.upload_file,
                color: _isUploadRoute
                    ? AppColors.primary
                    : AppColors.textOnPrimary,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                'Upload',
                style: AppTextStyles.labelLarge.copyWith(
                  color: _isUploadRoute
                      ? AppColors.primary
                      : AppColors.textOnPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String title;
  final bool isActive;
  final VoidCallback? onTap;

  const _NavItem({
    required this.title,
    this.isActive = false,
    this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
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
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isActive || _isHovered
                    ? AppColors.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            widget.title,
            style: widget.isActive
                ? AppTextStyles.navItemActive
                : AppTextStyles.navItem.copyWith(
                    color: _isHovered
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}
