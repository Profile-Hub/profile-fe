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
    id: json['id'] ?? '',
    firstname: json['firstname'] ?? 'Unknown',
    middlename: json['middlename'] ?? '', // Set to empty string if null
    lastname: json['lastname'] ?? 'Unknown',
    gender: json['gender'] ?? 'N/A',
    dateofbirth: json['dateofbirth'] != null 
        ? DateTime.tryParse(json['dateofbirth']) ?? DateTime(2000, 1, 1) 
        : DateTime(2000, 1, 1), // Default date if parsing fails
    country: json['country'] ?? 'N/A',
    state: json['state'] ?? 'N/A',
    city: json['city'] ?? 'N/A',
    bloodGroup: json['bloodGroup'] ?? 'N/A',
  );
}
}
