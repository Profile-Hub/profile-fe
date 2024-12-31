import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';
import '../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static final _storage = FlutterSecureStorage();
  String? _token;
final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId: '989849803787-c3n88dvvglbn5qei6d8ev5vf7b6evgcj.apps.googleusercontent.com',
  // serverClientId: '989849803787-c3n88dvvglbn5qei6d8ev5vf7b6evgcj.apps.googleusercontent.com',
  scopes: [
    'email',
    'profile',
    'openid',
  ],
);
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

 Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
     await _loadToken();
    final url = Uri.parse('${ServerConfig.baseUrl}/update-password');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json',
                'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update password: ${response.body}');
    }
  }

  Future<LoginResponse?> signInWithFacebook() async {
    try {
      // Trigger Facebook login flow
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // Get access token
        final String accessToken = result.accessToken!.token;

        // Call your backend API
        final url = Uri.parse('${ServerConfig.baseUrl}/Facebook-login');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'accessToken': accessToken,
          }),
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final loginResponse = LoginResponse.fromJson(jsonResponse);

          if (loginResponse.success) {
            _token = loginResponse.token;
            await _storage.write(key: 'auth_token', value: _token);
          }
          return loginResponse;
        }
      }
      return null;
    } catch (e) {
      print('Facebook login error: $e');
      return null;
    }
  }

  Future<LoginResponse?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;

      if (accessToken != null) {
        // Call your backend API
        final url = Uri.parse('${ServerConfig.baseUrl}/google-login');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idToken': googleAuth.idToken, 
          }),
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final loginResponse = LoginResponse.fromJson(jsonResponse);

          if (loginResponse.success) {
            _token = loginResponse.token;
            await _storage.write(key: 'auth_token', value: _token);
          }
          return loginResponse;
        }
      }
      return null;
    } catch (e) {
      print('Google login error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
      await _googleSignIn.signOut();
      await logout(); // Your existing logout method
    } catch (e) {
      print('Error signing out: $e');
    }
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
