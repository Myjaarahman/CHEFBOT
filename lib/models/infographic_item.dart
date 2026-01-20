// lib/models/infographic_item.dart

class InfographicItem {
  final int id;
  final String title;
  final String? subtitle;
  final String description;
  final String? imageUrl;
  final int sortOrder;

  InfographicItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.description,
    this.imageUrl,
    required this.sortOrder,
  });

  // Factory constructor to convert the Supabase JSON map into a Dart object
  factory InfographicItem.fromMap(Map<String, dynamic> map) {
    return InfographicItem(
      id: map['id'] as int,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String?,
      description: map['description'] as String,
      imageUrl: map['image_url'] as String?,
      sortOrder: map['sort_order'] as int,
    );
  }
}