// First, add these dependencies to pubspec.yaml:
// razorpay_flutter: ^1.3.5
// shared_preferences: ^2.2.2 (for storing subscription status)
// http: ^1.1.0 (for API calls)

import 'package:flutter/material.dart' hide Card;
import 'package:flutter/material.dart' as material show Card;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Model class to represent a subscription plan
class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final int contacts;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.contacts,
    required this.features,
  });

  // Helper method to format price for display
  String get formattedPrice => '₹${(price / 100).toStringAsFixed(2)}';
}
  final String baseUrl = ServerConfig.baseUrl;
    String? _token;
   final _storage = FlutterSecureStorage();
// Service class to handle all Razorpay-related operations
class RazorpayService {
  final String apiUrl = 'http://localhost:4000'; 
  final String apiKey = 'rzp_test_Z3Ii9PSZueytu2'; 
  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }
  // Create order on the backend
  Future<Map<String, dynamic>> createOrder(String planId, int amount) async {
    try {
      await _loadToken();
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
          
        },
        body: jsonEncode({
          'planId': planId,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create order: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Verify payment with backend
  Future<void> verifyPayment(String orderId, String paymentId, String signature) async {
    try {
      await _loadToken();
      final response = await http.post(
        Uri.parse('$baseUrl/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Payment verification failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

// Screen to display subscription plans
class SubscriptionPlansScreen extends StatefulWidget {
  final String? returnRoute;
  
  const SubscriptionPlansScreen({this.returnRoute, Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  // Initialize Razorpay instance
  late Razorpay _razorpay;
  late RazorpayService _razorpayService;
  bool _isLoading = false;

  // List of available subscription plans
  final List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'basic',
      name: 'Basic Plan',
      price: 10000, // Price in paise (₹100)
      contacts: 3,
      features: [
        '3 Contact Views',
        '3 Months Validity',
        'Unlock Forever',
        'Basic Support'
      ],
    ),
    SubscriptionPlan(
      id: 'standard',
      name: 'Standard Plan',
      price: 20000, // Price in paise (₹200)
      contacts: 6,
      features: [
        '6 Contact Views',
        '3 Months Validity',
        'Unlock Forever',
        'Priority Support',
        'Advanced Search'
      ],
    ),
    SubscriptionPlan(
      id: 'premium',
      name: 'Premium Plan',
      price: 50000, // Price in paise (₹500)
      contacts: -1,
      features: [
        'Unlimited Contact Views',
        '3 Months Validity',
        'Unlock Forever',
        'Premium Support',
        'Advanced Search',
        'Export Features'
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  // Initialize Razorpay instance and set up event handlers
  void _initializePayment() {
    _razorpay = Razorpay();
    _razorpayService = RazorpayService();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      setState(() => _isLoading = true);

      // Verify payment with backend
      await _razorpayService.verifyPayment(
        response.orderId!,
        response.paymentId!,
        response.signature!,
      );

      // Store subscription status locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasActiveSubscription', true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Your subscription is now active.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back or to specified route
        if (widget.returnRoute != null) {
          context.go(widget.returnRoute!);
        } else {
          context.pop();
        }
      }
    } catch (e) {
      _showError('Payment verification failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Handle payment failure
  void _handlePaymentError(PaymentFailureResponse response) {
    _showError('Payment failed: ${response.message ?? "Unknown error"}');
  }

  // Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
      ),
    );
  }

  // Show error message to user
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle subscription purchase
  Future<void> _handleSubscription(SubscriptionPlan plan) async {
    try {
      setState(() => _isLoading = true);

      // Create order on backend
      final orderData = await _razorpayService.createOrder(
        plan.id,
        plan.price.toInt(),
      );

      // Configure payment options
      var options = {
        'key': _razorpayService.apiKey,
        'amount': plan.price.toInt(),
        'name': 'Donor Connect',
        'order_id': orderData['orderId'],
        'description': '${plan.name} Subscription',
        'timeout': 300,
        'prefill': {
          // Add user details if available
          // 'contact': 'USER_PHONE',
          // 'email': 'USER_EMAIL',
        },
        'theme': {
          'color': '#2196F3',
        }
      };

      _razorpay.open(options);
    } catch (e) {
      _showError('Failed to initiate payment: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Choose a Plan'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select Your Subscription Plan',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a plan that best suits your needs',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ...plans.map((plan) => _buildPlanCard(plan)).toList(),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  // Build subscription plan card
  Widget _buildPlanCard(SubscriptionPlan plan) {
    final bool isPremium = plan.id == 'premium';
    
    return material.Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: isPremium ? 4 : 1,
      child: Container(
        decoration: isPremium ? BoxDecoration(
          border: Border.all(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isPremium) _buildPremiumBadge(),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                plan.formattedPrice,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                plan.contacts == -1
                    ? 'Unlimited Contacts'
                    : '${plan.contacts} Contacts',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...plan.features.map((feature) => _buildFeatureRow(feature)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _handleSubscription(plan),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: isPremium 
                      ? Theme.of(context).primaryColor 
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Subscribe Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build premium plan badge
  Widget _buildPremiumBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'MOST POPULAR',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Build feature row with checkmark
  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}