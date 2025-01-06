import 'package:http/http.dart' as http;
import 'dart:convert';

enum PaymentMethod { card, upi }

class StripeService {
  static const String _apiUrl = 'YOUR_BACKEND_API_URL';

  static Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String planId,
    required PaymentMethod paymentMethod,
    String? upiId,
  }) async {
    try {
      final amountInSmallestUnit = (amount * 100).round();

      final response = await http.post(
        Uri.parse('$_apiUrl/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_SECRET_KEY',
        },
        body: json.encode({
          'amount': amountInSmallestUnit,
          'currency': currency.toLowerCase(),
          'planId': planId,
          'payment_method_types': [
            if (paymentMethod == PaymentMethod.card) 'card',
            if (paymentMethod == PaymentMethod.upi) 'upi',
          ],
          if (upiId != null) 'upi_id': upiId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create payment intent');
      }

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  static Future<void> confirmUPIPayment({
    required String paymentIntentId,
    required String upiId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/confirm-upi-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_SECRET_KEY',
        },
        body: json.encode({
          'payment_intent_id': paymentIntentId,
          'upi_id': upiId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to confirm UPI payment');
      }
    } catch (e) {
      throw Exception('Error confirming UPI payment: $e');
    }
  }
}
