/// Export progress tracking models

// ignore_for_file: dangling_library_doc_comments

/// Represents the current phase of the export process
enum ExportPhase {
  preparingData('Preparing data...'),
  collectingFiles('Collecting files...'),
  creatingArchive('Creating archive...'),
  completed('Export completed');

  final String label;
  const ExportPhase(this.label);
}

/// Tracks the progress of an export operation
class ExportProgress {
  final int totalAssets;
  final int processedAssets;
  final int totalFiles;
  final int processedFiles;
  final String currentFile;
  final ExportPhase phase;
  final String? errorMessage;

  const ExportProgress({
    required this.totalAssets,
    required this.processedAssets,
    required this.totalFiles,
    required this.processedFiles,
    required this.currentFile,
    required this.phase,
    this.errorMessage,
  });

  /// Calculate completion percentage (0.0 to 1.0)
  double get percentage {
    if (totalFiles == 0) return 0.0;
    return processedFiles / totalFiles;
  }

  /// Calculate completion percentage as integer (0 to 100)
  int get percentageInt => (percentage * 100).round();

  /// Check if export is complete
  bool get isComplete => phase == ExportPhase.completed;

  /// Check if there's an error
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// Create a copy with modified fields
  ExportProgress copyWith({
    int? totalAssets,
    int? processedAssets,
    int? totalFiles,
    int? processedFiles,
    String? currentFile,
    ExportPhase? phase,
    String? errorMessage,
  }) {
    return ExportProgress(
      totalAssets: totalAssets ?? this.totalAssets,
      processedAssets: processedAssets ?? this.processedAssets,
      totalFiles: totalFiles ?? this.totalFiles,
      processedFiles: processedFiles ?? this.processedFiles,
      currentFile: currentFile ?? this.currentFile,
      phase: phase ?? this.phase,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'ExportProgress(phase: ${phase.label}, progress: $processedFiles/$totalFiles, current: $currentFile)';
  }
}

/// Token for cancelling an export operation
class ExportCancellationToken {
  bool _isCancelled = false;

  /// Mark the export as cancelled
  void cancel() {
    _isCancelled = true;
  }

  /// Check if the export has been cancelled
  bool get isCancelled => _isCancelled;

  /// Reset the cancellation state
  void reset() {
    _isCancelled = false;
  }
}

/// Exception thrown when export is cancelled
class ExportCancelledException implements Exception {
  final String message;

  ExportCancelledException([this.message = 'Export was cancelled by user']);

  @override
  String toString() => message;
}

/// Exception thrown when export encounters an error
class ExportException implements Exception {
  final String message;
  final dynamic originalError;

  ExportException(this.message, [this.originalError]);

  @override
  String toString() {
    if (originalError != null) {
      return 'ExportException: $message (caused by: $originalError)';
    }
    return 'ExportException: $message';
  }
}
