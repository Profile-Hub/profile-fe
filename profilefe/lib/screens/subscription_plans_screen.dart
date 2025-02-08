import 'package:flutter/material.dart' hide Card;
import 'package:flutter/material.dart' as material show Card;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../routes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'cashfree_web.dart' if (dart.library.io) 'cashfree_mobile.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import 'package:provider/provider.dart';


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

class PaymentService {
  final String appId;
  final String baseUrl;
  final String environment;
  final _storage = FlutterSecureStorage();
  String? _token;

  PaymentService({
    required this.appId,
    required this.baseUrl,
    this.environment = 'TEST',
  });

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
    if (_token == null) throw Exception('Authentication token not found');
  }

  Future<Map<String, dynamic>> createOrder(String planId, double amount) async {
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
        'currency': 'INR',
      }),
    );

    if (response.statusCode != 200) throw Exception('Failed to create order: ${response.body}');
    return jsonDecode(response.body);
  }

  Future<bool> verifyPayment(String orderId, String paymentId, String signature) async {
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

    if (response.statusCode != 200) throw Exception('Payment verification failed: ${response.body}');
    final responseData = jsonDecode(response.body);
    return responseData['verified'] == true;
  }

  Future<void> initializePayment({
    required BuildContext context,
    required String orderId,
    required double amount,
     required String sessionId,
    required User user,
    required Function(String paymentId, String orderId, String signature) onSuccess,
    required Function(String error) onError,
  }) async {
    try {

      final handler = CashfreeHandler();

      await handler.initializePayment(
        apiKey: appId,
         orderId: orderId,
        amount: (amount * 100).toInt(),
        name: "${user.firstname} ${user.lastname}",
         sessionId: sessionId,
        customerEmail: user.email,
        customerPhone: user.phoneNumber != null ? "+${user.phoneCode}${user.phoneNumber}" : "",
        onSuccess: onSuccess,
        onError: onError,
      );
    } catch (e) {
      onError('Payment initialization failed: $e');
    }
  }
}
class SubscriptionPlansScreen extends StatefulWidget {
  final String? returnRoute;
  
  const SubscriptionPlansScreen({this.returnRoute, Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _isLoading = false;
   late PaymentService _paymentService;
   User? _currentUser;


  List<SubscriptionPlan> getPlans(AppLocalizations localizations) => [
    SubscriptionPlan(
      id: 'basic',
      name: localizations.basicPlan,
      price: 1,
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
      price: 2,
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
      price: 5,
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
    _paymentService = PaymentService(
      appId: 'TEST10447003eedcf309ae89abd1615230074401',
      baseUrl: ServerConfig.baseUrl,
    );
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _currentUser = await userProvider.getCurrentUser();
    if (mounted) setState(() {});
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
      final orderData = await _paymentService.createOrder(plan.id, plan.price);
     

      await _paymentService.initializePayment(
        context: context,
        orderId: orderData['orderId'],
        sessionId: orderData['paymentSessionId'],
        amount: plan.price,
        user: _currentUser!,
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

  Future<void> _verifyAndCompletePayment(
    String paymentId,
    String orderId,
    String signature,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    
    try {
      setState(() => _isLoading = true);
      
      final isVerified = await _paymentService.verifyPayment(
        orderId,
        paymentId,
        signature,
      );
      
      if (isVerified) {
        final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasActiveSubscription', true);
      }
      else
      {
        throw Exception(localizations.paymentVerificationFailed);
      }

      

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
      _showError('${localizations.paymentVerificationFailed}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _handleBack(BuildContext context) {
    // Navigate to home or another specific route
    context.go(Routes.home); // Replace 'Routes.home' with your desired route
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