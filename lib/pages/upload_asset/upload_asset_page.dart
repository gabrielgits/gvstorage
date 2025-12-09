import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/upload_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/common/common.dart';
import '../../widgets/layout/layout.dart';
import '../../main.dart' show handleExportAllData, handleImportAllData;

/// Upload asset page with multi-step form
class UploadAssetPage extends StatefulWidget {
  const UploadAssetPage({super.key});

  @override
  State<UploadAssetPage> createState() => _UploadAssetPageState();
}

class _UploadAssetPageState extends State<UploadAssetPage> {
  final ScrollController _scrollController = ScrollController();
  final _tagController = TextEditingController();
  final _titleController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _versionController = TextEditingController();
  final _lastUpdatedController = TextEditingController();
  final _demoUrlController = TextEditingController();

  bool _dataLoaded = false;
  bool _isLoadingCategories = false;
  bool _isUploading = false;

  int _currentStep = 0;
  String? _errorMessage;

  // Step 1: File selection
  File? _selectedZipFile;
  int? _fileSize;
  int? _entryCount;

  // Step 2: Information
  String? _selectedCategoryId;
  List<Category> _categories = [];
  final List<String> _selectedTags = [];

  // Step 3: Images
  File? _thumbnail;
  final List<File> _galleryImages = [];

  // Last updated date
  DateTime? _selectedLastUpdated;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Load categories once - defer to after build completes
    if (!_dataLoaded) {
      _dataLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadCategories();
        }
      });
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categoryProvider = context.read<CategoryProvider>();
      if (categoryProvider.categories.isEmpty) {
        await categoryProvider.loadCategories();
      }
      if (mounted) {
        setState(() {
          _categories = categoryProvider.categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          _errorMessage = 'Failed to load categories: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tagController.dispose();
    _titleController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _versionController.dispose();
    _lastUpdatedController.dispose();
    _demoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UploadProvider, CategoryProvider>(
      builder: (context, uploadProvider, categoryProvider, child) {
        return AppScaffold(
          currentRoute: '/upload',
          onNavigate: (route) => context.go(route),
          onUploadTap: () => context.go('/upload'),
          onExportAllData: handleExportAllData,
          onImportAllData: handleImportAllData,
          scrollController: _scrollController,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumbs
              _buildBreadcrumbs(),
              const SizedBox(height: AppConstants.spacingMd),

              // Page header
              Text('Upload New Asset', style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'Add a new ZIP archive to your asset library',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppConstants.spacingXl),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
          ],

          // Stepper
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: _handleStepContinue,
              onStepCancel: _handleStepCancel,
              onStepTapped: _handleStepTapped,
              controlsBuilder: _buildStepperControls,
              steps: [
                Step(
                  title: const Text('Select ZIP File'),
                  subtitle: _selectedZipFile != null
                      ? Text(path_pkg.basename(_selectedZipFile!.path))
                      : null,
                  content: _buildFileSelectionStep(),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                ),
                Step(
                  title: const Text('Asset Information'),
                  subtitle: _titleController.text.isNotEmpty
                      ? Text(_titleController.text)
                      : null,
                  content: _buildInformationStep(),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                ),
                Step(
                  title: const Text('Images & Preview'),
                  subtitle: _thumbnail != null
                      ? const Text('Thumbnail selected')
                      : null,
                  content: _buildImagesStep(),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2
                      ? StepState.complete
                      : StepState.indexed,
                ),
                Step(
                  title: const Text('Review & Upload'),
                  content: _buildReviewStep(),
                  isActive: _currentStep >= 3,
                  state: StepState.indexed,
                ),
              ],
            ),
          ),
        ],
          ),
        );
      },
    );
  }

  Widget _buildBreadcrumbs() {
    return Breadcrumbs(
      items: [
        BreadcrumbItem(
          label: 'Home',
          onTap: () => context.go('/'),
        ),
        BreadcrumbItem(
          label: 'Assets',
          onTap: () => context.go('/assets'),
        ),
        BreadcrumbItem(label: 'Upload'),
      ],
    );
  }

  Widget _buildStepperControls(BuildContext context, ControlsDetails details) {
    final isLastStep = _currentStep == 3;

    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingLg),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: details.onStepCancel,
              child: const Text('Back'),
            ),
          if (_currentStep > 0) const SizedBox(width: AppConstants.spacingMd),
          ElevatedButton(
            onPressed: _isUploading ? null : details.onStepContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isLastStep ? 'Upload Asset' : 'Continue'),
          ),
        ],
      ),
    );
  }

  // Step 1: File Selection
  Widget _buildFileSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedZipFile == null)
          _buildDropZone()
        else
          _buildSelectedFileCard(),
      ],
    );
  }

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: _selectZipFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.spacingXxl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Click to select a ZIP file',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'Only .zip files are accepted',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: const Icon(
              Icons.folder_zip,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path_pkg.basename(_selectedZipFile!.path),
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatFileSize(_fileSize ?? 0)} • ${_entryCount ?? 0} files',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _selectedZipFile = null;
                _fileSize = null;
                _entryCount = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // Step 2: Information
  Widget _buildInformationStep() {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title *',
            hintText: 'Enter asset title',
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // Category dropdown with create button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                ),
                hint: const Text('Select a category'),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: _showCreateCategoryDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // Short description
        TextField(
          controller: _shortDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Short Description',
            hintText: 'Brief summary (optional)',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // Description
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Full Description',
            hintText: 'Detailed description of the asset',
          ),
          maxLines: 5,
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // Version
        TextField(
          controller: _versionController,
          decoration: const InputDecoration(
            labelText: 'Version',
            hintText: 'e.g., 1.0.0',
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // Demo URL
        TextField(
          controller: _demoUrlController,
          decoration: const InputDecoration(
            labelText: 'Demo URL',
            hintText: 'https://example.com/demo',
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // Last Updated Date
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _lastUpdatedController,
                decoration: const InputDecoration(
                  labelText: 'Last Updated',
                  hintText: 'When was this asset last updated?',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectLastUpdatedDate,
              ),
            ),
            if (_selectedLastUpdated != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _selectedLastUpdated = null;
                    _lastUpdatedController.clear();
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingMd),

        // Tags
        Text('Tags', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppConstants.spacingSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() => _selectedTags.remove(tag));
                },
              );
            }),
          ],
        ),
        const SizedBox(height: AppConstants.spacingSm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: 'Add a tag',
                  isDense: true,
                ),
                onSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_tagController.text),
            ),
          ],
        ),
      ],
    );
  }

  // Step 3: Images
  Widget _buildImagesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thumbnail Image', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          'Optional: Select a preview image for the asset',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        if (_thumbnail == null)
          OutlinedButton.icon(
            onPressed: _selectThumbnail,
            icon: const Icon(Icons.image),
            label: const Text('Select Thumbnail'),
          )
        else
          Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  child: Image.file(
                    _thumbnail!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path_pkg.basename(_thumbnail!.path),
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => setState(() => _thumbnail = null),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),

        const SizedBox(height: AppConstants.spacingLg),

        Text('Gallery Images', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppConstants.spacingSm),
        Text(
          'Optional: Add additional preview images',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingMd),

        if (_galleryImages.isEmpty)
          OutlinedButton.icon(
            onPressed: _selectGalleryImages,
            icon: const Icon(Icons.photo_library),
            label: const Text('Add Gallery Images'),
          )
        else
          Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _galleryImages.map((image) {
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusSm),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusSm),
                          child: Image.file(
                            image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, size: 20),
                          onPressed: () {
                            setState(() => _galleryImages.remove(image));
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              OutlinedButton.icon(
                onPressed: _selectGalleryImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add More'),
              ),
            ],
          ),
      ],
    );
  }

  // Step 4: Review
  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review your asset details:', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppConstants.spacingLg),

        _buildReviewItem(
            'File', path_pkg.basename(_selectedZipFile?.path ?? '')),
        _buildReviewItem('Size', _formatFileSize(_fileSize ?? 0)),
        _buildReviewItem('Files', '${_entryCount ?? 0} items'),
        const Divider(height: AppConstants.spacingLg),

        _buildReviewItem('Title', _titleController.text),
        _buildReviewItem(
          'Category',
          _categories
                  .where((c) => c.id == _selectedCategoryId)
                  .map((c) => c.name)
                  .firstOrNull ??
              'Not selected',
        ),
        if (_versionController.text.isNotEmpty)
          _buildReviewItem('Version', _versionController.text),
        if (_demoUrlController.text.isNotEmpty)
          _buildReviewItem('Demo URL', _demoUrlController.text),
        if (_selectedLastUpdated != null)
          _buildReviewItem('Last Updated',
              '${_selectedLastUpdated!.year}-${_selectedLastUpdated!.month.toString().padLeft(2, '0')}-${_selectedLastUpdated!.day.toString().padLeft(2, '0')}'),
        if (_selectedTags.isNotEmpty)
          _buildReviewItem('Tags', _selectedTags.join(', ')),
        if (_shortDescriptionController.text.isNotEmpty)
          _buildReviewItem(
              'Short Description', _shortDescriptionController.text),
        const Divider(height: AppConstants.spacingLg),

        _buildReviewItem(
            'Thumbnail', _thumbnail != null ? 'Selected' : 'None'),
        _buildReviewItem('Gallery Images', '${_galleryImages.length} images'),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // Handlers
  void _handleStepContinue() {
    if (_currentStep == 0) {
      if (_selectedZipFile == null) {
        setState(() => _errorMessage = 'Please select a ZIP file');
        return;
      }
    } else if (_currentStep == 1) {
      if (_titleController.text.isEmpty) {
        setState(() => _errorMessage = 'Please enter a title');
        return;
      }
      if (_selectedCategoryId == null) {
        setState(() => _errorMessage = 'Please select a category');
        return;
      }
    } else if (_currentStep == 3) {
      _handleUpload();
      return;
    }

    setState(() {
      _errorMessage = null;
      _currentStep++;
    });
  }

  void _handleStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _handleStepTapped(int step) {
    // Only allow going to steps that have been completed
    if (step < _currentStep) {
      setState(() => _currentStep = step);
    }
  }

  Future<void> _selectZipFile() async {
    try {
      // Show modal barrier to prevent interaction
      final result = await _showModalFilePicker(() async {
        return await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['zip'],
          dialogTitle: 'Select ZIP Archive',
        );
      });

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Validate ZIP
        final isValid = await services.zip.validateZipFile(file);
        if (!isValid) {
          setState(() => _errorMessage = 'Invalid or corrupted ZIP file');
          return;
        }

        final entryCount = await services.zip.getEntryCount(file);

        setState(() {
          _selectedZipFile = file;
          _fileSize = file.lengthSync();
          _entryCount = entryCount;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error selecting file: $e');
    }
  }

  Future<void> _selectThumbnail() async {
    try {
      // Show modal barrier to prevent interaction
      final result = await _showModalFilePicker(() async {
        return await FilePicker.platform.pickFiles(
          type: FileType.image,
          dialogTitle: 'Select Thumbnail Image',
        );
      });

      if (result != null && result.files.single.path != null) {
        setState(() {
          _thumbnail = File(result.files.single.path!);
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error selecting image: $e');
    }
  }

  Future<void> _selectGalleryImages() async {
    try {
      // Show modal barrier to prevent interaction
      final result = await _showModalFilePicker(() async {
        return await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          dialogTitle: 'Select Gallery Images',
        );
      });

      if (result != null) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              _galleryImages.add(File(file.path!));
            }
          }
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error selecting images: $e');
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_selectedTags.contains(trimmed)) {
      setState(() {
        _selectedTags.add(trimmed);
        _tagController.clear();
      });
    }
  }

  Future<void> _showCreateCategoryDialog() async {
    final newCategory = await showDialog<Category>(
      context: context,
      builder: (context) => const CreateCategoryDialog(),
    );

    if (newCategory != null) {
      // Reload categories
      await _loadCategories();

      // Auto-select the newly created category
      setState(() {
        _selectedCategoryId = newCategory.id;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "${newCategory.name}" created successfully!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _selectLastUpdatedDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedLastUpdated ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Last Updated Date',
    );

    if (picked != null) {
      setState(() {
        _selectedLastUpdated = picked;
        _lastUpdatedController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedZipFile == null || _selectedCategoryId == null) {
      setState(() => _errorMessage = 'Missing required information');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final asset = await services.asset.uploadAsset(
        zipFile: _selectedZipFile!,
        title: _titleController.text,
        categoryId: _selectedCategoryId!,
        description: _descriptionController.text,
        shortDescription: _shortDescriptionController.text,
        version:
            _versionController.text.isNotEmpty ? _versionController.text : null,
        lastUpdated: _selectedLastUpdated,
        demoUrl: _demoUrlController.text.isNotEmpty ? _demoUrlController.text : null,
        tags: _selectedTags,
        thumbnail: _thumbnail,
        galleryImages: _galleryImages,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Asset "${asset.title}" uploaded successfully!'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => context.go('/asset/${asset.slug}'),
            ),
          ),
        );

        // Navigate to asset detail or listing
        context.go('/asset/${asset.slug}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Upload failed: $e';
        _isUploading = false;
      });
    }
  }

  /// Shows a modal file picker that prevents interaction with the main window
  Future<FilePickerResult?> _showModalFilePicker(
    Future<FilePickerResult?> Function() picker,
  ) async {
    FilePickerResult? result;

    // Show a transparent barrier dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (BuildContext context) {
        // Launch the file picker immediately
        picker().then((value) {
          result = value;
          // Close the barrier dialog once picker returns
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });

        // Show a semi-transparent overlay with loading indicator
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Selecting file...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return result;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

