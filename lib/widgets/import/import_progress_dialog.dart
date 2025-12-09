import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/import_progress.dart';

/// Dialog showing real-time import progress
class ImportProgressDialog extends StatefulWidget {
  final Stream<ImportProgress> progressStream;
  final VoidCallback onCancel;

  const ImportProgressDialog({
    super.key,
    required this.progressStream,
    required this.onCancel,
  });

  @override
  State<ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<ImportProgressDialog> {
  ImportProgress? _currentProgress;
  bool _isCancelling = false;

  Future<void> _handleCancel() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Import?'),
        content: const Text(
          'Are you sure you want to cancel the import? Progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Import'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Cancel Import'),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      setState(() {
        _isCancelling = true;
      });
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissing with back button or escape
      child: AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.download,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            const Text(
              'Importing Data',
              style: AppTextStyles.headlineSmall,
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: StreamBuilder<ImportProgress>(
            stream: widget.progressStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _currentProgress = snapshot.data;
              }

              if (_currentProgress == null) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppConstants.spacingMd),
                    Text('Initializing import...'),
                  ],
                );
              }

              final progress = _currentProgress!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase label
                  Text(
                    progress.phase.label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),

                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: progress.percentage,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 8,
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${progress.percentageInt}%',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${progress.processedItems} / ${progress.totalItems} items',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.spacingLg),

                  // Asset count (if in assets phase)
                  if (progress.phase == ImportPhase.importingAssets) ...[
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingMd),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_2,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppConstants.spacingSm),
                          Text(
                            'Assets:',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${progress.processedAssets} / ${progress.totalAssets}',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                  ],

                  // Current item
                  Text(
                    'Current:',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress.currentItem,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Error message (if any)
                  if (progress.hasError) ...[
                    const SizedBox(height: AppConstants.spacingMd),
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingSm),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                        border: Border.all(
                          color: AppColors.error.withAlpha((255 * 0.3).round()),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppConstants.spacingSm),
                          Expanded(
                            child: Text(
                              progress.errorMessage!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Cancelling message
                  if (_isCancelling) ...[
                    const SizedBox(height: AppConstants.spacingMd),
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingSm),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: AppConstants.spacingSm),
                          Text(
                            'Cancelling import...',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        actions: [
          if (!_isCancelling)
            TextButton(
              onPressed: _handleCancel,
              child: Text(
                'Cancel',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
