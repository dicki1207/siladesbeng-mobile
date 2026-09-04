import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';

class UnitChatService {
  static const String baseUrl = '${ApiConfig.baseUrl}/api';

  Future<Map<String, String>> _getHeaders({String? sessionToken}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('token');

    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (sessionToken != null && sessionToken.isNotEmpty) {
      headers['X-Chat-Session-Token'] = sessionToken;
    }

    return headers;
  }

  Future<String?> getSavedSessionToken(String service) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('unit_chat_token_$service');
  }

  Future<void> saveSessionToken(String service, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unit_chat_token_$service', token);
  }

  /// Ambil riwayat percakapan untuk layanan tertentu
  Future<Map<String, dynamic>> getChatHistory(
    String service, {
    String? sessionToken,
    int? regionId,
  }) async {
    try {
      final token = sessionToken ?? await getSavedSessionToken(service);
      final headers = await _getHeaders(sessionToken: token);

      String url = '$baseUrl/unit-chat/$service/history';
      final queryParams = <String, String>{};
      if (token != null && token.isNotEmpty) {
        queryParams['session_token'] = token;
      }
      if (regionId != null) {
        queryParams['region_id'] = regionId.toString();
      }

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final session = data['data']['session'];
          if (session != null && session['session_token'] != null) {
            await saveSessionToken(service, session['session_token'].toString());
          }
        }
        return data;
      }
      return {'status': 'error', 'message': 'Gagal memuat obrolan: ${response.statusCode}'};
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan jaringan: $e'};
    }
  }

  /// Kirim pesan baru
  Future<Map<String, dynamic>> sendChatMessage(
    String service,
    String message, {
    String? sessionToken,
    int? regionId,
    String? itemReference,
  }) async {
    try {
      final token = sessionToken ?? await getSavedSessionToken(service);
      final headers = await _getHeaders(sessionToken: token);

      final Map<String, dynamic> body = {
        'message': message,
      };

      if (token != null && token.isNotEmpty) {
        body['session_token'] = token;
      }
      if (regionId != null) {
        body['region_id'] = regionId;
      }
      if (itemReference != null && itemReference.isNotEmpty) {
        body['item_reference'] = itemReference;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/unit-chat/$service/send'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final sToken = data['data']['session_token'];
          if (sToken != null) {
            await saveSessionToken(service, sToken.toString());
          }
        }
        return data;
      }
      return {'status': 'error', 'message': 'Gagal mengirim pesan'};
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Eskalasi ke Admin Petugas Layanan
  Future<Map<String, dynamic>> escalateChat(
    String service, {
    String? sessionToken,
    int? regionId,
  }) async {
    try {
      final token = sessionToken ?? await getSavedSessionToken(service);
      final headers = await _getHeaders(sessionToken: token);

      final Map<String, dynamic> body = {};
      if (token != null) body['session_token'] = token;
      if (regionId != null) body['region_id'] = regionId;

      final response = await http.post(
        Uri.parse('$baseUrl/unit-chat/$service/escalate'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error', 'message': 'Gagal eskalasi chat'};
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
