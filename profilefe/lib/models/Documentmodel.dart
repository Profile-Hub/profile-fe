class Document {
  String id; 
  String userId;
  Map<String, String>? files; 

  Document({
    required this.id,
    required this.userId,
    this.files,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    Map<String, String> files = {};
    json.forEach((key, value) {
      if (key != 'userId' && key != '_id' && value != null) {
        files[key] = value.toString();  // Convert value to string
      }
    });

    return Document(
      id: json['_id']?.toString() ?? '',  // Convert id to string
      userId: json['userId']?.toString() ?? '',  // Convert userId to string
      files: files.isNotEmpty ? files : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = id; 
    data['userId'] = userId;
    if (files != null) {
      files!.forEach((key, value) {
        data[key] = value;
      });
    }
    return data;
  }
}
