import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class KemitraanService {
  // Use Laragon backend IP
  static const String baseUrl = 'http://10.250.3.148:8000/api';

  Future<List<dynamic>> getRegions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kemitraan/regions'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> checkDesaAdmin(String desaId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kemitraan/check-desa/$desaId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      return {'has_admin': false};
    } catch (e) {
      return {'has_admin': false};
    }
  }

  Future<Map<String, dynamic>> submitPartnership({
    required String applicantName,
    required String position,
    required String contactPhone,
    required String contactEmail,
    required String regionId,
    required String regionType,
    required String regionName,
    required String reason,
    required String filePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/kemitraan/gabung'),
      );

      // Add headers
      request.headers['Accept'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add text fields
      request.fields['applicant_name'] = applicantName;
      request.fields['position'] = position;
      request.fields['region_type'] = regionType;
      request.fields['region_name'] = regionName;
      request.fields['parent_region_id'] = regionId;
      request.fields['contact_phone'] = contactPhone;
      request.fields['contact_email'] = contactEmail;
      request.fields['reason'] = reason;

      // Add file
      var file = await http.MultipartFile.fromPath('document', filePath);
      request.files.add(file);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'status': 'success'};
      } else {
        var errorData = json.decode(response.body);
        return {
          'status': 'error',
          'message': errorData['message'] ?? 'Gagal mengirim pengajuan',
          'errors': errorData['errors']
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan sistem: $e'
      };
    }
  }
}
