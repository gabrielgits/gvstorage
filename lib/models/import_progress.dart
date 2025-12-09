/// Import progress tracking models

// ignore_for_file: dangling_library_doc_comments

/// Represents the current phase of the import process
enum ImportPhase {
  extractingArchive('Extracting archive...'),
  validatingData('Validating data...'),
  importingCategories('Importing categories...'),
  importingTags('Importing tags...'),
  importingAssets('Importing assets...'),
  finalizing('Finalizing import...'),
  completed('Import completed');

  final String label;
  const ImportPhase(this.label);
}

/// Tracks the progress of an import operation
class ImportProgress {
  final int totalAssets;
  final int processedAssets;
  final int totalItems;
  final int processedItems;
  final String currentItem;
  final ImportPhase phase;
  final String? errorMessage;

  const ImportProgress({
    required this.totalAssets,
    required this.processedAssets,
    required this.totalItems,
    required this.processedItems,
    required this.currentItem,
    required this.phase,
    this.errorMessage,
  });

  /// Calculate completion percentage (0.0 to 1.0)
  double get percentage {
    if (totalItems == 0) return 0.0;
    return processedItems / totalItems;
  }

  /// Calculate completion percentage as integer (0 to 100)
  int get percentageInt => (percentage * 100).round();

  /// Check if import is complete
  bool get isComplete => phase == ImportPhase.completed;

  /// Check if there's an error
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// Create a copy with modified fields
  ImportProgress copyWith({
    int? totalAssets,
    int? processedAssets,
    int? totalItems,
    int? processedItems,
    String? currentItem,
    ImportPhase? phase,
    String? errorMessage,
  }) {
    return ImportProgress(
      totalAssets: totalAssets ?? this.totalAssets,
      processedAssets: processedAssets ?? this.processedAssets,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
      currentItem: currentItem ?? this.currentItem,
      phase: phase ?? this.phase,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'ImportProgress(phase: ${phase.label}, progress: $processedItems/$totalItems, current: $currentItem)';
  }
}

/// Token for cancelling an import operation
class ImportCancellationToken {
  bool _isCancelled = false;

  /// Mark the import as cancelled
  void cancel() {
    _isCancelled = true;
  }

  /// Check if the import has been cancelled
  bool get isCancelled => _isCancelled;

  /// Reset the cancellation state
  void reset() {
    _isCancelled = false;
  }
}

/// Exception thrown when import is cancelled
class ImportCancelledException implements Exception {
  final String message;

  ImportCancelledException([this.message = 'Import was cancelled by user']);

  @override
  String toString() => message;
}

/// Exception thrown when import encounters an error
class ImportException implements Exception {
  final String message;
  final dynamic originalError;

  ImportException(this.message, [this.originalError]);

  @override
  String toString() {
    if (originalError != null) {
      return 'ImportException: $message (caused by: $originalError)';
    }
    return 'ImportException: $message';
  }
}
