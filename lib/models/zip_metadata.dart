/// ZIP file metadata
class ZipMetadata {
  final String id;
  final String assetId;
  final int entryCount;
  final double? compressionRatio;
  final bool hasDirectoryStructure;
  final String? originalName;

  const ZipMetadata({
    required this.id,
    required this.assetId,
    required this.entryCount,
    this.compressionRatio,
    this.hasDirectoryStructure = false,
    this.originalName,
  });

  ZipMetadata copyWith({
    String? id,
    String? assetId,
    int? entryCount,
    double? compressionRatio,
    bool? hasDirectoryStructure,
    String? originalName,
  }) {
    return ZipMetadata(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      entryCount: entryCount ?? this.entryCount,
      compressionRatio: compressionRatio ?? this.compressionRatio,
      hasDirectoryStructure: hasDirectoryStructure ?? this.hasDirectoryStructure,
      originalName: originalName ?? this.originalName,
    );
  }

  factory ZipMetadata.fromJson(Map<String, dynamic> json) {
    return ZipMetadata(
      id: json['id'] as String,
      assetId: json['asset_id'] as String,
      entryCount: json['entry_count'] as int,
      compressionRatio: json['compression_ratio'] != null
          ? (json['compression_ratio'] as num).toDouble()
          : null,
      hasDirectoryStructure: (json['has_directory_structure'] as int?) == 1,
      originalName: json['original_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_id': assetId,
      'entry_count': entryCount,
      'compression_ratio': compressionRatio,
      'has_directory_structure': hasDirectoryStructure ? 1 : 0,
      'original_name': originalName,
    };
  }
}
