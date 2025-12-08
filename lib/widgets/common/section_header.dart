import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

/// Section header with optional view all link
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? viewAllText;
  final VoidCallback? onViewAll;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.viewAllText,
    this.onViewAll,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Trailing widget or View All link
          if (trailing != null)
            trailing!
          else if (viewAllText != null && onViewAll != null)
            _ViewAllLink(
              text: viewAllText!,
              onTap: onViewAll!,
            ),
        ],
      ),
    );
  }
}

class _ViewAllLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _ViewAllLink({
    required this.text,
    required this.onTap,
  });

  @override
  State<_ViewAllLink> createState() => _ViewAllLinkState();
}

class _ViewAllLinkState extends State<_ViewAllLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
                decoration: _isHovered ? TextDecoration.underline : null,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Breadcrumb navigation
class Breadcrumbs extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const Breadcrumbs({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items.length - 1;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BreadcrumbLink(
              text: item.label,
              onTap: isLast ? null : item.onTap,
              isActive: isLast,
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({
    required this.label,
    this.onTap,
  });
}

class _BreadcrumbLink extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isActive;

  const _BreadcrumbLink({
    required this.text,
    this.onTap,
    this.isActive = false,
  });

  @override
  State<_BreadcrumbLink> createState() => _BreadcrumbLinkState();
}

class _BreadcrumbLinkState extends State<_BreadcrumbLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isClickable = widget.onTap != null && !widget.isActive;

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: AppTextStyles.bodySmall.copyWith(
            color: widget.isActive
                ? AppColors.textPrimary
                : (_isHovered ? AppColors.primary : AppColors.textSecondary),
            fontWeight: widget.isActive ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
