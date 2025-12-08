/// Export/download history record
class ExportRecord {
  final String id;
  final String assetId;
  final String exportPath;
  final DateTime exportedAt;
  final ExportType exportType;

  const ExportRecord({
    required this.id,
    required this.assetId,
    required this.exportPath,
    required this.exportedAt,
    required this.exportType,
  });

  ExportRecord copyWith({
    String? id,
    String? assetId,
    String? exportPath,
    DateTime? exportedAt,
    ExportType? exportType,
  }) {
    return ExportRecord(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      exportPath: exportPath ?? this.exportPath,
      exportedAt: exportedAt ?? this.exportedAt,
      exportType: exportType ?? this.exportType,
    );
  }

  factory ExportRecord.fromJson(Map<String, dynamic> json) {
    return ExportRecord(
      id: json['id'] as String,
      assetId: json['asset_id'] as String,
      exportPath: json['export_path'] as String,
      exportedAt: DateTime.fromMillisecondsSinceEpoch(json['exported_at'] as int),
      exportType: ExportType.fromString(json['export_type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_id': assetId,
      'export_path': exportPath,
      'exported_at': exportedAt.millisecondsSinceEpoch,
      'export_type': exportType.value,
    };
  }
}

/// Export type enumeration
enum ExportType {
  full('full'),
  selective('selective'),
  allData('all_data');

  final String value;
  const ExportType(this.value);

  static ExportType fromString(String value) {
    switch (value) {
      case 'full':
        return ExportType.full;
      case 'selective':
        return ExportType.selective;
      case 'all_data':
        return ExportType.allData;
      default:
        throw ArgumentError('Unknown export type: $value');
    }
  }
}
