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
    required String password,
  }) async {
    final url = Uri.parse('${ServerConfig.baseUrl}/register');
    final headers = {'Content-Type': 'application/json'};
    
    
    final DateTime parsedDate = DateTime.parse(dateOfBirth);
    final String formattedDate = "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";

    final body = jsonEncode({
      'firstname': firstName,
      'midname': middleName,
      'lastname': lastName,
      'email': email,
      'dateofbirth': formattedDate,
      'gender': gender,
      'usertype': userType.toLowerCase(),
      'country': country,
      'state': state,
      'city': city,
      'password': password,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      
      if (response.statusCode == 201) {
        return true;
      } 
      final error = jsonDecode(response.body);
      throw error['message'] ?? 'Signup failed';
    } catch (e) {
      print('Exception during signup: $e');
      rethrow;
    }
  }
}