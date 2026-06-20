import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../models/category_model.dart';

class WordpressService {
  static const String _baseUrl = 'https://mimood.com.br/wp-json/wp/v2/';

  Future<List<Post>> fetchPosts({int page = 1, int perPage = 10, int? categoryId}) async {
    try {
      String url = '${_baseUrl}posts?_embed&page=$page&per_page=$perPage';
      if (categoryId != null) {
        url += '&categories=$categoryId';
      }
      final response = await http.get(Uri.parse(url));

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

  Future<List<Post>> searchPosts(String query, {int page = 1, int perPage = 10}) async {
    try {
      final response = await http.get(Uri.parse('${_baseUrl}posts?_embed&search=$query&page=$page&per_page=$perPage'));

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

  Future<List<WordPressCategory>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('${_baseUrl}categories?per_page=100&hide_empty=true'));

      if (response.statusCode == 200) {
        Iterable jsonResponse = json.decode(response.body);
        return jsonResponse.map((cat) => WordPressCategory.fromJson(cat)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }
}
