import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();
  User? _user;

  User? get user => _user;

  Future<void> setUser(User user) async {
    _user = user;
    print(_user);
    await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> updateUser(Map<String, dynamic> userData) async {
    try {
      final response = await _authService.makeAuthenticatedRequest(
        '/update-profile',
        'PUT',
        body: userData,
      );

      if (response != null && response.statusCode == 200) {
        final updatedUser = User.fromJson(jsonDecode(response.body)['user']);
        await setUser(updatedUser);
      }
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  Future<void> loadUser() async {
    try {
      final userJson = await _storage.read(key: 'user_data');
      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}