import 'package:flutter_cashfree_pg_sdk/flutter_cashfree_pg_sdk.dart';

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
      // Prepare input parameters for Cashfree Payment Gateway SDK
      Map<String, dynamic> inputParams = {
        "orderId": orderId,
        "orderAmount": (amount / 100).toStringAsFixed(2), // Ensure proper decimal format
        "customerName": name,
        "orderCurrency": "INR",
        "appId": apiKey,
        "customerPhone": customerPhone ?? "",
        "customerEmail": customerEmail ?? "",
        "stage": "TEST", // Change to "PROD" in production
        "orderNote": "Subscription Payment",
        "paymentSessionId": sessionId,
      };

      print("Initializing payment with params: $inputParams");

      // Call Cashfree SDK for payment processing
      final result = await CashfreePGSDK.doPayment(inputParams);

      if (result == null) {
        onError("Payment was cancelled by the user.");
        return;
      }

      print("Cashfree Payment Response: $result");

      // Extract payment details
      final status = result['txStatus']?.toString().toUpperCase();
      final paymentId = result['referenceId']?.toString();
      final responseOrderId = result['orderId']?.toString();
      final signature = result['signature']?.toString();
      final transactionMessage = result['txMsg']?.toString() ?? "Unknown error occurred";

      if (status == "SUCCESS" && paymentId != null && responseOrderId != null && signature != null) {
        print("Payment Successful: Payment ID: $paymentId, Order ID: $responseOrderId");
        onSuccess(paymentId, responseOrderId, signature);
      } else {
        print("Payment Failed: $transactionMessage");
        onError("Payment failed: $transactionMessage");
      }
    } catch (e) {
      print("Payment initialization failed: $e");
      onError("Payment initialization failed: ${e.toString()}");
    }
  }
}
