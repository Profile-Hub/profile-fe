import 'dart:convert';
import 'package:http/http.dart' as http;
import '../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class ProfileCompletionResponse {
  final bool success;
  final bool notify;
  final List<String> missingFields;
  final List<String> missingDocuments; 

  ProfileCompletionResponse({
    required this.success,
    required this.notify,
    required this.missingFields,
    required this.missingDocuments, 
  });

  factory ProfileCompletionResponse.fromJson(Map<String, dynamic> json) {
    return ProfileCompletionResponse(
      success: json['success'] ?? false,
      notify: json['notify'] ?? false,
      missingFields: List<String>.from(json['missingFields'] ?? []),
      missingDocuments: List<String>.from(json['missingDocuments'] ?? []), 
    );
  }
}



class ProfileCompletionService {
  final String baseUrl = ServerConfig.baseUrl;
   String? _token;
  static final _storage = FlutterSecureStorage();
  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }
  Future<ProfileCompletionResponse> checkProfileCompletion() async {
    try {
      await _loadToken();
      final response = await http.get(
        Uri.parse('$baseUrl/check-Profile-Completion'),
         headers: {'Content-Type': 'application/json',
                   'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ProfileCompletionResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to check profile completion');
      }
    } catch (e) {
      throw Exception('Error checking profile completion: $e');
    }
  }
}