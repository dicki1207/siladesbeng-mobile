import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PasarProductService {
  final String baseUrl = 'http://10.121.197.148:8000/api';

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

  Future<List<Map<String, dynamic>>> getProductReviews(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pasar-daerah/products/$productId/reviews'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  Future<bool> submitReview(int productId, int rating, String comment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/pasar-daerah/products/$productId/reviews'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'rating': rating,
          'comment': comment,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Error submitting review: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getSellerProfile(int regionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pasar-daerah/seller/$regionId'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return Map<String, dynamic>.from(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching seller profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> submitComplaint({
    required int orderId,
    required String reason,
    required String solutionRequested,
    String? description,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    List<String> evidencePhotoPaths = const [],
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        return {'success': false, 'message': 'Silakan login terlebih dahulu'};
      }

      final uri = Uri.parse('$baseUrl/pasar-daerah/orders/$orderId/complaint');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['reason'] = reason;
      request.fields['solution_requested'] = solutionRequested;
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      if (bankName != null && bankName.isNotEmpty) {
        request.fields['bank_name'] = bankName;
      }
      if (bankAccountNumber != null && bankAccountNumber.isNotEmpty) {
        request.fields['bank_account_number'] = bankAccountNumber;
      }
      if (bankAccountName != null && bankAccountName.isNotEmpty) {
        request.fields['bank_account_name'] = bankAccountName;
      }

      for (int i = 0; i < evidencePhotoPaths.length && i < 3; i++) {
        final path = evidencePhotoPaths[i];
        if (path.isNotEmpty) {
          request.files.add(
            await http.MultipartFile.fromPath('evidence_${i + 1}', path),
          );
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Komplain berhasil diajukan',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengajukan komplain',
        };
      }
    } catch (e) {
      debugPrint('Error submitting complaint: $e');
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }
}
