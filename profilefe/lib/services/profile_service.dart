import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';

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
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
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
        headers: {
          'Content-Type': 'application/json',
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

  Future<User> uploadProfileImage({
    required dynamic imageFile,  // Can be File or Uint8List
    required String fileName,
    required String mimeType,
  }) async {
    await _loadToken();

    try {
      // Create multipart request
      var uri = Uri.parse('$baseUrl/upload-profile-photo');
      var request = http.MultipartRequest('POST', uri);
      
      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $_token',
      });

      // Handle file upload based on platform
      if (kIsWeb) {
        // Web platform - imageFile should be Uint8List
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageFile as Uint8List,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        );
      } else {
        // Native platforms - imageFile should be File
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            (imageFile as io.File).path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['success'] == true && data['user'] != null) {
          return User.fromJson(data['user']);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }
}