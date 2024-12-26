import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:profilefe/server_config.dart';

class AuthService {
  Future<String?> login(String email, String password) async {
    final url = Uri.parse('${ServerConfig.baseUrl}/auth/login');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'email': email, 'password': password});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['auth_token']; // Replace with actual key from the API response
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception: $e');
    }
    return null;
  }
}
