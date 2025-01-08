import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/subscription.dart';
import '../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SubscriptionService {
  final String baseUrl = ServerConfig.baseUrl;
    String? _token;
  static final _storage = FlutterSecureStorage();

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }
  Future<SubscriptionStatus> checkSubscriptionStatus() async {
    await _loadToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscription-status'),
        headers: {
          'Authorization': 'Bearer $_token', 
        },
      );

      if (response.statusCode == 200) {
        return SubscriptionStatus.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to check subscription status');
      }
    } catch (e) {
      throw Exception('Error checking subscription status: $e');
    }
  }

  Future<bool> deductCredit() async {
    await _loadToken();
    try {
      
      final response = await http.post(
        Uri.parse('$baseUrl/deduct-credits'),
        headers: {
          'Authorization': 'Bearer $_token', 
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 400) {
        return false; 
      } else {
        throw Exception('Failed to deduct credit');
      }
    } catch (e) {
      throw Exception('Error deducting credit: $e');
    }
  }
}