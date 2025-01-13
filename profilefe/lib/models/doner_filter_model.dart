class DonorFilter {
  final String? country;
  final String? state;
  final String? city;
  final double? radius;
  final int? minAge;
  final int? maxAge;
  final String? gender;
  final List<String>? organsDonating;

  DonorFilter({
    this.country,
    this.state,
    this.city,
    this.radius,
    this.minAge,
    this.maxAge,
    this.gender,
    this.organsDonating,
  });

  Map<String, dynamic> toJson() {
    return {
      if (country != null) 'country': country,
      if (state != null) 'state': state,
      if (city != null) 'city': city,
      if (radius != null) 'radius': radius,
      if (minAge != null) 'minAge': minAge,
      if (maxAge != null) 'maxAge': maxAge,
      if (gender != null) 'gender': gender,
      if (organsDonating != null && organsDonating!.isNotEmpty) 
        'organsDonating': organsDonating,
    };
  }


  factory DonorFilter.fromJson(Map<String, dynamic> json) {
    return DonorFilter(
      country: json['country'] as String?,
      state: json['state'] as String?,
      city: json['city'] as String?,
      radius: json['radius'] as double?,
      minAge: json['minAge'] as int?,
      maxAge: json['maxAge'] as int?,
      gender: json['gender'] as String?,
      organsDonating: json['organsDonating'] != null 
          ? List<String>.from(json['organsDonating'])
          : null,
    );
  }

  
  DonorFilter copyWith({
    String? country,
    String? state,
    String? city,
    double? radius,
    int? minAge,
    int? maxAge,
    String? gender,
    List<String>? organsDonating,
  }) {
    return DonorFilter(
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      radius: radius ?? this.radius,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      gender: gender ?? this.gender,
      organsDonating: organsDonating ?? this.organsDonating,
    );
  }
}