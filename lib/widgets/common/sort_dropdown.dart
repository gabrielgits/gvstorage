import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

/// Sort dropdown for product listings
class SortDropdown extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String>? onChanged;
  final List<Map<String, String>>? options;

  const SortDropdown({
    super.key,
    required this.selectedValue,
    this.onChanged,
    this.options,
  });

  @override
  Widget build(BuildContext context) {
    final sortOptions = options ?? AppConstants.sortOptions;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String>(
        value: selectedValue,
        onChanged: (value) {
          if (value != null) onChanged?.call(value);
        },
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
        style: AppTextStyles.bodyMedium,
        dropdownColor: AppColors.cardBackground,
        items: sortOptions.map((option) {
          return DropdownMenuItem<String>(
            value: option['value'],
            child: Text(option['label']!),
          );
        }).toList(),
      ),
    );
  }
}

/// View mode toggle (grid/list)
class ViewModeToggle extends StatelessWidget {
  final ViewMode currentMode;
  final ValueChanged<ViewMode>? onChanged;

  const ViewModeToggle({
    super.key,
    required this.currentMode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.grid_view,
            mode: ViewMode.grid,
          ),
          _buildToggleButton(
            icon: Icons.view_list,
            mode: ViewMode.list,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required ViewMode mode,
  }) {
    final isActive = currentMode == mode;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged?.call(mode),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusSm - 1),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? AppColors.textOnPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

enum ViewMode { grid, list }
