import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RentalService {
  static const String baseUrl = 'http://10.193.206.148:8000/api';

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

  // ─── SEWA ALAT ───

  /// List semua alat sewa
  Future<List<dynamic>> getRentalItems() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rental/items'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Detail alat sewa
  Future<Map<String, dynamic>> getRentalItemDetail(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rental/items/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'status': 'success', 'data': data['data']};
      }
      return {'status': 'error', 'message': 'Gagal mengambil detail'};
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Booking alat sewa
  Future<Map<String, dynamic>> bookRentalItem({
    required int barangId,
    required int quantity,
    required String startDate,
    required String endDate,
    required String recipientName,
    String? deliveryAddress,
    required String paymentMethod,
    String? rentalPurpose,
    String? deliveryMethod,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'barang_id': barangId,
        'quantity': quantity,
        'start_date': startDate,
        'end_date': endDate,
        'recipient_name': recipientName,
        'delivery_address': deliveryAddress,
        'payment_method': paymentMethod,
        'rental_purpose': rentalPurpose,
        'delivery_method': deliveryMethod,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/rental/booking'),
        headers: headers,
        body: body,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'message': responseData['message'] ?? 'Booking berhasil.',
          'data': responseData['data'],
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Gagal membuat booking.',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Riwayat booking alat sewa
  Future<List<dynamic>> getMyRentalBookings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rental/my-bookings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── SEWA KENDARAAN ───

  /// List semua kendaraan
  Future<List<dynamic>> getMobilItems() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/mobil'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Detail kendaraan
  Future<Map<String, dynamic>> getMobilDetail(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/mobil/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'status': 'success', 'data': data['data']};
      }
      return {'status': 'error', 'message': 'Gagal mengambil detail'};
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Booking kendaraan
  Future<Map<String, dynamic>> bookMobil({
    required int mobilId,
    required String startDate,
    required String endDate,
    required String recipientName,
    String? deliveryAddress,
    required String paymentMethod,
    String? rentalPurpose,
    String? deliveryMethod,
    bool denganSupir = false,
    double? distanceKm,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'mobil_id': mobilId,
        'start_date': startDate,
        'end_date': endDate,
        'recipient_name': recipientName,
        'delivery_address': deliveryAddress,
        'payment_method': paymentMethod,
        'rental_purpose': rentalPurpose,
        'delivery_method': deliveryMethod,
        'dengan_supir': denganSupir,
        'distance_km': distanceKm,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/mobil/booking'),
        headers: headers,
        body: body,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'message': responseData['message'] ?? 'Booking berhasil.',
          'data': responseData['data'],
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Gagal membuat booking.',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Riwayat booking kendaraan
  Future<List<dynamic>> getMyMobilBookings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/mobil/my-bookings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── SEWA FASILITAS ───

  /// List semua fasilitas
  Future<List<dynamic>> getFasilitasItems() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/fasilitas'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Detail fasilitas
  Future<Map<String, dynamic>> getFasilitasDetail(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/fasilitas/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'status': 'success', 'data': data['data']};
      }
      return {'status': 'error', 'message': 'Gagal mengambil detail'};
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Booking fasilitas
  Future<Map<String, dynamic>> bookFasilitas({
    required int fasilitasId,
    required String startDate,
    required String endDate,
    String? rentalPurpose,
    String jenisAcara = 'sosial',
    bool butuhGudang = false,
    int quantity = 1,
    String? deliveryMethod,
    bool denganSupir = false,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'fasilitas_id': fasilitasId,
        'start_date': startDate,
        'end_date': endDate,
        'rental_purpose': rentalPurpose,
        'jenis_acara': jenisAcara,
        'butuh_gudang': butuhGudang,
        'quantity': quantity,
        'delivery_method': deliveryMethod,
        'dengan_supir': denganSupir,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/fasilitas/booking'),
        headers: headers,
        body: body,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'status': 'success',
          'message': responseData['message'] ?? 'Booking berhasil.',
          'data': responseData['data'],
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Gagal membuat booking.',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Riwayat booking fasilitas
  Future<List<dynamic>> getMyFasilitasBookings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/fasilitas/my-bookings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── CANCEL (UNIVERSAL) ───

  /// Batalkan booking alat sewa
  Future<Map<String, dynamic>> cancelRentalBooking(int id, {String? reason}) async {
    return _cancelBooking('$baseUrl/rental/booking/$id/cancel', reason);
  }

  /// Batalkan booking kendaraan
  Future<Map<String, dynamic>> cancelMobilBooking(int id, {String? reason}) async {
    return _cancelBooking('$baseUrl/mobil/booking/$id/cancel', reason);
  }

  /// Batalkan booking fasilitas
  Future<Map<String, dynamic>> cancelFasilitasBooking(int id, {String? reason}) async {
    return _cancelBooking('$baseUrl/fasilitas/booking/$id/cancel', reason);
  }

  Future<Map<String, dynamic>> _cancelBooking(String url, String? reason) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
        body: reason != null ? json.encode({'reason': reason}) : null,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': responseData['message'] ?? 'Booking berhasil dibatalkan.',
        };
      } else {
        return {
          'status': 'error',
          'message': responseData['message'] ?? 'Gagal membatalkan booking.',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
