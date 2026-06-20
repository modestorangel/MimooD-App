class Post {
  final String id;
  final String title;
  final String content;
  final String excerpt;
  final String? featuredImageUrl;
  final String link;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    this.featuredImageUrl,
    required this.link,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'].toString(),
      title: json['title']?['rendered'] ?? '',
      content: json['content']?['rendered'] ?? '',
      excerpt: json['excerpt']?['rendered'] ?? '',
      featuredImageUrl: json['_embedded']?['wp:featuredmedia']?[0]?['source_url'],
      link: json['link'] ?? '',
    );
  }
}
