class Doner {
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

  Doner({
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

  factory Doner.fromJson(Map<String, dynamic> json) {
    return Doner(
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
}
