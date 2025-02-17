import 'avatar.dart';

class Doner {
  Avatar? avatar;
  final String firstname;
  final String lastname;
  final String? middleName;
  final int? age;
  bool? isVerified;
  bool? isVerifiedDocument;
  final String? gender;
  final String? city;
  final String? state;
  final String? country;
  final String? usertype;
  final String? bloodGroup;
  final String id;
  final List<String>? organDonations;

  Doner({
    this.avatar,
    required this.firstname,
    required this.lastname,
    this.middleName,
    this.age,
    this.isVerified,
    this.isVerifiedDocument,
    this.gender,
    this.city,
    this.state,
    this.country,
    this.usertype,
    this.bloodGroup,
    required this.id,
    this.organDonations,
  });

  factory Doner.fromJson(Map<String, dynamic> json) {
    return Doner(
      avatar: json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      middleName: json['middleName'],
      age: json['age'],
      isVerified:json['isVerified'],
      isVerifiedDocument:json['isVerifiedDocument'],
      gender: json['gender'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      bloodGroup: json['bloodGroup'],
      usertype: json['usertype'],
      id: json['id'] ?? 'default_id',
      organDonations: (json['organDonations'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList(), 
    );
  }
}
