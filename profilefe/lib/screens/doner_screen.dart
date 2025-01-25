import 'package:flutter/material.dart';
import '../models/allDoner.dart';
import '../services/getdoner_service.dart';
import '../services/subscription_service.dart';
import './widgets/donor_card.dart';
import '../routes.dart';
import 'package:go_router/go_router.dart';
import '../models/doner_filter_model.dart';
import './widgets/dono_filter_widjet.dart';

class DonorListPage extends StatefulWidget {
  @override
  _DonorListPageState createState() => _DonorListPageState();
}

class _DonorListPageState extends State<DonorListPage> {
  late Future<List<Doner>> _donors;
  final SubscriptionService _subscriptionService = SubscriptionService();
  DonorFilter? _currentFilter;
  List<Doner> _allDonors = [];
  List<Doner> _filteredDonors = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _donors = fetchDonors();
  }

  Future<List<Doner>> fetchDonors() async {
    final donorService = DonnerService();
    final donors = await donorService.getAllDoner(filter: _currentFilter);
    setState(() {
      _allDonors = donors;
      _filteredDonors = donors;
    });
    return donors;
  }

  void _handleFilterChange(DonorFilter filter) {
    setState(() {
      _currentFilter = filter;
      _donors = fetchDonors();
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredDonors = _allDonors;
      } else {
        _filteredDonors = _allDonors
    .where((donor) {
      final searchParts = query.toLowerCase().split(' '); 
      return searchParts.every((part) =>
          donor.firstname.toLowerCase().contains(part) || 
          donor.lastname.toLowerCase().contains(part));
    })
    .toList();
      }
    });
  }

  Future<void> _handleDonorTap(BuildContext context, Doner donor) async {
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

    if (confirm != true) return;

    try {
      final status = await _subscriptionService.checkSubscriptionStatus();
      if (status.subscription?.credit == null ||
          status.subscription!.credit == 0 ||
          status.subscription!.status == "expired" ||
          status.subscription!.status == "canceled" ||
          status.message == "No subscription found for the user") {
        GoRouter.of(context).push(Routes.subscriptionPlans);
        return;
      }

      final success = await _subscriptionService.deductCredit(donor.id);
      if (!success) {
        GoRouter.of(context).push(Routes.subscriptionPlans);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have successfully unlocked this donor.')),
      );

      GoRouter.of(context).go('${Routes.donorDetails}/${donor.id}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            child: TextField(
              onChanged: _handleSearch,
                decoration: InputDecoration(
  hintText: 'Search Donor...',
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12), 
    borderSide: BorderSide(
      color: Colors.grey, 
      width: 0.8,         
    ),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: Colors.grey, 
      width: 0.8,
    ),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: Colors.black, 
      width: 1.5,
    ),
  ),
  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextButton.icon(
              icon: const Icon(Icons.tune, size: 20),
              label: const Text('Filter'),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 0.9,
                    builder: (_, controller) => SingleChildScrollView(
                      controller: controller,
                      child: DonorFilterWidget(
                        onFilterChanged: _handleFilterChange,
                        onClose: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredDonors.length,
              itemBuilder: (context, index) {
                final donor = _filteredDonors[index];
                return GestureDetector(
                  onTap: () => _handleDonorTap(context, donor),
                  child: DonorCard(donor: donor),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}