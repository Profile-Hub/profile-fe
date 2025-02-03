import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/getdoner_service.dart';
import '../models/selectedDonerModel.dart';
import '../routes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SelectedDonersScreen extends StatefulWidget {
  const SelectedDonersScreen({super.key});

  @override
  State<SelectedDonersScreen> createState() => _SelectedDonersScreenState();
}

class _SelectedDonersScreenState extends State<SelectedDonersScreen> {
  late Future<List<SelectedDoner>> _selectedDoners;

  @override
  void initState() {
    super.initState();
    _selectedDoners = DonnerService().getAllSelectedDoner();
  }

  void _handleBack(BuildContext context) {
    // Navigate to home or another specific route
    context.go(Routes.home); // Replace 'Routes.home' with your desired route
  }

 @override
Widget build(BuildContext context) {
     final localization = AppLocalizations.of(context)!;
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _handleBack(context),
      ),
      title:  Text(localization.donors),
      centerTitle: true,
    ),
    body: FutureBuilder<List<SelectedDoner>>(
      future: _selectedDoners,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
  // Redirect to the subscription page if an error occurs
  Future.microtask(() => context.go(Routes.subscriptionPlans));
  return const SizedBox(); // Return an empty widget while redirecting
}
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Redirect to the subscription page if no donors are found
          Future.microtask(() => context.go(Routes.subscriptionPlans));
          return const SizedBox(); // Return an empty widget while redirecting
        }

        final selectedDoners = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: selectedDoners.length,
          itemBuilder: (context, index) {
            final donor = selectedDoners[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: ListTile(
                leading: Hero(
                  tag: 'donor-avatar-${donor.id}',
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(donor.avatar.url),
                    onBackgroundImageError: (exception, stackTrace) {
                      debugPrint('Error loading avatar: $exception');
                    },
                  ),
                ),
                title: Text(
                  '${donor.firstname} ${donor.lastname}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onTap: () =>
                    context.go('${Routes.donorDetails}/${donor.id}'),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    ),
  );
}
}