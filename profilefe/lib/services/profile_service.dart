import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileService {
  final String baseUrl = ServerConfig.baseUrl;
  String? _token;
  static final _storage = FlutterSecureStorage();
  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }
  Future<User> getProfile() async {
    await _loadToken(); 
    try {
      final response = await http.get(Uri.parse('$baseUrl/profile'),
        headers: {'Content-Type': 'application/json',
                   'Authorization': 'Bearer $_token',
        },
      );
       
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data['userprofile']);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    await _loadToken(); 

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/update-Profile'),
        headers: {'Content-Type': 'application/json',
                   'Authorization': 'Bearer $_token',
        },
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<bool> updateProfileImage(String imagePath) async {
    await _loadToken(); 
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/update-profile-image'),
      );
      request.files.add(await http.MultipartFile.fromPath('profile_image', imagePath),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update profile image');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
  
}
