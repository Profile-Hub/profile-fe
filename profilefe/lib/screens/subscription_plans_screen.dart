import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../services/stripe_service.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/material.dart' as material show Card;
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
Future<void> _handleSubscription(
      BuildContext context, SubscriptionPlan plan) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Create payment intent
      final paymentIntentData = await StripeService.createPaymentIntent(
        plan.id,
        plan.price.toInt(),
      );

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Your App Name',
          paymentIntentClientSecret: paymentIntentData['clientSecret'],
          style: ThemeMode.system,
        ),
      );

      // Show payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Close loading indicator
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful!')),
      );

      // Handle post-payment logic (e.g., update user's subscription status)
      Navigator.pop(context);
    } catch (e) {
      // Close loading indicator if it's showing
      Navigator.maybeOf(context)?.pop();

      // Show error message
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
            SizedBox(height: 20),
            ...plans.map((plan) => _buildPlanCard(context, plan)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan) {
    return material.Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            ...plan.features.map((feature) => Padding(
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
                )),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _handleSubscription(context, plan),
              child: Text('Subscribe Now'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 
}