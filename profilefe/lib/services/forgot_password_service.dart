import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/email_model.dart';
import '../server_config.dart';
import 'email_service.dart';

class ForgotPasswordService {
  final String baseUrl = ServerConfig.baseUrl;
  final EmailVerificationService _emailVerificationService = EmailVerificationService();

  Future<EmailVerificationResponse> sendOtp(String email) {
    
    return _emailVerificationService.sendOtp(email);
  }

  Future<EmailVerificationResponse> verifyOtp(String email, String otp) {
    return _emailVerificationService.verifyOtp(email, otp);
  }

  Future<EmailVerificationResponse> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forget-Password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'newPassword': newPassword,
        }),
      );
      return EmailVerificationResponse.fromJson(json.decode(response.body));
    } catch (e) {
      return EmailVerificationResponse(success: false, message: 'Failed to reset password');
    }
  }
}
