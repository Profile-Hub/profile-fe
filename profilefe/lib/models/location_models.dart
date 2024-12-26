class Country {
  final String name;
  final String shortName;
  final int phoneCode;

  Country({
    required this.name,
    required this.shortName,
    required this.phoneCode,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['country_name'],
      shortName: json['country_short_name'],
      phoneCode: json['country_phone_code'],
    );
  }
}

class State {
  final String name;

  State({required this.name});

  factory State.fromJson(Map<String, dynamic> json) {
    return State(
      name: json['state_name'],
    );
  }
}

class City {
  final String name;

  City({required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['city_name'],
    );
  }
}