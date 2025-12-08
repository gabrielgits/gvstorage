import 'dart:io';
import 'package:flutter/material.dart';
import '../models/asset.dart';

/// Provider for upload form state management
/// Manages multi-step upload wizard state
class UploadProvider extends ChangeNotifier {
  // Step state
  int _currentStep = 0;

  // Loading and error states
  bool _isUploading = false;
  String? _errorMessage;

  // File selection
  File? _selectedZipFile;
  String? _zipFileName;
  int? _zipFileSize;

  // Images
  File? _mainImage;
  final List<File> _galleryImages = [];

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _shortDescriptionController = TextEditingController();
  final TextEditingController _versionController = TextEditingController();

  // Form data
  final List<String> _features = [];
  final List<String> _tags = [];
  String? _selectedCategoryId;
  bool _isFeatured = false;

  // Getters
  int get currentStep => _currentStep;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;

  File? get selectedZipFile => _selectedZipFile;
  String? get zipFileName => _zipFileName;
  int? get zipFileSize => _zipFileSize;

  File? get mainImage => _mainImage;
  List<File> get galleryImages => List.unmodifiable(_galleryImages);

  TextEditingController get titleController => _titleController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get shortDescriptionController => _shortDescriptionController;
  TextEditingController get versionController => _versionController;

  List<String> get features => List.unmodifiable(_features);
  List<String> get tags => List.unmodifiable(_tags);
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isFeatured => _isFeatured;

  // Computed getters
  bool get canProceed {
    switch (_currentStep) {
      case 0: // File selection step
        return _selectedZipFile != null;
      case 1: // Details step
        return _titleController.text.isNotEmpty && _selectedCategoryId != null;
      case 2: // Features step
        return true; // Features are optional
      default:
        return false;
    }
  }

  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _currentStep == 2;

  String? get zipFileSizeFormatted {
    if (_zipFileSize == null) return null;
    final size = _zipFileSize!;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Move to next step
  void nextStep() {
    if (!isLastStep && canProceed) {
      _currentStep++;
      notifyListeners();
    }
  }

  /// Move to previous step
  void previousStep() {
    if (!isFirstStep) {
      _currentStep--;
      notifyListeners();
    }
  }

  /// Go to specific step
  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      _currentStep = step;
      notifyListeners();
    }
  }

  /// Select ZIP file
  void selectZipFile(File file) {
    _selectedZipFile = file;
    _zipFileName = file.path.split('/').last;
    _zipFileSize = file.lengthSync();
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear ZIP file selection
  void clearZipFile() {
    _selectedZipFile = null;
    _zipFileName = null;
    _zipFileSize = null;
    notifyListeners();
  }

  /// Select main image
  void selectMainImage(File file) {
    _mainImage = file;
    notifyListeners();
  }

  /// Clear main image
  void clearMainImage() {
    _mainImage = null;
    notifyListeners();
  }

  /// Add gallery image
  void addGalleryImage(File file) {
    if (_galleryImages.length < 5) {
      // Limit to 5 gallery images
      _galleryImages.add(file);
      notifyListeners();
    }
  }

  /// Remove gallery image
  void removeGalleryImage(int index) {
    if (index >= 0 && index < _galleryImages.length) {
      _galleryImages.removeAt(index);
      notifyListeners();
    }
  }

  /// Clear all gallery images
  void clearGalleryImages() {
    _galleryImages.clear();
    notifyListeners();
  }

  /// Add feature
  void addFeature(String featureTitle, [String? featureDescription]) {
    if (featureTitle.isNotEmpty) {
      final feature = featureDescription != null
          ? '$featureTitle::$featureDescription'
          : featureTitle;
      _features.add(feature);
      notifyListeners();
    }
  }

  /// Remove feature
  void removeFeature(int index) {
    if (index >= 0 && index < _features.length) {
      _features.removeAt(index);
      notifyListeners();
    }
  }

  /// Clear all features
  void clearFeatures() {
    _features.clear();
    notifyListeners();
  }

  /// Add tag
  void addTag(String tag) {
    final trimmedTag = tag.trim().toLowerCase();
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      _tags.add(trimmedTag);
      notifyListeners();
    }
  }

  /// Remove tag
  void removeTag(String tag) {
    _tags.remove(tag);
    notifyListeners();
  }

  /// Clear all tags
  void clearTags() {
    _tags.clear();
    notifyListeners();
  }

  /// Set selected category
  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Set featured status
  void setFeatured(bool isFeatured) {
    _isFeatured = isFeatured;
    notifyListeners();
  }

  /// Set uploading state
  void setUploading(bool isUploading) {
    _isUploading = isUploading;
    notifyListeners();
  }

  /// Set error message
  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Parse features from string list to AssetFeature objects
  List<AssetFeature> get parsedFeatures {
    return _features.map((feature) {
      final parts = feature.split('::');
      return AssetFeature(
        title: parts[0],
        description: parts.length > 1 ? parts[1] : null,
      );
    }).toList();
  }

  /// Reset form to initial state
  void resetForm() {
    _currentStep = 0;
    _isUploading = false;
    _errorMessage = null;

    _selectedZipFile = null;
    _zipFileName = null;
    _zipFileSize = null;

    _mainImage = null;
    _galleryImages.clear();

    _titleController.clear();
    _descriptionController.clear();
    _shortDescriptionController.clear();
    _versionController.clear();

    _features.clear();
    _tags.clear();
    _selectedCategoryId = null;
    _isFeatured = false;

    notifyListeners();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _shortDescriptionController.dispose();
    _versionController.dispose();
    super.dispose();
  }
}
