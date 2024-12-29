import 'avatar.dart';
class User {
  final Avatar? avatar;
  final String id;
  final String firstname;
  final String lastname;
  final DateTime? dateofbirth;
  final String? gender;
  String email;
  final String? city;
  final String? state;
  final String? country;
  final String? usertype;

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
    );
  }
}
