class Country {
  final String name;
  final String phoneCode;
  final List<State>? states;

  Country({
    required this.name,
    required this.phoneCode,
    this.states,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'],
      phoneCode: json['phoneCode'] ?? '',
      states: json['states'] != null 
        ? (json['states'] as List).map((s) => State.fromJson(s)).toList()
        : null,
    );
  }
}

class State {
  final String name;
  final List<City>? cities;

  State({
    required this.name,
    this.cities,
  });

  factory State.fromJson(Map<String, dynamic> json) {
    return State(
      name: json['name'],
      cities: json['cities'] != null
        ? (json['cities'] as List).map((c) => City.fromJson(c)).toList()
        : null,
    );
  }
}

class City {
  final String name;

  City({required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(name: json['name']);
  }
}