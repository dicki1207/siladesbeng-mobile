import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MutasiService {
  static const String baseUrl = 'http://10.121.197.148:8000/api';

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

  Future<List<dynamic>> getMyMutations() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/mutasi'),
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

  Future<Map<String, dynamic>> store({
    required String nama,
    required String nik,
    String? noKk,
    required String desaAsal,
    required String desaTujuan,
    String? alamat,
    String? statusPemohon,
    required String alasan,
    required String tipe,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'nama': nama,
        'nik': nik,
        'no_kk': noKk,
        'desa_asal': desaAsal,
        'desa_tujuan': desaTujuan,
        'alamat': alamat,
        'status_pemohon': statusPemohon,
        'alasan': alasan,
        'tipe': tipe,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/mutasi'),
        headers: headers,
        body: body,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'message': responseData['message'] ?? 'Pengajuan mutasi domisili berhasil dikirim.',
          'data': responseData['data'],
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Gagal mengajukan mutasi domisili',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> cancel(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/mutasi/$id'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': responseData['message'] ?? 'Pengajuan mutasi berhasil dibatalkan.',
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Gagal membatalkan pengajuan mutasi',
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
