import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../services/service_locator.dart';

/// Dialog for initiating export all data operation
class ExportAllDialog extends StatefulWidget {
  const ExportAllDialog({super.key});

  @override
  State<ExportAllDialog> createState() => _ExportAllDialogState();
}

class _ExportAllDialogState extends State<ExportAllDialog> {
  bool _isLoading = true;
  int _totalAssets = 0;
  int _estimatedSizeBytes = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExportInfo();
  }

  Future<void> _loadExportInfo() async {
    try {
      final assetCount = await services.asset.getTotalAssetCount();
      // Estimate size: sum of all asset file sizes
      final results = await services.database.query('assets', columns: ['file_size']);
      int estimatedSize = 0;
      for (final row in results) {
        estimatedSize += (row['file_size'] as int? ?? 0);
      }
      // Add estimate for thumbnails and JSON
      estimatedSize += results.length * 500000; // 500KB per thumbnail estimate
      estimatedSize += 10485760; // 10MB for database JSON estimate

      if (mounted) {
        setState(() {
          _totalAssets = assetCount;
          _estimatedSizeBytes = estimatedSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to calculate export size: $e';
          _isLoading = false;
        });
      }
    }
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

  Future<void> _handleExport() async {
    // Show file picker for destination
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Select Export Location',
      fileName: 'gvstorage-export-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.zip',
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null) {
      // User cancelled
      return;
    }

    // Ensure .zip extension
    String destinationPath = result;
    if (!destinationPath.toLowerCase().endsWith('.zip')) {
      destinationPath += '.zip';
    }

    // Close this dialog and return the destination path
    if (mounted) {
      Navigator.of(context).pop(destinationPath);
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
              color: AppColors.primary.withOpacity(0.1),
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
            'Export All Data',
            style: AppTextStyles.headlineSmall,
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.spacingXl),
                  child: CircularProgressIndicator(),
                ),
              )
            : _errorMessage != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: AppConstants.spacingMd),
                      Text(
                        _errorMessage!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This will create a complete backup of your GvStorage library including all assets, metadata, and settings.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppConstants.spacingLg),
                      _buildInfoRow(
                        Icons.folder_zip,
                        'Total Assets',
                        _totalAssets.toString(),
                      ),
                      const SizedBox(height: AppConstants.spacingSm),
                      _buildInfoRow(
                        Icons.storage,
                        'Estimated Size',
                        _formatBytes(_estimatedSizeBytes),
                      ),
                      const SizedBox(height: AppConstants.spacingLg),
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: AppConstants.spacingSm),
                            Expanded(
                              child: Text(
                                'Ensure you have enough disk space before proceeding.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (!_isLoading && _errorMessage == null)
          ElevatedButton(
            onPressed: _handleExport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingLg,
                vertical: AppConstants.spacingMd,
              ),
            ),
            child: const Text('Export...'),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
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
          ),
        ),
      ],
    );
  }
}
