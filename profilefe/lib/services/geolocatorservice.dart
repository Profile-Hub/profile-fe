import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../server_config.dart';

class GeolocatorService {
  final String baseUrl = ServerConfig.baseUrl;
  String? _token;
  static final _storage = FlutterSecureStorage();

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }

  Future<bool> postLocation() async {
    await _loadToken();
    
    try {
      // Get location from secure storage
      final latitude = await _storage.read(key: 'user_latitude');
      final longitude = await _storage.read(key: 'user_longitude');
      
      if (latitude == null || longitude == null) {
        throw Exception('Location data not found in storage');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/update-location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'latitude': double.parse(latitude),
          'longitude': double.parse(longitude),
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      } else {
        throw Exception('Failed to post location. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  
  Future<Map<String, double>?> getStoredLocation() async {
    try {
      final latitude = await _storage.read(key: 'user_latitude');
      final longitude = await _storage.read(key: 'user_longitude');
      
      if (latitude != null && longitude != null) {
        return {
          'latitude': double.parse(latitude),
          'longitude': double.parse(longitude),
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get stored location: $e');
    }
  }
}