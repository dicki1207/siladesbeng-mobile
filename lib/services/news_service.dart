import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NewsService {
  static const String baseUrl = 'http://10.250.3.148:8000/api';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('token');

    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Get all news/announcements with optional filters
  Future<List<dynamic>> getNews({String? type, String? search, String? postCategory}) async {
    try {
      final headers = await _getHeaders();
      
      // Build query string
      List<String> queryParams = [];
      if (type != null && type != 'Semua') {
        queryParams.add('type=$type');
      }
      if (search != null && search.isNotEmpty) {
        queryParams.add('search=$search');
      }
      if (postCategory != null && postCategory.isNotEmpty) {
        queryParams.add('post_category=$postCategory');
      }
      
      String queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      
      final response = await http.get(
        Uri.parse('$baseUrl/news$queryString'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching news: $e');
      return [];
    }
  }

  /// Get specific news detail
  Future<Map<String, dynamic>?> getNewsDetail(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/news/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
