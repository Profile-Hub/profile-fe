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
    try {
      // Check subscription status
      final status = await _subscriptionService.checkSubscriptionStatus();
        if ((status.subscription?.credit == null || 
        (status.subscription?.credit == 0))) {
      // No active subscription, no credits, or null credits; show subscription plans
      GoRouter.of(context).push(Routes.subscriptionPlans);
      return;
    }
      // Attempt to deduct credit
      final success = await _subscriptionService.deductCredit();
      if (!success) {
        // Failed to deduct credit, show subscription plans
        GoRouter.of(context).push(Routes.subscriptionPlans);
        return;
      }

      // Navigate to donor details
      // GoRouter.of(context).go('${Routes.donorDetails}/${donor.id}');
    } catch (e) {
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