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

import 'razorpay_web.dart' if (dart.library.io) 'razorpay_mobile.dart';

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

  String get formattedPrice => '₹${(price / 100).toStringAsFixed(2)}';
}

// Service class to handle all Razorpay-related operations
class RazorpayService {
  final String apiKey = 'rzp_test_TzdLYDjiaegAyF';
  final String baseUrl = ServerConfig.baseUrl;
  final _storage = FlutterSecureStorage();
  String? _token;

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }

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

  Future<void> initializePayment({
    required String orderId,
    required int amount,
    required String name,
    required Function(String paymentId, String orderId, String signature) onSuccess,
    required Function(String error) onError,
  }) async {
    final razorpayHandler = getRazorpayHandler();
    await razorpayHandler.initializePayment(
      apiKey: apiKey,
      orderId: orderId,
      amount: amount,
      name: name,
      onSuccess: onSuccess,
      onError: onError,
    );
  }
}

class SubscriptionPlansScreen extends StatefulWidget {
  final String? returnRoute;
  
  const SubscriptionPlansScreen({this.returnRoute, Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  late RazorpayService _razorpayService;
  bool _isLoading = false;

  final List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'basic',
      name: 'Basic Plan',
      price: 10000,
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
      price: 20000,
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
      price: 50000,
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
    _razorpayService = RazorpayService();
  }

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

  Future<void> _handleSubscription(SubscriptionPlan plan) async {
    try {
      setState(() => _isLoading = true);
      final orderData = await _razorpayService.createOrder(plan.id, plan.price.toInt());

      await _razorpayService.initializePayment(
        orderId: orderData['orderId'],
        amount: orderData['amount'],
        name: 'Donor Connect',
        onSuccess: (paymentId, orderId, signature) async {
          await _verifyAndCompletePayment(paymentId, orderId, signature);
        },
        onError: _showError,
      );
    } catch (e) {
      _showError('Failed to initialize payment: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndCompletePayment(String paymentId, String orderId, String signature) async {
    try {
      setState(() => _isLoading = true);
      await _razorpayService.verifyPayment(orderId, paymentId, signature);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasActiveSubscription', true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Your subscription is now active.'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.returnRoute != null) {
          context.go(widget.returnRoute!);
        } else {
          context.pop();
        }
      }
    } catch (e) {
      _showError('Payment verification failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  void dispose() {
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose a plan that best suits your needs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
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

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final bool isPremium = plan.id == 'premium';
    final theme = Theme.of(context);
    
    return material.Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      elevation: isPremium ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPremium 
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: isPremium ? BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.05),
              Colors.white,
              theme.primaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ) : null,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isPremium) _buildPremiumBadge(),
              Text(
                plan.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPremium ? theme.primaryColor : null,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    plan.price.toStringAsFixed(0),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'per quarter',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  plan.contacts == -1
                      ? 'Unlimited Contacts'
                      : '${plan.contacts} Contacts',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ...plan.features.map((feature) => _buildFeatureRow(feature, isPremium)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _handleSubscription(plan),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: isPremium ? theme.primaryColor : null,
                  foregroundColor: isPremium ? Colors.white : null,
                  elevation: isPremium ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Subscribe Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isPremium) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.star, size: 20),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.star, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            'MOST POPULAR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature, bool isPremium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: isPremium ? Theme.of(context).primaryColor : Colors.green,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isPremium ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}