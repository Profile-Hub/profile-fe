import 'avatar.dart';

class User {
  final Avatar? avatar;
  final String id;
  String firstname;
  String lastname;
  DateTime? dateofbirth;
  String? gender;
  String email;
  String? city;
  String? state;
  String? country;
  String? usertype;
  int? phoneCode;
  String? phoneNumber;
  String? bloodGroup;
  List<String> organDonations;

  User({
    this.avatar,
    required this.id,
    required this.firstname,
    required this.lastname,
    this.dateofbirth,
    this.gender,
    required this.email,
    this.city,
    this.state,
    this.country,
    this.usertype,
    this.phoneCode,
    this.phoneNumber,
    this.bloodGroup,
    this.organDonations = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      avatar: json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null,
      id: json['_id'] as String,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      dateofbirth: json['dateofbirth'] != null
          ? DateTime.parse(json['dateofbirth'] as String)
          : null,
      gender: json['gender'] as String?,
      email: json['email'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      usertype: json['usertype'] as String?,
      phoneCode: json['phoneCode'] as int?,
      phoneNumber: json['phoneNumber'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      organDonations: (json['organDonations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'avatar': avatar?.toJson(),
      '_id': id,
      'firstname': firstname,
      'lastname': lastname,
      'dateofbirth': dateofbirth?.toIso8601String(),
      'gender': gender,
      'email': email,
      'city': city,
      'state': state,
      'country': country,
      'usertype': usertype,
      'phoneCode': phoneCode,
      'phoneNumber': phoneNumber,
      'bloodGroup': bloodGroup,
      'organDonations': organDonations,
    };
  }
}
