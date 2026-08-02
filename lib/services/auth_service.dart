import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.193.206.148:8000/api';

  Future<Map<String, dynamic>> forgotPassword(String emailOrPhone, String method) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Accept': 'application/json'},
        body: {
          'email_or_phone': emailOrPhone,
          'otp_method': method,
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyForgotPasswordOtp(String emailOrPhone, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password/verify-otp'),
        headers: {'Accept': 'application/json'},
        body: {
          'email_or_phone': emailOrPhone,
          'otp': otp,
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String emailOrPhone, String resetToken, String password, String passwordConfirmation) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password/reset'),
        headers: {'Accept': 'application/json'},
        body: {
          'email_or_phone': emailOrPhone,
          'reset_token': resetToken,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }
}
