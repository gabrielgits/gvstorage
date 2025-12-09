/// Import result and conflict resolution models

// ignore_for_file: dangling_library_doc_comments

/// Result of an import operation
class ImportResult {
  final int totalAssets;
  final int successfulAssets;
  final int failedAssets;
  final int skippedAssets;
  final int categoriesImported;
  final int tagsImported;
  final Map<String, String> errors; // slug -> error message

  const ImportResult({
    required this.totalAssets,
    required this.successfulAssets,
    required this.failedAssets,
    required this.skippedAssets,
    required this.categoriesImported,
    required this.tagsImported,
    required this.errors,
  });

  /// Check if there are any failures
  bool get hasFailures => failedAssets > 0;

  /// Check if import had partial success
  bool get hasPartialSuccess => successfulAssets > 0 && failedAssets > 0;

  /// Check if import was fully successful
  bool get isFullSuccess => successfulAssets > 0 && failedAssets == 0;

  @override
  String toString() {
    return 'ImportResult(total: $totalAssets, successful: $successfulAssets, failed: $failedAssets, skipped: $skippedAssets)';
  }
}

/// Actions available when resolving asset conflicts
enum ConflictResolutionAction {
  skip,      // Skip this asset entirely
  overwrite, // Replace existing asset
  rename,    // Import with new slug (user provides suffix)
}

/// Resolution decision for a conflicting asset
class ConflictResolution {
  final ConflictResolutionAction action;
  final String? newSlug; // Only used for rename action

  const ConflictResolution({
    required this.action,
    this.newSlug,
  });

  @override
  String toString() {
    if (action == ConflictResolutionAction.rename && newSlug != null) {
      return 'ConflictResolution(rename to: $newSlug)';
    }
    return 'ConflictResolution(${action.name})';
  }
}

/// Callback type for conflict resolution
typedef ConflictResolutionCallback = Future<ConflictResolution> Function(
  String assetSlug,
  String assetTitle,
  Map<String, dynamic> existingAssetData,
  Map<String, dynamic> incomingAssetData,
);

/// Result of importing a single asset
class ImportAssetResult {
  final bool success;
  final String assetId;
  final String slug;
  final String? errorMessage;

  const ImportAssetResult({
    required this.success,
    required this.assetId,
    required this.slug,
    this.errorMessage,
  });

  @override
  String toString() {
    if (success) {
      return 'ImportAssetResult(success: $slug)';
    }
    return 'ImportAssetResult(failed: $slug, error: $errorMessage)';
  }
}
