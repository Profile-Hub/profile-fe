import 'package:flutter/material.dart';
import '../subscription_plans_screen.dart';

class SubscriptionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Subscribe to View Details'),
      content: Text('You need to subscribe to view donor details.'),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text('View Plans'),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SubscriptionPlansScreen()),
            );
          },
        ),
      ],
    );
  }
}