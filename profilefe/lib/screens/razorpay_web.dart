@JS()
library razorpay_web;

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('Razorpay')
class RazorpayWeb {
  external RazorpayWeb(Object options);
  external void open();
}

class RazorpayHandler {
  Future<void> initializePayment({
    required String apiKey,
    required String orderId,
    required int amount,
    required String name,
    required Function(String paymentId, String orderId, String signature) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final options = {
        'key': apiKey,
        'amount': amount,
        'order_id': orderId,
        'name': name,
        'handler': allowInterop((response) {
          try {
            final paymentId = getProperty(response, 'razorpay_payment_id') as String?;
            final responseOrderId = getProperty(response, 'razorpay_order_id') as String?;
            final signature = getProperty(response, 'razorpay_signature') as String?;

            if (paymentId == null || responseOrderId == null || signature == null) {
              onError('Invalid payment response: Missing required fields');
              return;
            }

            onSuccess(paymentId, responseOrderId, signature);
          } catch (e) {
            onError('Error processing payment response: $e');
          }
        }),
        'prefill': {
          'contact': '',
          'email': '',
        },
        'theme': {
          'color': '#2196F3',
        },
        'modal': {
          'ondismiss': allowInterop(() {
            onError('Payment cancelled by user');
          }),
        }
      };

      final jsOptions = jsify(options);
      final razorpay = RazorpayWeb(jsOptions);
      razorpay.open();
    } catch (e) {
      onError('Failed to initialize payment: $e');
    }
  }
}

RazorpayHandler getRazorpayHandler() => RazorpayHandler();