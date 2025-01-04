import 'package:flutter/material.dart';
import '../services/admin_services.dart';
import '../models/adminmodel.dart';
import '../models/Documentmodel.dart';
import '../services/getAlluser_services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final AdminService _adminService = AdminService();
  List<VerificationRequest> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<List<Document>> fetchDonorDocuments(String donorId, String country) async {
    final documentService = AlluserData();
    return await documentService.getUserDocuments(donorId, country);
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetching data from API
      _users = await _adminService.requestVerification();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleApprove(String userId) async {
    try {
      final response = await _adminService.approveOrRejectVerification(userId, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      _fetchUsers(); // Refresh the list after action
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving user: $e')),
      );
    }
  }

  Future<void> _handleReject(String userId) async {
    try {
      final response = await _adminService.approveOrRejectVerification(userId, false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      _fetchUsers(); // Refresh the list after action
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting user: $e')),
      );
    }
  }

  void _showUserDetails(VerificationRequest user) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'User Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('Name: ${user.userId?.firstName} ${user.userId?.lastName}'),
                Text('Email: ${user.userId?.email}'),
                Text('Phone Number: ${user.userId?.phoneNumber}'),
                Text('Blood Group: ${user.userId?.bloodGroup}'),
                Text('City: ${user.userId?.city}'),
                Text('State: ${user.userId?.state}'),
                Text('Country: ${user.userId?.country}'),
                Text('Organ Donations: ${user.userId?.organDonations.join(', ')}'),
                SizedBox(height: 16),
                Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Center(
                    child: FutureBuilder<List<Document>>(
                      future: fetchDonorDocuments(user.userId?.id ?? '', user.userId?.country ?? ''),
                      builder: (context, docSnapshot) {
                        if (docSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (docSnapshot.hasError) {
                          return Center(child: Text('Error: ${docSnapshot.error}'));
                        } else if (!docSnapshot.hasData || docSnapshot.data!.isEmpty) {
                          return Center(child: Text('No documents found.'));
                        } else {
                          final documents = docSnapshot.data!;
                          return ListView.builder(
                            itemCount: documents.length,
                            itemBuilder: (context, index) {
                              final document = documents[index];
                              final documentFiles = document.files?.entries
                                      .where((entry) => entry.value.isNotEmpty)
                                      .toList() ?? [];

                              return documentFiles.isNotEmpty
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Document ${index + 1}',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 10),
                                        Card(
                                          elevation: 5,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                ...documentFiles.map((fileEntry) {
                                                  final fileName = fileEntry.key.split('/').last;
                                                  final fileValue = fileEntry.value.split('/').last;
                                                  return GestureDetector(
                                                    onTap: () {
                                                      _openDocument(context, fileEntry.value);
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: RichText(
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text: '$fileName: ',
                                                                  style: const TextStyle(
                                                                    fontSize: 18, // Increased size
                                                                    fontWeight: FontWeight.bold, // Bold font
                                                                    color: Colors.black,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text: fileValue,
                                                                  style: const TextStyle(
                                                                    fontSize: 16,
                                                                    color: Colors.lightBlue, // Light blue color
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        const Icon(Icons.image, color: Colors.blue),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                    )
                                  : const SizedBox.shrink();
                            },
                          );
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Request'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                if (user.userId?.country == null || user.userId?.email == null) {
                       return SizedBox.shrink(); 
                          }
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Name: ${user.userId?.firstName} ${user.userId?.lastName}'),
                    subtitle: Text('Country: ${user.userId?.country} | Phone Number: ${user.userId?.phoneNumber}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () => _handleApprove(user.userId?.id ?? ''),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () => _handleReject(user.userId?.id ?? ''),
                        ),
                      ],
                    ),
                    onTap: () => _showUserDetails(user),
                  ),
                );
              },
            ),
    );
  }
  void _openDocument(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'Could not open the document';
  }
}
}


