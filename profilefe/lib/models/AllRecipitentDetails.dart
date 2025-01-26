import 'avatar.dart';


class RecipitentDetails {
  final Avatar? avatar;
  final String id;
  final String firstname;
  final String middlename;
  final String lastname;
  final String gender;
  final DateTime dateofbirth;
  final String country;
  final String state;
  final String city;
  final String bloodGroup;

  RecipitentDetails({
    this.avatar,
    required this.id,
    required this.firstname,
    required this.middlename,
    required this.lastname,
    required this.gender,
    required this.dateofbirth,
    required this.country,
    required this.state,
    required this.city,
    required this.bloodGroup,
  });

  factory RecipitentDetails.fromJson(Map<String, dynamic> json) {
    return RecipitentDetails(
      avatar: json['avatar'] != null ? Avatar.fromJson(json['avatar']) : null,
      id: json['id'],
      firstname: json['firstname'],
      middlename: json['middlename'],
      lastname: json['lastname'],
      gender: json['gender'],
      dateofbirth: DateTime.parse(json['dateofbirth']),
      country: json['country'],
      state: json['state'],
      city: json['city'],
      bloodGroup: json['bloodGroup'],
    );
  }
}
