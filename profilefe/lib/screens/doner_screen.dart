import 'package:flutter/material.dart';
import '../models/allDoner.dart';
import '../services/getdoner_service.dart';
import '../services/subscription_service.dart';
import './widgets/donor_card.dart';
import '../routes.dart';
import 'package:go_router/go_router.dart';

class DonorListPage extends StatefulWidget {
  @override
  _DonorListPageState createState() => _DonorListPageState();
}

class _DonorListPageState extends State<DonorListPage> {
  late Future<List<Doner>> _donors;
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    _donors = fetchDonors();
  }

  Future<List<Doner>> fetchDonors() async {
    final donorService = DonnerService();
    return await donorService.getAllDoner();
  }

  Future<void> _handleDonorTap(BuildContext context, Doner donor) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Unlock'),
          content: Text('Are you sure you want to unlock this donor?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    // If user cancels, do nothing
    if (confirm != true) return;

    try {
      // Check subscription status
      final status = await _subscriptionService.checkSubscriptionStatus();
      if (status.subscription?.credit == null || 
    status.subscription!.credit == 0 || 
    status.subscription!.status == "expired" || 
    status.subscription!.status == "canceled") {
  GoRouter.of(context).push(Routes.subscriptionPlans);
  return;
}
      // Attempt to deduct credit
      final success = await _subscriptionService.deductCredit(donor.id);
      if (!success) {
        // Failed to deduct credit, show subscription plans
        GoRouter.of(context).push(Routes.subscriptionPlans);
        return;
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have successfully unlocked this donor.')),
      );

      // Navigate to donor details
      GoRouter.of(context).go('${Routes.donorDetails}/${donor.id}');
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Doner>>(
        future: _donors,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No donors found.'));
          }

          List<Doner> donors = snapshot.data!;
          return ListView.builder(
            itemCount: donors.length,
            itemBuilder: (context, index) {
              final donor = donors[index];
              return GestureDetector(
                onTap: () => _handleDonorTap(context, donor),
                child: DonorCard(donor: donor),
              );
            },
          );
        },
      ),
    );
  }
}
