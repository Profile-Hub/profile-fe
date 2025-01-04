class VerificationRequest {
  final String documentId;
  final UserDetails? userId;

  VerificationRequest({required this.documentId, this.userId});

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    return VerificationRequest(
      documentId: json['_id'] ?? '',
      userId: json['userId'] != null ? UserDetails.fromJson(json['userId']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': documentId,
      'userId': userId?.toJson(),
    };
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
  final List<String> organDonations;
  final String avatarUrl;

  UserDetails({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.bloodGroup,
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
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      organDonations: List<String>.from(json['organDonations'] ?? []),
      avatarUrl: json['avatar'] != null ? json['avatar']['url'] : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstname': firstName,
      'lastname': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'bloodGroup': bloodGroup,
      'city': city,
      'state': state,
      'country': country,
      'organDonations': organDonations,
      'avatar': {'url': avatarUrl},
    };
  }
}


class VerificationResponse {
  final bool success;
  final String message;

  VerificationResponse({required this.success, required this.message});

  factory VerificationResponse.fromJson(Map<String, dynamic> json) {
    return VerificationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
