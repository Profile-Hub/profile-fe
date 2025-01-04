import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/adminmodel.dart';
import '../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AdminService {
  final String baseUrl = ServerConfig.baseUrl;
  String? _token;
  static final _storage = FlutterSecureStorage();

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }

  
  Future<List<VerificationRequest>> requestVerification() async {
    await _loadToken();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-AllUser-Requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<VerificationRequest> users = [];
        for (var user in data['documents']) {
          users.add(VerificationRequest.fromJson(user));
        }
        return users;
      } else {
        throw Exception('Failed to fetch user requests. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }


  Future<VerificationResponse> approveOrRejectVerification(String userId, bool approve) async {
    await _loadToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin-VerifyOrReject-Document'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'userId': userId,
          'approve': approve,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return VerificationResponse.fromJson(data);
      } else {
        throw Exception('Failed to process verification. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
