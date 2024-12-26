import 'dart:convert';
import 'package:http/http.dart' as http;
import '../server_config.dart';

class SignupService {
  Future<bool> signup({
    required String firstName,
    String? middleName,
    required String lastName,
    required String email,
    required String dateOfBirth,
    required String gender,
    required String userType,
    required String country,
    required String state,
    required String city,
  }) async {
    final url = Uri.parse('${ServerConfig.baseUrl}/auth/signup');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'email': email,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'user_type': userType,
      'country': country,
      'state': state,
      'city': city,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        return true; // Signup success
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception during signup: $e');
    }
    return false; // Signup failed
  }
}
