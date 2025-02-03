import 'package:flutter/material.dart';
import '../subscription_plans_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SubscriptionDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
     final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(localizations.subscribeTitle),
      content: Text(localizations.subscribeContent),
      actions: [
        TextButton(
          child: Text(localizations.cancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text(localizations.viewsplans),
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