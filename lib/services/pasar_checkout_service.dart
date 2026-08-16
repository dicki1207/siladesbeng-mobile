// ignore_for_file: use_null_aware_elements
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';

class PasarCheckoutService {
  String get baseUrl => '${ApiConfig.baseUrl}/api';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> checkout(
    String deliveryMethod, {
    String? deliveryAddress,
    String? notes,
    String? paymentMethod,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'delivery_method': deliveryMethod,
        if (deliveryAddress != null) 'delivery_address': deliveryAddress,
        if (notes != null) 'notes': notes,
        if (paymentMethod != null) 'payment_method': paymentMethod,
      });
      final response = await http
          .post(Uri.parse('$baseUrl/pasar-daerah/checkout'), headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message'], 'order': data['order']};
      }
      return {'success': false, 'message': data['message'] ?? 'Checkout gagal'};
    } catch (e) {
      debugPrint('Error checkout: $e');
      return {'success': false, 'message': 'Terjadi kesalahan sistem'};
    }
  }
}
