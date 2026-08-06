import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PasarProductService {
  final String baseUrl = 'http://10.250.3.148:8000/api';

  Future<List<Map<String, dynamic>>> getProducts({String category = 'Semua', String search = ''}) async {
    try {
      final uri = Uri.parse('$baseUrl/pasar-daerah/products').replace(queryParameters: {
        if (category != 'Semua') 'category': category,
        if (search.isNotEmpty) 'search': search,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pasar-daerah/categories')).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<String>.from(data['data']);
        }
      }
      return ['Semua'];
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return ['Semua'];
    }
  }
}
