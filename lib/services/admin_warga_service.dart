import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';

class AdminWargaService {
  String get baseUrl => '${ApiConfig.baseUrl}/api';

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

  Future<List<dynamic>> getWargaList() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/wilayah/warga'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic> && responseData['data'] is List) {
          return responseData['data'];
        } else if (responseData is List) {
          return responseData;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getWargaDetail(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/wilayah/warga/$id'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'data': responseData['data'],
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Gagal mengambil detail warga',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> approveKyc(int userId, {String? notes}) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'notes': notes,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/wilayah/warga/$userId/approve-kyc'),
        headers: headers,
        body: body,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'message': responseData['message'] ?? 'Verifikasi warga berhasil disetujui.',
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Gagal menyetujui verifikasi warga.',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> rejectKyc(int userId, {String? notes}) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'notes': notes,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/wilayah/warga/$userId/reject-kyc'),
        headers: headers,
        body: body,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'message': responseData['message'] ?? 'Verifikasi warga ditolak.',
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Gagal menolak verifikasi warga.',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
