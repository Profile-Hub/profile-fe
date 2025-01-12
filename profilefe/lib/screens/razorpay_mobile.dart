
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayHandler {
  Future<void> initializePayment({
    required String apiKey,
    required String orderId,
    required int amount,
    required String name,
    required Function(String paymentId, String orderId, String signature) onSuccess,
    required Function(String error) onError,
  }) async {
    final razorpay = Razorpay();
    
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      onSuccess(response.paymentId!, response.orderId!, response.signature!);
      razorpay.clear();
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      onError(response.message ?? 'Payment failed');
      razorpay.clear();
    });

    final options = {
      'key': apiKey,
      'amount': amount,
      'order_id': orderId,
      'name': name,
      'prefill': const {
        'contact': '',
        'email': '',
      },
      'theme': {
        'color': '#2196F3',
      }
    };

    razorpay.open(options);
  }
}

RazorpayHandler getRazorpayHandler() => RazorpayHandler();