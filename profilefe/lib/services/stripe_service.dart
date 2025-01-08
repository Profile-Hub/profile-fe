import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/foundation.dart';
import '../stripe_config.dart';
import '../server_config.dart';

class StripeService {
  static final StripeService _instance = StripeService._internal();
  
  factory StripeService() {
    return _instance;
  }

  StripeService._internal();

  final String baseUrl = ServerConfig.baseUrl;
  String? _token;
  final _storage = FlutterSecureStorage();

  static Future<void> init() async {
    if (kIsWeb) {
      // Web-specific initialization
      Stripe.publishableKey = StripeConfig.publishableKey;
      await Stripe.instance.applySettings();
    } 
    // else {
      //android and ios
    //   Stripe.publishableKey = StripeConfig.publishableKey;
    //   if (StripeConfig.merchantIdentifier != null) {
    //     await Stripe.instance.applySettings(
    //       stripeAccountId: StripeConfig.stripeAccountId ,
    //       merchantIdentifier: StripeConfig.merchantIdentifier,
    //     );
    //   } else {
    //     await Stripe.instance.applySettings();
    //   }
    // }
  }

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }

  Future<Map<String, dynamic>> createPaymentIntent(
    String planId,
    int amount,
  ) async {
    await _loadToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'planId': planId,
          'amount': amount,
          'currency': StripeConfig.currency,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  Future<void> handlePaymentSuccess(
    String paymentIntentId,
    String planId,
  ) async {
    await _loadToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment-success'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'paymentIntentId': paymentIntentId,
          'planId': planId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to confirm payment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error confirming payment: $e');
    }
  }
   Future<Map<String, dynamic>> createCheckoutSession(String planId) async {
    await _loadToken();
    final response = await http.post(
      Uri.parse('$baseUrl/create-checkout-session'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'planId': planId,
        'successUrl': 'http://localhost:3000/success',
        'cancelUrl': 'http://localhost:3000/cancel',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create checkout session');
    }
  }
}