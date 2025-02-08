import 'package:flutter_cashfree_pg_sdk/flutter_cashfree_pg_sdk.dart';

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
      Map<String, dynamic> inputParams = {
        "orderId": orderId,
        "orderAmount": amount / 100,
        "customerName": name,
        "orderCurrency": "INR",
        "appId": apiKey,
        "customerPhone": customerPhone ?? "",
        "customerEmail": customerEmail ?? "",
        "stage": "TEST", // Change to "PROD" in production
        "orderNote": "Subscription Payment",
        "paymentSessionId": sessionId,
      };

      final result = await CashfreePGSDK.doPayment(inputParams);
      if (result == null) {
        onError("Payment cancelled");
        return;
      }

      final status = result['txStatus'];
      final paymentId = result['referenceId'];
      final responseOrderId = result['orderId'];
      final signature = result['signature'];

      if (status == "SUCCESS" && paymentId != null && responseOrderId != null && signature != null) {
        onSuccess(paymentId, responseOrderId, signature);
      } else {
        onError("Payment failed: ${result['txMsg'] ?? 'Unknown error'}");
      }
    } catch (e) {
      onError(e.toString());
    }
  }
}
