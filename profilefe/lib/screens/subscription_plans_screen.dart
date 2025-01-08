import 'package:flutter/material.dart' hide Card;
import 'package:flutter/material.dart' as material show Card;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../services/stripe_service.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';


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
}

class SubscriptionPlansScreen extends StatelessWidget {
  final String? returnRoute;
  
  SubscriptionPlansScreen({this.returnRoute});

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

Future<void> _handleSubscription(BuildContext context, SubscriptionPlan plan) async {
  final stripeService = StripeService();

  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    if (kIsWeb) {
      final response = await stripeService.createCheckoutSession(plan.id);
      final checkoutUrl = response['checkoutUrl'];
      Navigator.pop(context);

      if (checkoutUrl != null) {
        await launchUrl(Uri.parse(checkoutUrl));
      } else {
        throw Exception('Failed to retrieve checkout URL');
      }
    } else {
      // Mobile-specific flow: Use PaymentSheet
      final paymentIntentData = await stripeService.createPaymentIntent(
        plan.id,
        plan.price.toInt(),
      );

      Navigator.pop(context);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Donor Connect',
          paymentIntentClientSecret: paymentIntentData['clientSecret'],
          style: ThemeMode.system,
          applePay: PaymentSheetApplePay(
            merchantCountryCode: 'IN',
          ),
          googlePay: PaymentSheetGooglePay(
            merchantCountryCode: 'IN',
            testEnv: true,
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Handle successful payment
      await stripeService.handlePaymentSuccess(
        paymentIntentData['paymentIntent'],
        plan.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Your subscription is now active.'),
            backgroundColor: Colors.green,
          ),
        );

        if (returnRoute != null) {
          context.go(returnRoute!);
        } else {
          context.pop();
        }
      }
    }
  } catch (e) {
    Navigator.maybeOf(context)?.pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose a Plan'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Your Subscription Plan',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Choose a plan that best suits your needs',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ...plans.map((plan) => _buildPlanCard(context, plan)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan) {
    final bool isPremium = plan.id == 'premium';
    
    return material.Card(
      margin: EdgeInsets.symmetric(vertical: 8),
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
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isPremium) _buildPremiumBadge(context),
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
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
              SizedBox(height: 16),
              Text(
                '₹${plan.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                plan.contacts == -1
                    ? 'Unlimited Contacts'
                    : '${plan.contacts} Contacts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ...plan.features.map((feature) => _buildFeatureRow(feature)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _handleSubscription(context, plan),
                child: Text('Subscribe Now'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: isPremium 
                      ? Theme.of(context).primaryColor 
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBadge(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
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

  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              color: Colors.green, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}