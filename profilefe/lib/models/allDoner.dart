import 'avatar.dart';

class Doner {
  Avatar? avatar;
  final String firstname;
  final String lastname;
  final String? middleName;
  final int? age;
  final String? gender;
  final String? city;
  final String? state;
  final String? country;
  final String? usertype;
  final String id;
  final List<String>? organDonations;

  Doner({
    this.avatar,
    required this.firstname,
    required this.lastname,
    this.middleName,
    this.age,
    this.gender,
    this.city,
    this.state,
    this.country,
    this.usertype,
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
      gender: json['gender'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      usertype: json['usertype'],
      id: json['id'] ?? 'default_id',
      organDonations: (json['organDonations'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList(), 
    );
  }
}
