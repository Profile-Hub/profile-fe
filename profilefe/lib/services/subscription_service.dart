import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/subscription.dart';
import '../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';

class CreditStatus {
  final bool success;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int credit;

  CreditStatus({
    required this.success,
    required this.status,
    this.startDate,
    this.endDate,
    required this.credit,
  });

  factory CreditStatus.fromJson(Map<String, dynamic> json) {
    return CreditStatus(
      success: json['success'],
      status: json['status'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      credit: json['credit'],
    );
  }
}

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

  Future<CreditStatus> getCreditStatus(BuildContext context) async {
    await _loadToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/credit-status'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        return CreditStatus.fromJson(json.decode(response.body));
      } else {
        String errorMessage = 'Failed to get credit status';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Error getting credit status: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      throw Exception(errorMessage);
    }
  }

  Future<bool> deductCredit(donorId) async {
    await _loadToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/select-single-doner'),
        headers: {
          'Authorization': 'Bearer $_token', 
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'donorId': donorId}),
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