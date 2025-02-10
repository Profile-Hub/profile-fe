@JS()
library cashfree_web;

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('Cashfree')
external PG? get cashfreePG; // Ensure it's nullable to prevent direct access errors

@JS()
@anonymous
class PG {
  external void initiatePayment(Object options);
}

@JS()
external bool isCashfreeLoaded(); // This function checks if Cashfree is loaded

@JS()
@anonymous
class CashfreeResponse {
  external String get transaction_id;
  external String get order_id;
  external String get signature;
}

class CashfreeHandler {
  Future<void> initializePayment({
    required String apiKey,
    required String orderId,
    required int amount,
    required String name,
    required String sessionId,
    required String paymentUrl,
    String? customerEmail,
    String? customerPhone,
    required Function(String paymentId, String orderId, String signature) onSuccess,
    required Function(String error) onError,
  }) async {
    try {

      if (!isCashfreeLoaded()) {
        throw Exception("Cashfree SDK is not loaded. Ensure it's included in index.html.");
      }

      if (cashfreePG == null) {
        throw Exception("Cashfree PG instance is null. Check if the SDK is properly initialized.");
      }

      final options = jsify({
        'orderToken': sessionId, // Use correct session key
        'orderAmount': (amount / 100).toStringAsFixed(2), // Convert to string with 2 decimal places
        'customerName': name,
        'orderCurrency': 'INR',
        'appId': apiKey,
        'customerPhone': customerPhone ?? '',
        'customerEmail': customerEmail ?? '',
        'stage': 'TEST', // Change to 'PROD' in production
        'orderNote': 'Subscription Payment',
        'components': ['card', 'app', 'upi', 'netbanking', 'wallet'],
        'onSuccess': allowInterop((CashfreeResponse response) {
          if (response.transaction_id.isNotEmpty) {
            onSuccess(response.transaction_id, response.order_id, response.signature);
          } else {
            onError("Transaction failed. No transaction ID received.");
          }
        }),
        'onFailure': allowInterop((error) {
          onError("Payment failed: ${error.toString()}");
        }),
        'onCancel': allowInterop((_) {
          onError('Payment was cancelled by the user.');
        }),
        'style': {
          'backgroundColor': '#ffffff',
          'color': '#2196F3',
          'fontFamily': 'Roboto',
          'fontSize': '14px',
          'errorColor': '#ff0000',
          'theme': 'light'
        }
      });

      cashfreePG!.initiatePayment(options);
    } catch (e) {
      onError("Error initializing payment: ${e.toString()}");
    }
  }
}
