import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

/// Pagination widget for product listings
class Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int>? onPageChanged;
  final int visiblePages;

  const Pagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.totalItems = 0,
    this.itemsPerPage = AppConstants.itemsPerPage,
    this.onPageChanged,
    this.visiblePages = 5,
  });

  int get startItem => ((currentPage - 1) * itemsPerPage) + 1;
  int get endItem => (currentPage * itemsPerPage).clamp(0, totalItems);

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Column(
      children: [
        // Results info
        if (totalItems > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
            child: Text(
              'Showing $startItem–$endItem of $totalItems results',
              style: AppTextStyles.bodySmall,
            ),
          ),

        // Page buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous button
            _buildNavButton(
              icon: Icons.chevron_left,
              onTap: currentPage > 1 ? () => onPageChanged?.call(currentPage - 1) : null,
            ),

            const SizedBox(width: AppConstants.spacingSm),

            // Page numbers
            ..._buildPageNumbers(),

            const SizedBox(width: AppConstants.spacingSm),

            // Next button
            _buildNavButton(
              icon: Icons.chevron_right,
              onTap: currentPage < totalPages ? () => onPageChanged?.call(currentPage + 1) : null,
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers() {
    final pages = <Widget>[];
    final half = visiblePages ~/ 2;

    int start = (currentPage - half).clamp(1, totalPages);
    int end = (start + visiblePages - 1).clamp(1, totalPages);

    if (end - start < visiblePages - 1) {
      start = (end - visiblePages + 1).clamp(1, totalPages);
    }

    // First page and ellipsis
    if (start > 1) {
      pages.add(_buildPageButton(1));
      if (start > 2) {
        pages.add(_buildEllipsis());
      }
    }

    // Visible page numbers
    for (int i = start; i <= end; i++) {
      pages.add(_buildPageButton(i));
    }

    // Last page and ellipsis
    if (end < totalPages) {
      if (end < totalPages - 1) {
        pages.add(_buildEllipsis());
      }
      pages.add(_buildPageButton(totalPages));
    }

    return pages;
  }

  Widget _buildPageButton(int page) {
    final isActive = page == currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: isActive ? null : () => onPageChanged?.call(page),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Center(
              child: Text(
                page.toString(),
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive ? AppColors.textOnPrimary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled ? AppColors.textPrimary : AppColors.textHint,
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}
