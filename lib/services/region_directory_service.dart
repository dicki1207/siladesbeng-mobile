import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:siladesbeng_mobile/core/api_config.dart';

class RegionDirectoryService {
  Future<Map<String, dynamic>?> getHierarchy() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/region-hierarchy'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfile(int regionId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/region-profile/$regionId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
