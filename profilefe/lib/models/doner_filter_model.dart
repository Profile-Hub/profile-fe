class DonorFilter {
  final String? state;
  final String? city;
  final double? radius;
  final int? minAge;
  final int? maxAge;
  final String? gender;
  final bool? isOrganDonor;

  DonorFilter({
    this.state,
    this.city,
    this.radius,
    this.minAge,
    this.maxAge,
    this.gender,
    this.isOrganDonor,
  });

  Map<String, dynamic> toJson() {
    return {
      if (state != null) 'state': state,
      if (city != null) 'city': city,
      if (radius != null) 'radius': radius,
      if (minAge != null) 'minAge': minAge,
      if (maxAge != null) 'maxAge': maxAge,
      if (gender != null) 'gender': gender,
      if (isOrganDonor != null) 'isOrganDonor': isOrganDonor,
    };
  }
}
