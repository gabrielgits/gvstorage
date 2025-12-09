import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/import_result.dart';

/// Dialog for resolving asset conflicts during import
class ConflictResolutionDialog extends StatefulWidget {
  final String assetSlug;
  final String assetTitle;
  final Map<String, dynamic> existingAssetData;
  final Map<String, dynamic> incomingAssetData;

  const ConflictResolutionDialog({
    super.key,
    required this.assetSlug,
    required this.assetTitle,
    required this.existingAssetData,
    required this.incomingAssetData,
  });

  @override
  State<ConflictResolutionDialog> createState() =>
      _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  ConflictResolutionAction? _selectedAction;
  final TextEditingController _newSlugController = TextEditingController();
  String? _slugError;

  @override
  void dispose() {
    _newSlugController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _generateSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  void _validateNewSlug() {
    final newSlug = _newSlugController.text.trim();

    if (newSlug.isEmpty) {
      setState(() {
        _slugError = 'Slug cannot be empty';
      });
      return;
    }

    final validSlug = _generateSlug(newSlug);
    if (validSlug != newSlug) {
      setState(() {
        _slugError = 'Invalid slug format. Use lowercase letters, numbers, and hyphens only.';
      });
      return;
    }

    setState(() {
      _slugError = null;
    });
  }

  void _handleSkip() {
    Navigator.of(context).pop(
      const ConflictResolution(action: ConflictResolutionAction.skip),
    );
  }

  void _handleOverwrite() {
    Navigator.of(context).pop(
      const ConflictResolution(action: ConflictResolutionAction.overwrite),
    );
  }

  void _handleRename() {
    _validateNewSlug();

    if (_slugError != null) {
      return;
    }

    final newSlug = _newSlugController.text.trim();
    Navigator.of(context).pop(
      ConflictResolution(
        action: ConflictResolutionAction.rename,
        newSlug: newSlug,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          const Expanded(
            child: Text(
              'Duplicate Asset Detected',
              style: AppTextStyles.headlineSmall,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'An asset with the slug "${widget.assetSlug}" already exists in your library. Choose how to handle this conflict:',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // Comparison Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Existing Asset
                  Expanded(
                    child: _buildAssetCard(
                      'Existing Asset',
                      widget.existingAssetData,
                      AppColors.error,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  // Incoming Asset
                  Expanded(
                    child: _buildAssetCard(
                      'Incoming Asset',
                      widget.incomingAssetData,
                      AppColors.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacingLg),
              const Divider(),
              const SizedBox(height: AppConstants.spacingLg),

              // Action Selection
              Text(
                'Choose Action:',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              // Skip Option
              _buildActionOption(
                ConflictResolutionAction.skip,
                'Skip',
                'Skip importing this asset. The existing asset will remain unchanged.',
                Icons.cancel_outlined,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // Overwrite Option
              _buildActionOption(
                ConflictResolutionAction.overwrite,
                'Overwrite',
                'Replace the existing asset with the incoming one. This cannot be undone.',
                Icons.swap_horiz,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // Rename Option
              _buildActionOption(
                ConflictResolutionAction.rename,
                'Rename',
                'Import the asset with a new slug. Both assets will exist.',
                Icons.drive_file_rename_outline,
              ),

              // Rename Input (shown when rename is selected)
              if (_selectedAction == ConflictResolutionAction.rename) ...[
                const SizedBox(height: AppConstants.spacingMd),
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha((255 * 0.05).round()),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: AppColors.primary.withAlpha((255 * 0.2).round()),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Slug:',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
                      TextField(
                        controller: _newSlugController,
                        decoration: InputDecoration(
                          hintText: '${widget.assetSlug}-imported',
                          errorText: _slugError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingMd,
                            vertical: AppConstants.spacingSm,
                          ),
                        ),
                        onChanged: (_) {
                          if (_slugError != null) {
                            _validateNewSlug();
                          }
                        },
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
                      Text(
                        'Use lowercase letters, numbers, and hyphens only.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _handleSkip,
          child: Text(
            'Skip This Asset',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Spacer(),
        if (_selectedAction == ConflictResolutionAction.skip)
          ElevatedButton(
            onPressed: _handleSkip,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textSecondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Skip'),
          ),
        if (_selectedAction == ConflictResolutionAction.overwrite)
          ElevatedButton(
            onPressed: _handleOverwrite,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('Overwrite'),
          ),
        if (_selectedAction == ConflictResolutionAction.rename)
          ElevatedButton(
            onPressed: _handleRename,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Rename & Import'),
          ),
      ],
    );
  }

  Widget _buildAssetCard(
    String title,
    Map<String, dynamic> assetData,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: accentColor.withAlpha((255 * 0.05).round()),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: accentColor.withAlpha((255 * 0.2).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2,
                size: 16,
                color: accentColor,
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMd),
          _buildAssetDetail('Title', assetData['title'] as String? ?? 'Unknown'),
          _buildAssetDetail('Category', assetData['categoryName'] as String? ?? assetData['category'] as String? ?? 'Unknown'),
          _buildAssetDetail(
            'Size',
            _formatBytes(assetData['file_size'] as int? ?? assetData['fileSize'] as int? ?? 0),
          ),
          _buildAssetDetail(
            'Created',
            _formatDate(assetData['created_at'] as int? ?? assetData['createdAt'] as int? ?? 0),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionOption(
    ConflictResolutionAction action,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedAction == action;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAction = action;
          if (action == ConflictResolutionAction.rename) {
            _newSlugController.text = '${widget.assetSlug}-imported';
          }
        });
      },
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha((255 * 0.1).round()) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<ConflictResolutionAction>(
              value: action,
              groupValue: _selectedAction,
              onChanged: (value) {
                setState(() {
                  _selectedAction = value;
                  if (value == ConflictResolutionAction.rename) {
                    _newSlugController.text = '${widget.assetSlug}-imported';
                  }
                });
              },
            ),
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
