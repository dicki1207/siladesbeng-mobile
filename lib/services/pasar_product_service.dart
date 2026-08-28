import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PasarProductService {
  final String baseUrl = 'http://10.250.3.148:8000/api';

  Future<List<Map<String, dynamic>>> getProducts({
    String category = 'Semua',
    String search = '',
    String sort = 'latest',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/pasar-daerah/products').replace(queryParameters: {
        if (category != 'Semua') 'category': category,
        if (search.isNotEmpty) 'search': search,
        if (sort != 'latest') 'sort': sort,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return _getFallbackProducts();
    } catch (e) {
      debugPrint('Error fetching products, using fallback: $e');
      return _getFallbackProducts();
    }
  }

  List<Map<String, dynamic>> _getFallbackProducts() {
    return [
      {
        'id': 101,
        'nama_produk': 'Kain Tenun Lejo Khas Bengkalis',
        'kategori': 'Kerajinan',
        'harga': 150000,
        'image_url': 'assets/images/PasarDaerah.png',
        'lokasi': 'Desa Sebauk, Kec. Bengkalis',
      },
      {
        'id': 102,
        'nama_produk': 'Lempuk Durian Asli Bantan',
        'kategori': 'Makanan',
        'harga': 45000,
        'image_url': 'assets/images/PasarDaerah.png',
        'lokasi': 'Desa Bantan Tua, Kec. Bantan',
      },
      {
        'id': 103,
        'nama_produk': 'Kopi Liberika Meranti',
        'kategori': 'Minuman',
        'harga': 35000,
        'image_url': 'assets/images/PasarDaerah.png',
        'lokasi': 'Desa Selatbaru, Kec. Bantan',
      },
      {
        'id': 104,
        'nama_produk': 'Tikar Pandan Anyaman',
        'kategori': 'Kerajinan',
        'harga': 80000,
        'image_url': 'assets/images/PasarDaerah.png',
        'lokasi': 'Desa Pematang Duku, Kec. Bengkalis',
      }
    ];
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pasar-daerah/categories')).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<String>.from(data['data']);
        }
      }
      return ['Semua', 'Makanan', 'Minuman', 'Kerajinan', 'Pertanian'];
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return ['Semua', 'Makanan', 'Minuman', 'Kerajinan', 'Pertanian'];
    }
  }

  Future<Map<String, dynamic>?> getProductDetail(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pasar-daerah/products/$productId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return Map<String, dynamic>.from(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching product detail: $e');
      return null;
    }
  }

  Future<int> getCartCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('$baseUrl/pasar-daerah/cart'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final items = List.from(data['data'] ?? []);
          return items.length;
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching cart count: $e');
      return 0;
    }
  }
}
