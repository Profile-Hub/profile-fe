import 'package:flutter/material.dart';
import '../services/chat_services.dart';
import '../models/user.dart';
import '../services/getdoner_service.dart';
import '../services/subscription_service.dart';
import '../routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../theme.dart';

class RecipientScreen extends StatefulWidget {
    final User user;
    RecipientScreen({Key? key, required this.user}) : super(key: key);
  @override
  _RecipientScreenState createState() => _RecipientScreenState();
}

class _RecipientScreenState extends State<RecipientScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  final ChatServices _chatservice = ChatServices();
  bool _isLoading = true;
  late User userId;
  String? _error;
  String conversationSid = '';
  final SubscriptionService _subscriptionService = SubscriptionService(); // Assuming you have a subscription service

  @override
  void initState() {
    super.initState();
    userId = widget.user;
    
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchUserdetails();
  }

  Future<void> _fetchUserdetails() async {
     final localizations = AppLocalizations.of(context)!;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final conversations = await _chatservice.getSenderDetails();
      setState(() {
        _conversations = conversations ?? [];
        _filteredConversations = _conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load sender details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

 void _filterConversations(String query) {
  setState(() {
    _filteredConversations = query.isEmpty
        ? _conversations
        : _conversations
            .where((conversation) =>
                (conversation['firstname']?.toString().toLowerCase() ?? '')
                    .contains(query.toLowerCase()) ||
                (conversation['lastname']?.toString().toLowerCase() ?? '')
                    .contains(query.toLowerCase()))  // Ensuring we are comparing to a boolean value.
            .toList();
  });
}

 Future<void> _handleDonorTap(BuildContext context, Map<String, dynamic> donor) async {
  final localizations = AppLocalizations.of(context)!;
  try {
    final status = await _subscriptionService.checkSubscriptionStatus();
    final donorId = donor['id'] ?? '';
    
    if (donorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.missingDonorId)),
      );
      return;
    }

    bool isDonorSelected = false;
    try {
      final selectedDonors = await DonnerService().getAllSelectedDoner();
      isDonorSelected = selectedDonors.map((donor) => donor.id).contains(donorId);
    } catch (e) {
      debugPrint('Error fetching selected donors: $e');
      // Continue with isDonorSelected as false
    }

    if ((status.subscription?.credit == null ||
        status.subscription!.credit == 0 ||
        status.subscription!.status == "expired" ||
        status.subscription!.status == "canceled" ||
        status.message == "No subscription found for the user") &&
        !isDonorSelected) {
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(localizations.confirmUnlock),
            content: Text(localizations.needActiveSubcribe),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(localizations.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(localizations.viewsplans),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        GoRouter.of(context).push(Routes.subscriptionPlans);
      }
      return;
    }

    if (isDonorSelected) {
      openChat(context, donor);
      return;
    }

    await _subscriptionService.deductCredit(donorId);

    final String userName = '${donor['firstname']} ${donor['lastname']}';
    final String profileImage = donor['avatar']?['url'] ?? 'https://via.placeholder.com/150';

    final sid = await _chatservice.getOrCreateConversation(donorId);
    setState(() {
      conversationSid = sid;
    });

    GoRouter.of(context).go(
      '${Routes.donnerchat}/$conversationSid',
      extra: {
        'conversationSid': conversationSid,
        'userName': userName,
        'profileImage': profileImage,
      },
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${localizations.error}: ${e.toString()}")),
    );
  }
}


void openChat(BuildContext context, Map<String, dynamic> donor) {
  final userId = donor['id'] ?? '';
  final String userName = '${donor['firstname']} ${donor['lastname']}';
  final String profileImage = donor['avatar']?['url'] ?? 'https://via.placeholder.com/150';

  GoRouter.of(context).go(
    '${Routes.donnerchat}/$userId',
    extra: {
      'userId': userId,
      'userName': userName,
      'profileImage': profileImage,
    },
  );
}


  Widget _buildErrorWidget() {
     final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchUserdetails,
            child: Text(localizations.retry),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
     final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            GoRouter.of(context).go(Routes.home);
          },
        ),
        title: Text(localizations.allDonors),
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterConversations,
              decoration: InputDecoration(
                hintText: localizations.searchDonor,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorWidget()
                    : _filteredConversations.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? localizations.noDonorsFound
                                  : localizations.noMatchingDonors,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredConversations.length,
                            itemBuilder: (context, index) {
                              final sender = _filteredConversations[index];
                              final userName = '${sender['firstname']} ${sender['lastname']}';
                              final profileImage = sender['avatar']?['url'] ??
                                  'https://via.placeholder.com/150';

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Card(
                                  elevation: 4, // Shadow effect
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12), // Padding inside the card
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage(profileImage),
                                      radius: 30, // Increased by 20% from the original 25
                                    ),
                                    title: Text(
                                      userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    onTap: () => _handleDonorTap(context, sender), // Use the updated method
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}