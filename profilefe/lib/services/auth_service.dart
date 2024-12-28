import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';
import '../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static final _storage = FlutterSecureStorage();
  String? _token;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

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
        final loginResponse = LoginResponse.fromJson(jsonResponse);

        if (loginResponse.success) {
          _token = loginResponse.token;
          await _storage.write(key: 'auth_token', value: _token);
          print('Token saved: $_token');
        }
        return loginResponse;
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<bool> logout() async {
    await _loadToken(); 
    print('Token before logout: $_token');
    if (_token == null) {
      print('No token available for logout.');
      return false;
    }

    final url = Uri.parse('${ServerConfig.baseUrl}/logoutuser');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };

    try {
      final response = await http.delete(url, headers: headers);
      print('Logout response: ${response.body}');

      if (response.statusCode == 200) {
        _token = null;
        await _storage.delete(key: 'auth_token');
        return true;
      }
      return false;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }

  Future<http.Response?> makeAuthenticatedRequest(
      String endpoint, String method, {Map<String, dynamic>? body}) async {
    await _loadToken(); 
    if (_token == null) {
      print('No token available for authenticated request.');
      return null;
    }

    final url = Uri.parse('${ServerConfig.baseUrl}$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };

    try {
      if (method == 'GET') {
        return await http.get(url, headers: headers);
      } else if (method == 'POST') {
        return await http.post(url, headers: headers, body: jsonEncode(body));
      } else if (method == 'PUT') {
        return await http.put(url, headers: headers, body: jsonEncode(body));
      } else if (method == 'DELETE') {
        return await http.delete(url, headers: headers);
      } else {
        throw UnsupportedError('Unsupported HTTP method: $method');
      }
    } catch (e) {
      print('Error making authenticated request: $e');
      return null;
    }
  }
}
