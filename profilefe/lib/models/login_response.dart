import 'user.dart';
class LoginResponse {
  final bool success;
  final User user;
  final String token;
  final String? message;

  LoginResponse({
    required this.success,
    required this.user,
    required this.token,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool,
      user: User.fromJson(json['user']),
      token: json['auth_token'] as String, 
      message: json['message'] as String?,
    );
  }
}
