import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';
import '../server_config.dart';

class AuthService {
  Future<LoginResponse?> login(String email, String password) async {
    final url = Uri.parse('${ServerConfig.baseUrl}/loginuser');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        final jsonResponse = jsonDecode(response.body);
        return LoginResponse.fromJson(jsonResponse);
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }
    Future<bool> logout() async {
    final url = Uri.parse('${ServerConfig.baseUrl}/logoutuser');
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.post(url, headers: headers);
      print('Logout response: ${response.body}');
      
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }
}

