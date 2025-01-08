import 'package:http/http.dart' as http;
import 'dart:convert';

class StripeService {
  static const String _baseUrl = 'your_backend_url';

  static Future<Map<String, dynamic>> createPaymentIntent(
      String planId, int amount) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'planId': planId,
          'amount': amount,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  static Future<Map<String, dynamic>> createSubscription(
      String planId, String paymentMethodId, [String? customerId]) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/create-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'planId': planId,
          'paymentMethodId': paymentMethodId,
          if (customerId != null) 'customerId': customerId,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to create subscription: $e');
    }
  }
}