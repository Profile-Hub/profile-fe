
class VerificationRequest {
  final UserDetails user;

  VerificationRequest({required this.user});

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    return VerificationRequest(
      user: UserDetails.fromJson(json),
    );
  }
}

class UserDetails {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String bloodGroup;
  final String city;
  final String state;
  final String country;
  final bool isVerifiedDocument;
  final List<String> organDonations;
  final String avatarUrl;

  UserDetails({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.bloodGroup,
    required this.isVerifiedDocument,
    required this.city,
    required this.state,
    required this.country,
    required this.organDonations,
    required this.avatarUrl,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['_id'] ?? '',
      firstName: json['firstname'] ?? '',
      lastName: json['lastname'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      isVerifiedDocument: json['isVerifiedDocument'] ?? false,
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      organDonations: List<String>.from(json['organDonations'] ?? []),
      avatarUrl: json['avatar'] != null ? json['avatar']['url'] : '',
    );
  }
}


class VerificationResponse {
  final bool success;
  final String message;

  VerificationResponse({required this.success, required this.message});

  factory VerificationResponse.fromJson(Map<String, dynamic> json) {
    return VerificationResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? 'No message provided',
    );
  }
}
