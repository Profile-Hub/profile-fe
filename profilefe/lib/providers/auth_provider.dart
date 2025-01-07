import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../models/login_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();
  User? _currentUser;
  String? _token;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _token = await _storage.read(key: 'auth_token');
      final userJson = await _storage.read(key: 'user_data');
      
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing auth state: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _authService.login(email, password);
      
      if (response != null && response.success) {
        _currentUser = response.user;
        _token = response.token;
        
        // Store user data and token
        await _storage.write(key: 'user_data', value: jsonEncode(_currentUser!.toJson()));
        await _storage.write(key: 'auth_token', value: _token);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      final response = await _authService.signInWithGoogle();
      
      if (response != null && response.success) {
        _currentUser = response.user;
        _token = response.token;
        
        await _storage.write(key: 'user_data', value: jsonEncode(_currentUser!.toJson()));
        await _storage.write(key: 'auth_token', value: _token);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Google login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      await _storage.deleteAll();
      _currentUser = null;
      _token = null;
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword, String confirmPassword) async {
    try {
      final result = await _authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      
      return result['success'] ?? false;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }
}