class EmailVerificationResponse {
  final bool success;
  final String message;

  EmailVerificationResponse({
    required this.success,
    required this.message,
  });

  factory EmailVerificationResponse.fromJson(Map<String, dynamic> json) {
    return EmailVerificationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}