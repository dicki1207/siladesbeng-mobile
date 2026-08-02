import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EventService {
  static const String baseUrl = 'http://10.250.3.148:8000/api';

  Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('token');

    final Map<String, String> headers = {
      'Accept': 'application/json',
    };
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<List<dynamic>> getEvents() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/events'),
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
    required String judul,
    required String tipe,
    String? targetScope,
    String? rw,
    String? rt,
    String? koordinator,
    String? jadwal,
    String? lokasi,
    String? catatan,
    List<String>? peralatan,
    String? posterPath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      if (posterPath != null && posterPath.isNotEmpty) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/events'),
        );

        request.headers['Accept'] = 'application/json';
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        request.fields['judul'] = judul;
        request.fields['tipe'] = tipe;
        if (targetScope != null) request.fields['target_scope'] = targetScope;
        if (rw != null) request.fields['rw'] = rw;
        if (rt != null) request.fields['rt'] = rt;
        if (koordinator != null) request.fields['koordinator'] = koordinator;
        if (jadwal != null) request.fields['jadwal'] = jadwal;
        if (lokasi != null) request.fields['lokasi'] = lokasi;
        if (catatan != null) request.fields['catatan'] = catatan;

        if (peralatan != null) {
          for (int i = 0; i < peralatan.length; i++) {
            request.fields['peralatan[$i]'] = peralatan[i];
          }
        }

        var file = await http.MultipartFile.fromPath('poster', posterPath);
        request.files.add(file);

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        final responseData = json.decode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return {
            'status': 'success',
            'message': responseData['message'] ?? 'Event berhasil dibuat.',
            'data': responseData['data'],
          };
        } else {
          return {
            'status': 'error',
            'message': responseData['message'] ?? 'Gagal membuat event.',
            'errors': responseData['errors'],
          };
        }
      } else {
        final headers = await _getHeaders(isJson: true);
        final body = json.encode({
          'judul': judul,
          'tipe': tipe,
          'target_scope': targetScope,
          'rw': rw,
          'rt': rt,
          'koordinator': koordinator,
          'jadwal': jadwal,
          'lokasi': lokasi,
          'catatan': catatan,
          'peralatan': peralatan,
        });

        final response = await http.post(
          Uri.parse('$baseUrl/events'),
          headers: headers,
          body: body,
        );

        final responseData = json.decode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return {
            'status': 'success',
            'message': responseData['message'] ?? 'Event berhasil dibuat.',
            'data': responseData['data'],
          };
        } else {
          return {
            'status': 'error',
            'message': responseData['message'] ?? 'Gagal membuat event.',
            'errors': responseData['errors'],
          };
        }
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> toggleJoin(int eventId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/events/$eventId/join'),
        headers: headers,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'joined': responseData['joined'] ?? false,
          'jumlah_peserta': responseData['jumlah_peserta'] ?? 0,
          'message': responseData['message'] ?? '',
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Gagal mengubah status kehadiran',
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
