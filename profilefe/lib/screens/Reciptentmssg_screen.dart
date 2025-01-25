import 'package:flutter/material.dart';
import '../services/chat_services.dart';
import '../services/getdoner_service.dart';
import '../routes.dart';
import 'package:go_router/go_router.dart';
import '../models/selectedDonerModel.dart';  // Import the model

class RecipientScreen extends StatefulWidget {
  @override
  _RecipientScreenState createState() => _RecipientScreenState();
}

class _RecipientScreenState extends State<RecipientScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SelectedDoner> _filteredDonors = [];  // Changed to List<SelectedDoner>
  List<SelectedDoner> _selectedDoners = [];  // Changed to List<SelectedDoner>
 
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDonorDetails();
  }

  Future<void> _fetchDonorDetails() async {
    try {
      _selectedDoners = await DonnerService().getAllSelectedDoner();
      setState(() {
        _filteredDonors = _selectedDoners;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _filterDonors(String query) {
    setState(() {
      _filteredDonors = query.isEmpty
          ? _selectedDoners
          : _selectedDoners
              .where((donor) =>
                  (donor.firstname?.toLowerCase() ?? '')
                      .contains(query.toLowerCase()) ||
                  (donor.lastname?.toLowerCase() ?? '')
                      .contains(query.toLowerCase()))
              .toList();
    });
  }

  void _navigateToChat(SelectedDoner donor) async {  // Changed to SelectedDoner
    final String donorId = donor.id ?? '';
    final String donorName = '${donor.firstname} ${donor.lastname}';
    final String profileImage = donor.avatar?.url ??
        'https://via.placeholder.com/150'; 
        final chatService = ChatServices(); 
        final conversationSid = await chatService.getOrCreateConversation(donorId);


    GoRouter.of(context).go('${Routes.chat}/$conversationSid', extra: {
      'conversationSid': conversationSid,
      'userName': donorName,
      'profileImage': profileImage,
    });
  }

 Widget _buildErrorWidget() {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          _error ?? 'No users exist at the moment.',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ],
    ),
  );
}

  Widget _buildNoDonorsWidget() {
    return Center(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_off,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No donors selected. Please select a donor.',
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            GoRouter.of(context).go(Routes.home);
          },
        ),
        title: Text("All Donors"),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterDonors,
              decoration: InputDecoration(
                hintText: "Search donors...",
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
                    ? _buildNoDonorsWidget()
                    : _filteredDonors.isEmpty
                        ? _buildErrorWidget()
                        : ListView.builder(
                            itemCount: _filteredDonors.length,
                            itemBuilder: (context, index) {
                              final donor = _filteredDonors[index];
                              final donorName =
                                  '${donor.firstname} ${donor.lastname}';
                              final profileImage = donor.avatar?.url ??
                                  'https://via.placeholder.com/150';

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.all(12),
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          profileImage),
                                      radius: 30,
                                    ),
                                    title: Text(
                                      donorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    onTap: () => _navigateToChat(donor),
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
