class Post {
  final int id;
  final String title;
  final String excerpt;
  final String content;
  final String? featuredImageUrl;

  Post({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    this.featuredImageUrl,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    try {
      if (json['_embedded']?['wp:featuredmedia'] != null && 
          json['_embedded']['wp:featuredmedia'].isNotEmpty) {
        imageUrl = json['_embedded']['wp:featuredmedia'][0]['source_url'];
      }
    } catch (e) {
      // Could log this error, but for now, we'll just ignore it if the structure is unexpected
      imageUrl = null;
    }

    return Post(
      id: json['id'],
      title: json['title']?['rendered'] ?? '',
      excerpt: json['excerpt']?['rendered'] ?? '',
      content: json['content']?['rendered'] ?? '',
      featuredImageUrl: imageUrl,
    );
  }
}
