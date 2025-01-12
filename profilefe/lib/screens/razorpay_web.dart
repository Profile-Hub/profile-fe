// razorpay_web.dart
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
    final options = {
      'key': apiKey,
      'amount': amount,
      'order_id': orderId,
      'name': name,
      'handler': allowInterop((response) {
        onSuccess(
          response['razorpay_payment_id'],
          response['razorpay_order_id'],
          response['razorpay_signature'],
        );
      }),
      'prefill': {
        'contact': '',
        'email': '',
      },
      'theme': {
        'color': '#2196F3',
      }
    };

    
    final jsOptions = jsify(options);
    final razorpay = RazorpayWeb(jsOptions);
    razorpay.open();
  }
}

RazorpayHandler getRazorpayHandler() => RazorpayHandler();