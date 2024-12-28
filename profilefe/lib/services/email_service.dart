import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/email_model.dart';
import '../server_config.dart';  

class EmailVerificationService {
  final String baseUrl = ServerConfig.baseUrl;  

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
}