import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:universal_io/io.dart';
import '../models/login_response.dart';
import '../models/user.dart';
import '../server_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static const _storage = FlutterSecureStorage();
  
  String? _token;
  User? _user;
  Timer? _refreshTimer;
  
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userDataKey = 'user_data';
  static const _userEmailKey = 'user_email';
  static const _userNameKey = 'user_name';
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb 
        ? '989849803787-ulkqn66upm45sn4euasbdbue60qe506r.apps.googleusercontent.com'
        : null,
    scopes: [
      'email',
      'profile',
      'openid',
      'https://www.googleapis.com/auth/userinfo.profile',
      'https://www.googleapis.com/auth/userinfo.email'
    ],
  );

  factory AuthService() {
    return _instance;
  }

  AuthService._internal() {
    // Initialize refresh timer
    _initializeTokenRefresh();
  }

  void _initializeTokenRefresh() {
    // Refresh token every 45 minutes
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 45), (_) {
      refreshToken();
    });
  }

  Future<LoginResponse?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ServerConfig.baseUrl}/loginuser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
        
        if (loginResponse.success) {
          await _saveAuthData(loginResponse);
          _initializeTokenRefresh();
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
    try {
      await _loadToken();
      
      if (_token == null) {
        await _clearAuthData();
        return true;
      }

      final response = await http.delete(
        Uri.parse('${ServerConfig.baseUrl}/logoutuser'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      await _clearAuthData();
      return response.statusCode == 200;
    } catch (e) {
      print('Logout error: $e');
      await _clearAuthData();
      return false;
    }
  }

  Future<void> _loadToken() async {
    _token = await _storage.read(key: _tokenKey);
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _loadToken();
    
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.put(
      Uri.parse('${ServerConfig.baseUrl}/update-password'),
      headers: {
        'Content-Type': 'application/json',
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

  Future<void> refreshToken() async {
    final storedRefreshToken = await _storage.read(key: _refreshTokenKey);

    if (storedRefreshToken == null) {
      print('No refresh token found.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ServerConfig.baseUrl}/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': storedRefreshToken}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        await _storage.write(key: _tokenKey, value: jsonResponse['auth_token']);
        await _storage.write(key: _refreshTokenKey, value: jsonResponse['refresh_token']);
        _token = jsonResponse['auth_token'];
      } else {
        print('Failed to refresh token: ${response.body}');
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
  }

  Future<LoginResponse?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final userInfoResponse = await http.get(
        Uri.parse('https://people.googleapis.com/v1/people/me?personFields=names,emailAddresses,photos'),
        headers: {'Authorization': 'Bearer ${googleAuth.accessToken}'},
      );

      if (userInfoResponse.statusCode != 200) {
        throw Exception('Failed to get user info: ${userInfoResponse.body}');
      }

      final userInfo = json.decode(userInfoResponse.body);
      final payload = _createGooglePayload(googleAuth, userInfo);

      final response = await http.post(
        Uri.parse('${ServerConfig.baseUrl}/google-login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
        
        if (loginResponse.success) {
          await _saveGoogleAuthData(loginResponse, payload);
          _initializeTokenRefresh();
        }
        return loginResponse;
      }
      return null;
    } catch (e) {
      print('Google login error: $e');
      return null;
    }
  }

  Map<String, dynamic> _createGooglePayload(
    GoogleSignInAuthentication auth,
    Map<String, dynamic> userInfo,
  ) {
    return {
      'accessToken': auth.accessToken,
      'idToken': auth.idToken,
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'email': _extractEmail(userInfo),
      'displayName': _extractDisplayName(userInfo),
      'photoUrl': _extractPhotoUrl(userInfo),
    };
  }

  String _extractEmail(Map<String, dynamic> userInfo) {
    return userInfo['emailAddresses']?.first['value'] ?? '';
  }

  String _extractDisplayName(Map<String, dynamic> userInfo) {
    return userInfo['names']?.first['displayName'] ?? '';
  }

  String _extractPhotoUrl(Map<String, dynamic> userInfo) {
    return userInfo['photos']?.first['url'] ?? '';
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await logout();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<http.Response?> makeAuthenticatedRequest(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
  }) async {
    await _loadToken();
    
    if (_token == null) {
      await refreshToken();
      await _loadToken();
      
      if (_token == null) {
        throw Exception('Authentication required');
      }
    }

    final url = Uri.parse('${ServerConfig.baseUrl}$endpoint');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };

    try {
      switch (method) {
        case 'GET':
          return await http.get(url, headers: headers);
        case 'POST':
          return await http.post(url, headers: headers, body: jsonEncode(body));
        case 'PUT':
          return await http.put(url, headers: headers, body: jsonEncode(body));
        case 'DELETE':
          return await http.delete(url, headers: headers);
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }
    } catch (e) {
      print('Error making authenticated request: $e');
      return null;
    }
  }

  Future<void> _saveAuthData(LoginResponse loginResponse) async {
    _token = loginResponse.token;
    final userJson = jsonEncode(loginResponse.user.toJson());
    
    await _storage.write(key: _tokenKey, value: _token);
    await _storage.write(key: _userDataKey, value: userJson);
  }

  Future<void> _saveGoogleAuthData(
    LoginResponse loginResponse,
    Map<String, dynamic> payload,
  ) async {
    _token = loginResponse.token;
    final userJson = jsonEncode(loginResponse.user.toJson());
    
    await _storage.write(
      key: _tokenKey,
      value: _token,
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      aOptions: const AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
    await _storage.write(key: _userDataKey, value: userJson);
    await _storage.write(key: _userEmailKey, value: payload['email']);
    await _storage.write(key: _userNameKey, value: payload['displayName']);
  }

  Future<void> _clearAuthData() async {
    _token = null;
    _user = null;
    _refreshTimer?.cancel();
    await _storage.deleteAll();
  }

  // Cleanup method to be called when the app is closed
  void dispose() {
    _refreshTimer?.cancel();
  }
}