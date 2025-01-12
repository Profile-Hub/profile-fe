class Avatar {
  final String url;

  Avatar({required this.url});

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(url: json['url']);
  }
}

class SelectedDoner {
  final String id;
  final String firstname;
  final String lastname;
  final Avatar avatar;

  SelectedDoner({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.avatar,
  });

  factory SelectedDoner.fromJson(Map<String, dynamic> json) {
    return SelectedDoner(
      id: json['_id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      avatar: Avatar.fromJson(json['avatar']),
    );
  }
}

class SelectedDonerResponse {
  final bool success;
  final List<SelectedDoner> data;

  SelectedDonerResponse({required this.success, required this.data});

  factory SelectedDonerResponse.fromJson(Map<String, dynamic> json) {
    return SelectedDonerResponse(
      success: json['success'],
      data: (json['data'] as List)
          .map((donorJson) => SelectedDoner.fromJson(donorJson))
          .toList(),
    );
  }
}
