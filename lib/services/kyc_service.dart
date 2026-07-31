import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class KycService {
  static const String baseUrl = 'http://10.193.206.148:8000/api';

  Future<Map<String, dynamic>> processKtp({
    required String imagePath,
    String? nik,
    String? name,
    String? address,
    String? rtRw,
    String? kecamatan,
    String? desa,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/kyc/process'),
      );

      request.headers['Accept'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Input manual jika ada
      if (nik != null && nik.isNotEmpty) request.fields['nik'] = nik;
      if (name != null && name.isNotEmpty) request.fields['name'] = name;
      if (address != null && address.isNotEmpty) request.fields['address'] = address;
      if (rtRw != null && rtRw.isNotEmpty) {
        final parts = rtRw.split('/');
        if (parts.isNotEmpty) request.fields['rt'] = parts[0];
        if (parts.length >= 2) request.fields['rw'] = parts[1];
      }
      if (kecamatan != null && kecamatan.isNotEmpty) request.fields['kecamatan'] = kecamatan;
      if (desa != null && desa.isNotEmpty) request.fields['desa'] = desa;

      // File KTP
      var file = await http.MultipartFile.fromPath('ktp_image', imagePath);
      request.files.add(file);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'kyc_id': responseData['data']?['kyc_id'],
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Gagal memproses KTP'
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

  Future<Map<String, dynamic>> submitFace({
    required int kycId,
    required List<Map<String, dynamic>> faceData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final response = await http.post(
        Uri.parse('$baseUrl/kyc/submit'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'kyc_id': kycId,
          'face_data': faceData,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'status': 'success'};
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Gagal mengirim rekam wajah'
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
