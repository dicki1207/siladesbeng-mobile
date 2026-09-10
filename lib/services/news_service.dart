import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NewsService {
  static const String baseUrl = 'https://siladesbeng.inovasia.site/api';

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

  String _replaceLocalhost(String? url) {
    if (url == null || url.isEmpty) return '';
    String fixedUrl = url;

    // Fix HTTP to HTTPS for release builds (Android blocks cleartext HTTP)
    if (fixedUrl.startsWith('http://siladesbeng.inovasia.site')) {
      fixedUrl = fixedUrl.replaceFirst('http://', 'https://');
    }

    // Replace all localhost variants with the actual server IP
    fixedUrl = fixedUrl.replaceAll('http://localhost:8000', 'https://siladesbeng.inovasia.site');
    fixedUrl = fixedUrl.replaceAll('http://localhost', 'https://siladesbeng.inovasia.site');
    fixedUrl = fixedUrl.replaceAll('http://127.0.0.1:8000', 'https://siladesbeng.inovasia.site');
    fixedUrl = fixedUrl.replaceAll('http://127.0.0.1', 'https://siladesbeng.inovasia.site');
    fixedUrl = fixedUrl.replaceAll('http://10.0.2.2:8000', 'https://siladesbeng.inovasia.site');
    fixedUrl = fixedUrl.replaceAll('http://10.0.2.2', 'https://siladesbeng.inovasia.site');

    if (!fixedUrl.startsWith('http')) {
      return 'https://siladesbeng.inovasia.site/$fixedUrl';
    }

    return fixedUrl;
  }

  List<dynamic> _fixImageUrls(List<dynamic> items) {
    return items.map((item) {
      if (item is Map<String, dynamic> && item.containsKey('image') && item['image'] != null) {
        item['image'] = _replaceLocalhost(item['image'] as String?);
      }
      return item;
    }).toList();
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
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['data'] ?? [];
        return _fixImageUrls(items as List<dynamic>);
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
        final item = data['data'];
        if (item is Map<String, dynamic> && item.containsKey('image') && item['image'] != null) {
          item['image'] = _replaceLocalhost(item['image'] as String?);
        }
        return item;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create news / article / activity (for Admin RT/RW/Desa)
  Future<Map<String, dynamic>> createNews({
    required String title,
    required String type, // 'Berita', 'Kegiatan', 'Artikel'
    required String description,
    String? location,
    String? eventDate,
    String? imagePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final uri = Uri.parse('$baseUrl/wilayah/berita');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['title'] = title;
      request.fields['type'] = type;
      request.fields['description'] = description;
      if (location != null && location.trim().isNotEmpty) {
        request.fields['location'] = location.trim();
      }
      if (eventDate != null && eventDate.trim().isNotEmpty) {
        request.fields['event_date'] = eventDate.trim();
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath('image', imagePath));
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      try {
        final data = json.decode(response.body);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true, 'message': data['message'] ?? 'Berita berhasil dipublikasikan!'};
        } else {
          return {'success': false, 'message': data['message'] ?? 'Gagal mempublikasikan berita'};
        }
      } catch (_) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'success': true, 'message': 'Berita berhasil dipublikasikan!'};
        }
        return {'success': false, 'message': 'Terjadi kesalahan pada respon server (${response.statusCode})'};
      }
    } catch (e) {
      debugPrint('Error creating news: $e');
      return {'success': false, 'message': 'Terjadi kesalahan koneksi atau sistem.'};
    }
  }
}
