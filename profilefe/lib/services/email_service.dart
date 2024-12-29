import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/email_model.dart';
import '../server_config.dart';  
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class EmailVerificationService {
  final String baseUrl = ServerConfig.baseUrl; 
  String? _token;
  static final _storage = FlutterSecureStorage(); 
  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }
  Future<EmailVerificationResponse> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      return EmailVerificationResponse.fromJson(json.decode(response.body));
    } catch (e) {
      return EmailVerificationResponse(success: false, message: 'Failed to send OTP');
    }
  }

  Future<EmailVerificationResponse> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
        }),
      );

      return EmailVerificationResponse.fromJson(json.decode(response.body));
    } catch (e) {
      return EmailVerificationResponse(success: false, message: 'Failed to verify OTP');
    }
  }
  Future<EmailVerificationResponse> updateEmail(String oldEmail, String newEmail) async {
  try {
    await _loadToken(); 
    final response = await http.put(
      Uri.parse('$baseUrl/update-email'),
      headers: {'Content-Type': 'application/json',
                 'Authorization': 'Bearer $_token',
                                        
      },
      body: json.encode({'oldEmail': oldEmail, 'newEmail': newEmail}),
    );

    return EmailVerificationResponse.fromJson(json.decode(response.body));
  } catch (e) {
    return EmailVerificationResponse(success: false, message: 'Failed to update email');
  }
}

}