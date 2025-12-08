/// Tag model for categorizing assets
class Tag {
  final String id;
  final String name;
  final String slug;
  final DateTime createdAt;

  const Tag({
    required this.id,
    required this.name,
    required this.slug,
    required this.createdAt,
  });

  Tag copyWith({
    String? id,
    String? name,
    String? slug,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
