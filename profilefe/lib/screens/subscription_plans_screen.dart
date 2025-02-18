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
import '../routes.dart';
import 'razorpay_web.dart' if (dart.library.io) 'razorpay_mobile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  final String apiKey = 'rzp_live_XPOlaMoyZPAdMm';
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

  List<SubscriptionPlan> getPlans(AppLocalizations localizations) => [
    SubscriptionPlan(
      id: 'basic',
      name: localizations.basicPlan,
      price: 10000,
      contacts: 3,
      features: [
        '3 ${localizations.contacts}',
        '3 ${localizations.monthsValidity}',
        localizations.unlockForever,
        localizations.basicSupport
      ],
    ),
    SubscriptionPlan(
      id: 'standard',
      name: localizations.standardPlan,
      price: 20000,
      contacts: 6,
      features: [
        '6 ${localizations.contacts}',
        '3 ${localizations.monthsValidity}',
        localizations.unlockForever,
        localizations.prioritySupport,
        localizations.advancedSearch
      ],
    ),
    SubscriptionPlan(
      id: 'premium',
      name: localizations.premiumPlan,
      price: 50000,
      contacts: -1,
      features: [
        localizations.unlimited + ' ' + localizations.contacts,
        '3 ${localizations.monthsValidity}',
        localizations.unlockForever,
        localizations.premiumSupport,
        localizations.advancedSearch,
        localizations.exportFeatures
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
     final localizations = AppLocalizations.of(context)!;
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
      _showError('${localizations.paymentFailed}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndCompletePayment(String paymentId, String orderId, String signature) async {
     final localizations = AppLocalizations.of(context)!;
    try {
      setState(() => _isLoading = true);
      await _razorpayService.verifyPayment(orderId, paymentId, signature);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasActiveSubscription', true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(localizations.paymentSuccess),
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
      _showError('${localizations.paymentVerificationFailed}: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  void _handleBack(BuildContext context) {
    // Navigate to home or another specific route
    context.go(Routes.home); 
  }


  @override
  void dispose() {
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final plans = getPlans(localizations);
    
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(localizations.choosePlan),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _handleBack(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  localizations.selectSubscriptionPlan,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  localizations.chooseBestPlan,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ...plans.map((plan) => _buildPlanCard(plan, localizations)).toList(),
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
   Widget _buildPlanCard(SubscriptionPlan plan, AppLocalizations localizations) {
    final bool isPremium = plan.id == 'premium';
    final theme = Theme.of(context);
    
    return material.Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.primaryColor, 
          width: 2
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
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
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isPremium) _buildPremiumBadge(localizations),
              Text(
                plan.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
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
                localizations.perQuarter,
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
                      ? '${localizations.unlimited} ${localizations.contacts}'
                      : '${plan.contacts} ${localizations.contacts}',
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
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      localizations.subscribeNow,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isPremium) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 20),
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



  Widget _buildPremiumBadge(AppLocalizations localizations) {
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
        children: [
          const Icon(Icons.star, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            localizations.mostPopular,
            style: const TextStyle(
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
            color: Theme.of(context).primaryColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}