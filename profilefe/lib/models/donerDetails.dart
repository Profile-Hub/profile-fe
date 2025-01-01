import 'avatar.dart';

class DonerDetails {
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

  DonerDetails({
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
  });

  factory DonerDetails.fromJson(Map<String, dynamic> json) {
    return DonerDetails(
      avatar: json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null,
      id: json['_id'] ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      dateofbirth: json['dateofbirth'] != null
          ? DateTime.tryParse(json['dateofbirth'] as String)
          : null,
      gender: json['gender'],
      email: json['email'] ?? '',
      city: json['city'],
      state: json['state'],
      country: json['country'],
      usertype: json['usertype'],
      phoneCode: json['phoneCode'] as int?,
      phoneNumber: json['phoneNumber'],
      bloodGroup: json['bloodGroup'],
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
    };
  }
}
