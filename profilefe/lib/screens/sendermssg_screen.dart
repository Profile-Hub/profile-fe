import 'package:flutter/material.dart';
import '../services/chat_services.dart';
import '../routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../theme.dart';

class SenderScreen extends StatefulWidget {
  @override
  _SenderScreenState createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  final ChatServices  _chatservice=ChatServices();
  bool _isLoading = true;
  String? _error;
 String conversationSid = '';
  @override
  void initState() {
    super.initState();
    _fetchUserdetails();
  }
  Future<void> _fetchUserdetails() async {
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
                      .contains(query.toLowerCase()))
              .toList();
    });
  }

  void _navigateToChat(Map<String, dynamic> conversation) async {
    final  userId = conversation['id'] ;
    final String userName = '${conversation['firstname']} ${conversation['lastname']}';
    final String profileImage = conversation['avatar']?['url'] ??
        'https://via.placeholder.com/150';
    final sid = await _chatservice.getOrCreateConversation(userId);
    setState(() {
      conversationSid = sid; 
    });

    GoRouter.of(context).go('${Routes.donnerchat}/$conversationSid',
    extra: {
        'conversationSid': conversationSid,
        'userName': userName,
        'profileImage': profileImage,
      },);
  }

  Widget _buildErrorWidget() {
     final localization = AppLocalizations.of(context)!;
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
            child: Text(localization.retry),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
     final localization = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      GoRouter.of(context).go(Routes.home);
    },
  ),
        title: Text(localization.allRecipients),
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
                hintText: localization.searchRecipitent,
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
                                  ? localization.noRecipientFound
                                  : localization.noMatchingRecipient,
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
              onTap: () => _navigateToChat(sender),
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
