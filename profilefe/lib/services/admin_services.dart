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
      List<VerificationRequest> users = (data['documents'] as List)
          .map((user) => VerificationRequest.fromJson(user))
          .toList();
      return users;
    } else {
      throw Exception('Failed to fetch user requests. Status Code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to connect to server: $e');
  }
}


  Future<VerificationResponse> approveOrRejectVerification(String documentId, bool approve) async {
    await _loadToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin-VerifyOrReject-Document'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'documentId': documentId,
          'approve': approve,
        }),
      );

      if (response.statusCode == 200) {
        return VerificationResponse.fromJson(json.decode(response.body));
      } else {
        return VerificationResponse(
          success: false,
          message: 'Failed to process verification. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      return VerificationResponse(
        success: false,
        message: 'Failed to connect to server: $e',
      );
    }
  }
}