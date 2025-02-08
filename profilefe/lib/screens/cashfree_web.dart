// File: lib/payment/cashfree_web.dart

@JS()
library cashfree_web;

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('Cashfree')
class CashfreeWeb {
  external CashfreeWeb(Object options);
  external void initiate();
}

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
    String? customerEmail,
    String? customerPhone,
    required Function(String paymentId, String orderId, String signature) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final options = {
        'orderToken': sessionId,
        'orderAmount': amount / 100,
        'customerName': name,
        'orderCurrency': 'INR',
        'appId': apiKey,
        'customerPhone': customerPhone ?? '',
        'customerEmail': customerEmail ?? '',
        'stage': 'TEST',
        'orderNote': 'Subscription Payment',
        'components': ['card', 'app', 'upi', 'netbanking', 'wallet'],
        'onSuccess': allowInterop((CashfreeResponse response) {
          onSuccess(
            response.transaction_id,
            response.order_id,
            response.signature,
          );
        }),
        'onFailure': allowInterop((error) {
          onError(error.toString());
        }),
        'onCancel': allowInterop((_) {
          onError('Payment cancelled');
        }),
        'style': {
          'backgroundColor': '#ffffff',
          'color': '#2196F3',
          'fontFamily': 'Roboto',
          'fontSize': '14px',
          'errorColor': '#ff0000',
          'theme': 'light'
        }
      };

      final jsOptions = jsify(options);
      final cashfree = CashfreeWeb(jsOptions);
      cashfree.initiate();
    } catch (e) {
      onError(e.toString());
    }
  }
}