import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class WordpressService {
  static const String _baseUrl = 'https://mimood.com.br/wp-json/wp/v2/';

  Future<List<Post>> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('${_baseUrl}posts?_embed'));

      if (response.statusCode == 200) {
        Iterable jsonResponse = json.decode(response.body);
        return jsonResponse.map((post) => Post.fromJson(post)).toList();
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      throw Exception('Failed to load posts: $e');
    }
  }

  Future<List<Post>> searchPosts(String query) async {
    try {
      final response = await http.get(Uri.parse('${_baseUrl}posts?_embed&search=$query'));

      if (response.statusCode == 200) {
        Iterable jsonResponse = json.decode(response.body);
        return jsonResponse.map((post) => Post.fromJson(post)).toList();
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      throw Exception('Failed to load search results: $e');
    }
  }

  Future<Post> fetchPost(String id) async {
    try {
      final response = await http.get(Uri.parse('${_baseUrl}posts/$id?_embed'));

      if (response.statusCode == 200) {
        return Post.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load post');
      }
    } catch (e) {
      throw Exception('Failed to load post: $e');
    }
  }
}
