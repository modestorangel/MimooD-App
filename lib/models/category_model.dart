class WordPressCategory {
  final int id;
  final String name;
  final String slug;
  final int count;

  WordPressCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.count,
  });

  factory WordPressCategory.fromJson(Map<String, dynamic> json) {
    return WordPressCategory(
      id: json['id'] as int,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}
