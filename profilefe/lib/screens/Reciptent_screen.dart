import 'package:flutter/material.dart';
import '../models/AllReciptentmodel.dart';
import '../services/getReciptent_services.dart';
import '../services/subscription_service.dart';
import './widgets/recipient_card.dart';
import '../routes.dart';
import 'package:go_router/go_router.dart';
import '../models/Recipitent_filter_modal.dart';
import './widgets/Reciptetent_filter_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RecipientListPage extends StatefulWidget {
  @override
  _RecipientListPageState createState() => _RecipientListPageState();
}

class _RecipientListPageState extends State<RecipientListPage> {
  late Future<List<Recipient>> _recipients;
  final SubscriptionService _subscriptionService = SubscriptionService();
  RecipientFilter? _currentFilter;
  List<Recipient> _allRecipients = [];
  List<Recipient> _filteredRecipients = [];
  String _searchQuery = "";
  bool _isLoading = true;

 @override
  void initState() {
    super.initState();
    _fetchRecipients();
  }

  Future<void> _fetchRecipients() async {
    setState(() {
      _isLoading = true;
    });

    final recipientService = RecipitentService();
    final recipients = await recipientService.getAllReciptent(filter: _currentFilter);
    setState(() {
      _allRecipients = recipients;
      _filteredRecipients = recipients;
      _isLoading = false;
    });
  }

  void _handleFilterChange(RecipientFilter filter) {
    setState(() {
      _currentFilter = filter;
      _fetchRecipients();
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredRecipients = _allRecipients;
      } else {
        _filteredRecipients = _allRecipients
            .where((recipient) {
              final searchParts = query.toLowerCase().split(' ');
              return searchParts.every((part) =>
                  recipient.firstname.toLowerCase().contains(part) ||
                  recipient.lastname.toLowerCase().contains(part));
            })
            .toList();
      }
    });
  }

  Future<void> _handleRecipientTap(BuildContext context, Recipient recipient) async {
      GoRouter.of(context).go('${Routes.recipientDetails}/${recipient.id}');
  }
 bool _areFiltersApplied() {
  if (_currentFilter == null) return false;
  return _currentFilter!.city != null ||
      _currentFilter!.state != null ||
      _currentFilter!.radius != null ||
      _currentFilter!.gender != null 
    ;
}
void _resetFilters() {
      final localization = AppLocalizations.of(context)!;
  setState(() {
    _currentFilter = null;
     _fetchRecipients(); 
  });

  ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text(localization.filtersReset)),
  );
}
  @override
  Widget build(BuildContext context) {
      final localization = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: TextField(
                    onChanged: _handleSearch,
                    decoration: InputDecoration(
                      hintText: localization.searchHint,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 0.8,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 0.8,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                icon: Icon(
                  _areFiltersApplied() ? Icons.check_circle : Icons.tune,
                  color: _areFiltersApplied() ? Colors.green : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                label:  Text(localization.filter),
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
                        child: RecipientFilterWidget(
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
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              if (_areFiltersApplied())
                TextButton.icon(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.red,
                    size: 20,
                  ),
                  label:  Text(localization.resetFilters),
                  onPressed: () {
                    _resetFilters();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ), _isLoading
              ? Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              :Expanded(
            child: ListView.builder(
              itemCount: _filteredRecipients.length,
              itemBuilder: (context, index) {
                final recipient = _filteredRecipients[index];
                return GestureDetector(
                  onTap: () => _handleRecipientTap(context, recipient),
                  child: RecipientCard(recipient: recipient),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
