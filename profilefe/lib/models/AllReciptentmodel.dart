import 'avatar.dart';

class Recipient {
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

  Recipient({
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
  });

  // Factory constructor to create an instance from JSON
  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
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
    );
  }

  // Convert instance to JSON
  Map<String, dynamic> toJson() {
    return {
      if (avatar != null) 'avatar': avatar!.toJson(),
      'firstname': firstname,
      'lastname': lastname,
      if (middleName != null) 'middleName': middleName,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (usertype != null) 'usertype': usertype,
      'id': id,
    };
  }
}
