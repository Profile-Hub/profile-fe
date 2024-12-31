import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart'; // For MIME type detection
import 'dart:io' as io; // For native platforms
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


Future<bool> updateProfileImage() async {
  await _loadToken(); // Load token (if required)

  try {
    // Open file picker for all platforms
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'], // Allowed file types
    );

    if (result == null) {
      // User canceled the picker
      return false;
    }

    PlatformFile file = result.files.first; // Selected file

    // Prepare Multipart Request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload-profile-image'), // Replace with your endpoint
    );

    // Platform-specific file handling
    if (kIsWeb) {
      // Web: Use bytes for Multipart
      Uint8List bytes = file.bytes!;
      request.files.add(http.MultipartFile.fromBytes(
        'profile_image', // Field name
        bytes,
        filename: file.name, // File name
        contentType: MediaType.parse(lookupMimeType(file.name)!),
      ));
    } else {
      // Mobile/Desktop: Use file path
      io.File physicalFile = io.File(file.path!);
      request.files.add(await http.MultipartFile.fromPath(
        'profile_image',
        physicalFile.path,
        contentType: MediaType.parse(lookupMimeType(physicalFile.path)!),
      ));
    }

    // Add Authorization Header
    request.headers['Authorization'] = 'Bearer $_token';
    request.headers['Content-Type'] = 'multipart/form-data';

    // Send request
    var response = await request.send();

    if (response.statusCode == 200) {
      print("Profile image uploaded successfully.");
      return true;
    } else {
      print("Failed to upload profile image: ${response.statusCode}");
      return false;
    }
  } catch (e) {
    print("Exception: $e");
    throw Exception('Failed to upload profile image: $e');
  }
}

}