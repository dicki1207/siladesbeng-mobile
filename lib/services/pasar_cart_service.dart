import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PasarCartService {
  final String baseUrl = 'http://10.250.3.148:8000/api';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getCart() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/pasar-daerah/cart'), headers: headers).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting cart: $e');
      return [];
    }
  }

  Future<bool> addToCart(int productId, int quantity) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'pasar_produk_id': productId,
        'quantity': quantity
      });
      final response = await http.post(Uri.parse('$baseUrl/pasar-daerah/cart/add'), headers: headers, body: body).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      return false;
    }
  }

  Future<bool> updateCart(int cartItemId, int quantity) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'cart_item_id': cartItemId,
        'quantity': quantity
      });
      final response = await http.post(Uri.parse('$baseUrl/pasar-daerah/cart/update'), headers: headers, body: body).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating cart: $e');
      return false;
    }
  }

  Future<bool> removeFromCart(int cartItemId) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({'cart_item_id': cartItemId});
      final response = await http.post(Uri.parse('$baseUrl/pasar-daerah/cart/remove'), headers: headers, body: body).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      return false;
    }
  }
}
