import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

/// Dialog showing import completion summary
class ImportCompleteDialog extends StatefulWidget {
  final int totalAssets;
  final int successfulAssets;
  final int failedAssets;
  final int skippedAssets;
  final int categoriesImported;
  final int tagsImported;
  final Map<String, String> errors;

  const ImportCompleteDialog({
    super.key,
    required this.totalAssets,
    required this.successfulAssets,
    required this.failedAssets,
    required this.skippedAssets,
    required this.categoriesImported,
    required this.tagsImported,
    required this.errors,
  });

  @override
  State<ImportCompleteDialog> createState() => _ImportCompleteDialogState();
}

class _ImportCompleteDialogState extends State<ImportCompleteDialog> {
  bool _showErrors = false;

  IconData get _statusIcon {
    if (widget.failedAssets == 0 && widget.skippedAssets == 0) {
      return Icons.check_circle;
    } else if (widget.successfulAssets > 0) {
      return Icons.warning_amber;
    } else {
      return Icons.error;
    }
  }

  Color get _statusColor {
    if (widget.failedAssets == 0 && widget.skippedAssets == 0) {
      return AppColors.success;
    } else if (widget.successfulAssets > 0) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  String get _statusTitle {
    if (widget.failedAssets == 0 && widget.skippedAssets == 0) {
      return 'Import Complete';
    } else if (widget.successfulAssets > 0) {
      return 'Import Partially Complete';
    } else {
      return 'Import Failed';
    }
  }

  String get _statusMessage {
    if (widget.failedAssets == 0 && widget.skippedAssets == 0) {
      return 'All assets were successfully imported!';
    } else if (widget.successfulAssets > 0) {
      return 'Some assets were imported, but there were issues with others.';
    } else {
      return 'No assets were imported due to errors or cancellation.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _statusColor.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _statusIcon,
              color: _statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Text(
              _statusTitle,
              style: AppTextStyles.headlineSmall,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _statusMessage,
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppConstants.spacingLg),

              // Import summary
              Text(
                'Import Summary:',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),

              _buildInfoRow(
                Icons.check_circle_outline,
                'Successful Assets',
                '${widget.successfulAssets}',
                AppColors.success,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              _buildInfoRow(
                Icons.error_outline,
                'Failed Assets',
                '${widget.failedAssets}',
                AppColors.error,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              _buildInfoRow(
                Icons.cancel_outlined,
                'Skipped Assets',
                '${widget.skippedAssets}',
                AppColors.warning,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              _buildInfoRow(
                Icons.folder_outlined,
                'Categories Imported',
                '${widget.categoriesImported}',
                AppColors.primary,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              _buildInfoRow(
                Icons.label_outlined,
                'Tags Imported',
                '${widget.tagsImported}',
                AppColors.primary,
              ),

              // Failed assets details
              if (widget.errors.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacingLg),
                InkWell(
                  onTap: () {
                    setState(() {
                      _showErrors = !_showErrors;
                    });
                  },
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha((255 * 0.1).round()),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                      border: Border.all(
                        color: AppColors.error.withAlpha((255 * 0.3).round()),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _showErrors ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        Expanded(
                          child: Text(
                            'View Error Details (${widget.errors.length} ${widget.errors.length == 1 ? 'error' : 'errors'})',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showErrors) ...[
                  const SizedBox(height: AppConstants.spacingMd),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.errors.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: AppConstants.spacingMd,
                      ),
                      itemBuilder: (context, index) {
                        final entry = widget.errors.entries.elementAt(index);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.inventory_2,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: AppConstants.spacingSm),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 24,
                              ),
                              child: Text(
                                entry.value,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],

              // Info message
              if (widget.successfulAssets > 0) ...[
                const SizedBox(height: AppConstants.spacingLg),
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.info.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(
                      color: AppColors.info.withAlpha((255 * 0.3).round()),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: Text(
                          'Imported assets are now available in your library.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (widget.successfulAssets > 0)
          ElevatedButton(
            onPressed: () {
              // Close dialog and navigate to home
              Navigator.of(context).pop(true); // Return true to indicate view library
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingLg,
                vertical: AppConstants.spacingMd,
              ),
            ),
            child: const Text('View Library'),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: AppConstants.spacingSm),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
