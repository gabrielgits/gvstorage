import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/export_progress.dart';

/// Dialog showing real-time export progress
class ExportProgressDialog extends StatefulWidget {
  final Stream<ExportProgress> progressStream;
  final VoidCallback onCancel;

  const ExportProgressDialog({
    super.key,
    required this.progressStream,
    required this.onCancel,
  });

  @override
  State<ExportProgressDialog> createState() => _ExportProgressDialogState();
}

class _ExportProgressDialogState extends State<ExportProgressDialog> {
  ExportProgress? _currentProgress;
  bool _isCancelling = false;

  Future<void> _handleCancel() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Export?'),
        content: const Text(
          'Are you sure you want to cancel the export? Progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Export'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Cancel Export'),
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
                Icons.backup,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            const Text(
              'Exporting Data',
              style: AppTextStyles.headlineSmall,
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: StreamBuilder<ExportProgress>(
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
                    Text('Initializing export...'),
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
                            '${progress.processedFiles} / ${progress.totalFiles} files',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: AppConstants.spacingLg),

                  // Current file
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insert_drive_file,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        Expanded(
                          child: Text(
                            progress.currentFile,
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.spacingMd),

                  // Asset progress (if applicable)
                  if (progress.totalAssets > 0)
                    Text(
                      'Assets: ${progress.processedAssets} / ${progress.totalAssets}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          if (_isCancelling)
            const Padding(
              padding: EdgeInsets.all(AppConstants.spacingMd),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppConstants.spacingSm),
                  Text('Cancelling...'),
                ],
              ),
            )
          else
            TextButton(
              onPressed: _handleCancel,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }
}
