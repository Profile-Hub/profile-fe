import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  final _storage = const FlutterSecureStorage();
  
  User? get user => _user;

  Future<void> initializeFromSecureStorage() async {
    final userJson = await _storage.read(key: 'user_data');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }

  Future<User?> getCurrentUser() async {
    if (_user != null) return _user;
    
    final userJson = await _storage.read(key: 'user_data');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
    return _user;
  }

  Future<void> setUser(User user) async {
    _user = user;
    await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<void> clearUser() async {
    _user = null;
    await _storage.delete(key: 'user_data');
    notifyListeners();
  }

  Future<void> updateUser(User updatedUser) async {
    await setUser(updatedUser);
  }
}