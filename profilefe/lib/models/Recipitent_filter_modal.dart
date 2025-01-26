class RecipientFilter {
  final String? country;
  final String? state;
  final String? gender;
  final String? city;
  final double? radius;
  final double? latitude;
  final double? longitude;

  RecipientFilter({
    this.country,
    this.state,
    this.gender,
    this.city,
    this.radius,
    this.latitude,
    this.longitude,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (country != null) 'country': country,
      if (state != null) 'state': state,
      if (gender != null) 'gender': gender,
      if (city != null) 'city': city,
      if (radius != null) 'radius': radius,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  // Create from JSON
  factory RecipientFilter.fromJson(Map<String, dynamic> json) {
    return RecipientFilter(
      country: json['country'] as String?,
      state: json['state'] as String?,
      gender: json['gender'] as String?,
      city: json['city'] as String?,
      radius: json['radius'] as double?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }

  // Copy with method
  RecipientFilter copyWith({
    String? country,
    String? state,
    String? gender,
    String? city,
    double? radius,
    double? latitude,
    double? longitude,
  }) {
    return RecipientFilter(
      country: country ?? this.country,
      state: state ?? this.state,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      radius: radius ?? this.radius,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
