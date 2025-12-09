import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive_io.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

/// Dialog for initiating import all data operation
class ImportAllDialog extends StatefulWidget {
  const ImportAllDialog({super.key});

  @override
  State<ImportAllDialog> createState() => _ImportAllDialogState();
}

class _ImportAllDialogState extends State<ImportAllDialog> {
  bool _isLoading = false;
  String? _selectedArchivePath;
  Map<String, dynamic>? _archiveMetadata;
  String? _errorMessage;

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

  Future<void> _selectArchive() async {
    setState(() {
      _errorMessage = null;
    });

    // Show file picker for archive selection
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Import Archive',
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.single.path == null) {
      // User cancelled
      return;
    }

    final archivePath = result.files.single.path!;

    setState(() {
      _isLoading = true;
      _selectedArchivePath = archivePath;
      _archiveMetadata = null;
      _errorMessage = null;
    });

    // Extract and validate archive metadata
    try {
      final metadata = await _extractArchiveMetadata(archivePath);

      if (mounted) {
        setState(() {
          _archiveMetadata = metadata;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _selectedArchivePath = null;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _extractArchiveMetadata(String archivePath) async {
    final archiveFile = File(archivePath);

    if (!archiveFile.existsSync()) {
      throw Exception('Archive file not found');
    }

    // Get file size
    final fileSize = archiveFile.lengthSync();

    // Read and extract database.json
    try {
      final bytes = await archiveFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find database.json
      final databaseJsonFile = archive.files.firstWhere(
        (file) => file.name == 'database.json',
        orElse: () => throw Exception('database.json not found in archive'),
      );

      // Extract and parse database.json
      final jsonContent = utf8.decode(databaseJsonFile.content as List<int>);
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      // Validate structure
      if (!data.containsKey('metadata')) {
        throw Exception('Invalid archive: missing metadata');
      }

      final metadata = data['metadata'] as Map<String, dynamic>;

      return {
        'totalAssets': metadata['totalAssets'] ?? 0,
        'totalCategories': metadata['totalCategories'] ?? 0,
        'totalTags': metadata['totalTags'] ?? 0,
        'archiveSize': fileSize,
        'exportedAt': metadata['exportedAt'] ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to read archive: $e');
    }
  }

  Future<void> _handleImport() async {
    if (_selectedArchivePath == null) {
      return;
    }

    // Close this dialog and return the archive path
    if (mounted) {
      Navigator.of(context).pop(_selectedArchivePath);
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
            'Import All Data',
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
              'Import a complete backup of your GvStorage library from an export archive.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppConstants.spacingLg),

            // File selection button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _selectArchive,
              icon: const Icon(Icons.folder_open),
              label: Text(_selectedArchivePath == null
                  ? 'Select Archive...'
                  : 'Change Archive...'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withAlpha((255 * 0.1).round()),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLg,
                  vertical: AppConstants.spacingMd,
                ),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: AppConstants.spacingLg),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Center(
                child: Text(
                  'Reading archive...',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: AppConstants.spacingLg),
              Container(
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
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_archiveMetadata != null) ...[
              const SizedBox(height: AppConstants.spacingLg),
              Text(
                'Archive Preview:',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.spacingMd),
              _buildInfoRow(
                Icons.inventory_2,
                'Total Assets',
                _archiveMetadata!['totalAssets'].toString(),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              _buildInfoRow(
                Icons.folder,
                'Categories',
                _archiveMetadata!['totalCategories'].toString(),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              _buildInfoRow(
                Icons.label,
                'Tags',
                _archiveMetadata!['totalTags'].toString(),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              _buildInfoRow(
                Icons.storage,
                'Archive Size',
                _formatBytes(_archiveMetadata!['archiveSize'] as int),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha((255 * 0.1).round()),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(
                    color: AppColors.warning.withAlpha((255 * 0.3).round()),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Expanded(
                      child: Text(
                        'Existing assets with duplicate slugs will require conflict resolution.',
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
        if (_archiveMetadata != null && !_isLoading)
          ElevatedButton(
            onPressed: _handleImport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingLg,
                vertical: AppConstants.spacingMd,
              ),
            ),
            child: const Text('Import'),
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
