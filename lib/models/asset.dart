import 'zip_metadata.dart';

/// Asset model representing a digital asset stored in ZIP format
class Asset {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String shortDescription;
  final String imageUrl;
  final List<String> galleryImages;
  final String category;
  final String categorySlug;
  final String? version;
  final DateTime? lastUpdated;
  final List<String> tags;
  final List<AssetFeature> features;
  final bool isFeatured;
  final DateTime createdAt;
  final int fileSize; // in bytes
  final String zipPath; // Relative path from storage root
  final String? thumbnailPath;
  final int downloadsCount;
  final ZipMetadata? zipMetadata; // Lazy-loaded
  final String? demoUrl;
  final DateTime updatedAt;

  const Asset({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    this.shortDescription = '',
    required this.imageUrl,
    this.galleryImages = const [],
    required this.category,
    required this.categorySlug,
    this.version,
    this.lastUpdated,
    this.tags = const [],
    this.features = const [],
    this.isFeatured = false,
    required this.createdAt,
    required this.fileSize,
    required this.zipPath,
    this.thumbnailPath,
    this.downloadsCount = 0,
    this.zipMetadata,
    this.demoUrl,
    required this.updatedAt,
  });

  /// Get human-readable file size
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Check if asset has a version
  bool get hasVersion => version != null && version!.isNotEmpty;

  /// Create a copy with modified fields
  Asset copyWith({
    String? id,
    String? title,
    String? slug,
    String? description,
    String? shortDescription,
    String? imageUrl,
    List<String>? galleryImages,
    String? category,
    String? categorySlug,
    String? version,
    DateTime? lastUpdated,
    List<String>? tags,
    List<AssetFeature>? features,
    bool? isFeatured,
    DateTime? createdAt,
    int? fileSize,
    String? zipPath,
    String? thumbnailPath,
    int? downloadsCount,
    ZipMetadata? zipMetadata,
    String? demoUrl,
    DateTime? updatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      category: category ?? this.category,
      categorySlug: categorySlug ?? this.categorySlug,
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      tags: tags ?? this.tags,
      features: features ?? this.features,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
      zipPath: zipPath ?? this.zipPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      downloadsCount: downloadsCount ?? this.downloadsCount,
      zipMetadata: zipMetadata ?? this.zipMetadata,
      demoUrl: demoUrl ?? this.demoUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create Asset from JSON (database record)
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      shortDescription: json['short_description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      galleryImages: json['gallery_images'] != null
          ? (json['gallery_images'] as String)
              .split(',')
              .where((s) => s.isNotEmpty)
              .toList()
          : [],
      category: json['category'] as String? ?? '',
      categorySlug: json['category_slug'] as String? ?? '',
      version: json['version'] as String?,
      lastUpdated: json['last_updated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_updated'] as int)
          : null,
      tags: json['tags'] != null
          ? (json['tags'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      features: json['features'] != null
          ? (json['features'] as String)
              .split('|')
              .where((s) => s.isNotEmpty)
              .map((f) {
                final parts = f.split('::');
                return AssetFeature(
                  title: parts[0],
                  description: parts.length > 1 ? parts[1] : null,
                  icon: parts.length > 2 ? parts[2] : null,
                );
              })
              .toList()
          : [],
      isFeatured: (json['is_featured'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      fileSize: json['file_size'] as int,
      zipPath: json['zip_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      downloadsCount: json['downloads_count'] as int? ?? 0,
      zipMetadata: null, // Lazy-loaded separately
      demoUrl: json['demo_url'] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['updated_at'] as int? ?? json['created_at'] as int
      ),
    );
  }

  /// Convert Asset to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'short_description': shortDescription,
      'image_url': imageUrl,
      'gallery_images': galleryImages.join(','),
      'category': category,
      'category_slug': categorySlug,
      'version': version,
      'last_updated': lastUpdated?.millisecondsSinceEpoch,
      'tags': tags.join(','),
      'features': features
          .map((f) => '${f.title}::${f.description ?? ''}::${f.icon ?? ''}')
          .join('|'),
      'is_featured': isFeatured ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'file_size': fileSize,
      'zip_path': zipPath,
      'thumbnail_path': thumbnailPath,
      'downloads_count': downloadsCount,
      'demo_url': demoUrl,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Convert Asset to database insert/update map (without computed fields)
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'short_description': shortDescription,
      'category_id': category,
      'version': version,
      'last_updated': lastUpdated?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'file_size': fileSize,
      'zip_path': zipPath,
      'thumbnail_path': thumbnailPath,
      'is_featured': isFeatured ? 1 : 0,
      'downloads_count': downloadsCount,
      'demo_url': demoUrl,
      // Note: updated_at is managed by SQLite trigger, not set manually
    };
  }
}

/// Asset feature/bullet point
class AssetFeature {
  final String title;
  final String? description;
  final String? icon;

  const AssetFeature({
    required this.title,
    this.description,
    this.icon,
  });

  factory AssetFeature.fromJson(Map<String, dynamic> json) {
    return AssetFeature(
      title: json['title'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
    };
  }
}
