class Avatar {
  final String userId;
  final String url;

  Avatar({
    required this.userId,
    required this.url,
  });

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      userId: json['user_id'] as String,
      url: json['url'] as String,
    );
  }

  toJson() {}
}


