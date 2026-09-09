import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';

class SaldoAlamatService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Mengambil rincian saldo dompet warga, riwayat mutasi, dan pengajuan penarikan
  Future<Map<String, dynamic>> getSaldo() async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi telah berakhir, silakan login.'};
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/saldo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal memuat saldo'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  /// Mengajukan penarikan saldo ke rekening bank / e-wallet
  Future<Map<String, dynamic>> tarikSaldo({
    required double amount,
    required String namaBank,
    required String noRekening,
    required String namaPemilik,
    String? catatan,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi telah berakhir, silakan login.'};
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/saldo/tarik'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amount,
          'nama_bank': namaBank,
          'no_rekening': noRekening,
          'nama_pemilik': namaPemilik,
          if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal mengajukan penarikan'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  /// Membatalkan pengajuan penarikan yang masih berstatus 'menunggu'
  Future<Map<String, dynamic>> batalTarik(int id) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi telah berakhir, silakan login.'};
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/saldo/tarik/$id/batal'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal membatalkan pengajuan'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  /// Mengambil daftar alamat tersimpan milik warga
  Future<Map<String, dynamic>> getAlamat() async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi telah berakhir, silakan login.'};
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/alamat'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'data': data['data'] ?? []};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal memuat alamat'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  /// Menambah alamat baru
  Future<Map<String, dynamic>> tambahAlamat(Map<String, dynamic> payload) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi telah berakhir, silakan login.'};
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/alamat'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      final data = json.decode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && data['status'] == 'success') {
        return {'success': true, 'message': data['message'], 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal menyimpan alamat'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  /// Memperbarui alamat yang sudah ada
  Future<Map<String, dynamic>> updateAlamat(int id, Map<String, dynamic> payload) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi telah berakhir, silakan login.'};
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/alamat/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message'], 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal memperbarui alamat'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  /// Menjadikan alamat sebagai alamat utama
  Future<Map<String, dynamic>> setAlamatUtama(int id) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi telah berakhir, silakan login.'};
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/alamat/$id/utama'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal mengubah alamat utama'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  /// Menghapus alamat
  Future<Map<String, dynamic>> hapusAlamat(int id) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi telah berakhir, silakan login.'};
    }

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/profile/alamat/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal menghapus alamat'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  /// Mengambil hierarki wilayah (Kecamatan & Desa)
  Future<List<dynamic>> getRegions() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/kemitraan/regions'),
        headers: {'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return data['data'];
        }
      }
    } catch (_) {}
    return [];
  }
}
