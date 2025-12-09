import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

/// Dialog showing successful export completion
class ExportCompleteDialog extends StatelessWidget {
  final String exportPath;
  final int totalAssets;
  final int totalFiles;

  const ExportCompleteDialog({
    super.key,
    required this.exportPath,
    required this.totalAssets,
    required this.totalFiles,
  });

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

  Future<String> _getFileSize() async {
    try {
      final file = File(exportPath);
      if (await file.exists()) {
        final size = await file.length();
        return _formatBytes(size);
      }
    } catch (e) {
      // Ignore errors
    }
    return 'Unknown';
  }

  Future<void> _openFolder() async {
    try {
      final directory = path_pkg.dirname(exportPath);
      final uri = Uri.directory(directory);

      // Platform-specific folder opening
      if (Platform.isLinux) {
        await Process.run('xdg-open', [directory]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [directory]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [directory]);
      } else {
        // Fallback to URL launcher
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      // Silently fail if we can't open the folder
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
              color: AppColors.success.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          const Text(
            'Export Complete',
            style: AppTextStyles.headlineSmall,
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your data has been successfully exported!',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // Export summary
            _buildInfoRow(Icons.folder_zip, 'Assets Exported', '$totalAssets'),
            const SizedBox(height: AppConstants.spacingSm),
            _buildInfoRow(Icons.insert_drive_file, 'Total Files', '$totalFiles'),
            const SizedBox(height: AppConstants.spacingSm),
            FutureBuilder<String>(
              future: _getFileSize(),
              builder: (context, snapshot) {
                return _buildInfoRow(
                  Icons.storage,
                  'Archive Size',
                  snapshot.data ?? 'Calculating...',
                );
              },
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // Export location
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Location:',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Expanded(
                        child: Text(
                          exportPath,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontFamily: 'monospace',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingLg),

            // Info message
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
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      'Keep this export file safe. It contains all your assets and metadata.',
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
            'Close',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            _openFolder();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLg,
              vertical: AppConstants.spacingMd,
            ),
          ),
          icon: const Icon(Icons.folder_open, size: 18),
          label: const Text('Open Folder'),
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
