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

  String _replaceLocalhost(String? url) {
    if (url == null || url.isEmpty) return '';
    String fixedUrl = url;
    // Replace all localhost variants with the actual server IP
    fixedUrl = fixedUrl.replaceAll('http://localhost:8000', 'http://10.250.3.148:8000');
    fixedUrl = fixedUrl.replaceAll('http://localhost', 'http://10.250.3.148:8000');
    fixedUrl = fixedUrl.replaceAll('http://127.0.0.1:8000', 'http://10.250.3.148:8000');
    fixedUrl = fixedUrl.replaceAll('http://127.0.0.1', 'http://10.250.3.148:8000');
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
      return _getFallbackNews();
    } catch (e) {
      debugPrint('Error fetching news, using fallback: $e');
      return _getFallbackNews();
    }
  }

  List<dynamic> _getFallbackNews() {
    return [
      {
        'id': 1,
        'title': 'Gotong Royong Membersihkan Parit dan Fasilitas Desa',
        'content': 'Warga desa beramai-ramai membersihkan lingkungan untuk mencegah banjir di musim penghujan.',
        'post_category': 'Agenda',
        'published_at': '2026-08-25',
        'image': 'assets/images/F2.png',
        'views': 120,
      },
      {
        'id': 2,
        'title': 'Penyaluran Bantuan Sembako BUMDes',
        'content': 'BUMDes menyalurkan bantuan sembako kepada warga kurang mampu di balai desa.',
        'post_category': 'Berita',
        'published_at': '2026-08-27',
        'image': 'assets/images/F2.png',
        'views': 85,
      },
      {
        'id': 3,
        'title': 'Pengumuman Musyawarah Perencanaan Pembangunan Desa (Musrenbangdes)',
        'content': 'Diharapkan kehadiran seluruh RT dan RW pada acara Musrenbangdes tahun 2027.',
        'post_category': 'Pengumuman',
        'published_at': '2026-08-28',
        'image': 'assets/images/F2.png',
        'views': 250,
      }
    ];
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
}
