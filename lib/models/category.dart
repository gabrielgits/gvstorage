/// Category model for asset categories
class Category {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final int assetCount;
  final String? parentId;
  final int displayOrder;
  final DateTime createdAt;
  final List<Category> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.assetCount = 0,
    this.parentId,
    this.displayOrder = 0,
    DateTime? createdAt,
    this.subcategories = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasSubcategories => subcategories.isNotEmpty;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      assetCount: json['asset_count'] as int? ?? 0,
      parentId: json['parent_id'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int)
          : DateTime.now(),
      subcategories: (json['subcategories'] as List<dynamic>?)
              ?.map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'image_url': imageUrl,
      'asset_count': assetCount,
      'parent_id': parentId,
      'display_order': displayOrder,
      'created_at': createdAt.millisecondsSinceEpoch,
      'subcategories': subcategories.map((e) => e.toJson()).toList(),
    };
  }
}
