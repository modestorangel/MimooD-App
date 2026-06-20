class Post {
  final String id;
  final String title;
  final String content;
  final String excerpt;
  final String? featuredImageUrl;
  final String link;
  final DateTime date;
  final int readingTime;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    this.featuredImageUrl,
    required this.link,
    required this.date,
    required this.readingTime,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final contentText = json['content']?['rendered'] ?? '';
    return Post(
      id: json['id'].toString(),
      title: json['title']?['rendered'] ?? '',
      content: contentText,
      excerpt: json['excerpt']?['rendered'] ?? '',
      featuredImageUrl: json['_embedded']?['wp:featuredmedia']?[0]?['source_url'],
      link: json['link'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      readingTime: _calculateReadingTime(contentText),
    );
  }

  static int _calculateReadingTime(String htmlContent) {
    // Strip HTML tags
    final plainText = htmlContent.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
    final words = plainText.trim().split(RegExp(r'\s+'));
    final wordCount = words.where((w) => w.isNotEmpty).length;
    final minutes = (wordCount / 200).ceil();
    return minutes > 0 ? minutes : 1;
  }
}
