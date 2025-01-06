import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/donerDetails.dart';
import '../models/Documentmodel.dart';
import '../services/getdoner_service.dart';
import '../services/credit_service.dart';
import 'subscription_plans_screen.dart';
class DonorDetailPage extends StatefulWidget {
  final String donorId;

  DonorDetailPage({required this.donorId});

  @override
  _DonorDetailPageState createState() => _DonorDetailPageState();
}

class _DonorDetailPageState extends State<DonorDetailPage> {
  late Future<bool> _creditCheckFuture;
  late Future<DonerDetails> _donorDetailsFuture;
  bool _hasCheckedCredits = false;

  @override
  void initState() {
    super.initState();
    _creditCheckFuture = CreditService().checkCredits();
    _donorDetailsFuture = DonnerService().getDonorById(widget.donorId);
  }

  Future<List<Document>> fetchDonorDocuments(String donorId, String country) async {
    final documentService = DonnerService();
    return await documentService.getDonorDocuments(donorId, country);
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Subscribe to View Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'You need a subscription to view donor details.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Choose a subscription plan to unlock this donor and more!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text('View Plans'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SubscriptionPlansScreen()),
              ).then((_) {
                // Refresh credit check when returning from subscription screen
                setState(() {
                  _creditCheckFuture = CreditService().checkCredits();
                  _hasCheckedCredits = false;
                });
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDonorDetails(DonerDetails donor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          if (donor.avatar != null)
            CircleAvatar(
              backgroundImage: NetworkImage(donor.avatar!.url),
              radius: 50,
            ),
          const SizedBox(height: 20),
          Text(
            'Name: ${donor.firstname} ${donor.lastname}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Date of Birth: ${donor.dateofbirth != null ? DateFormat.yMMMd().format(donor.dateofbirth!) : 'N/A'}',
          ),
          Text('Gender: ${donor.gender ?? 'N/A'}'),
          Text('Email: ${donor.email}'),
          Text(
            'Phone: ${donor.phoneCode != null && donor.phoneNumber != null ? '${donor.phoneCode} ${donor.phoneNumber}' : 'N/A'}',
          ),
          Text('City: ${donor.city ?? 'N/A'}'),
          Text('State: ${donor.state ?? 'N/A'}'),
          Text('Country: ${donor.country ?? 'N/A'}'),
          Text('Usertype: ${donor.usertype ?? 'N/A'}'),
          Text('Blood Group: ${donor.bloodGroup ?? 'N/A'}'),
          const SizedBox(height: 20),
          _buildDocumentsSection(donor),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(DonerDetails donor) {
    return FutureBuilder<List<Document>>(
      future: fetchDonorDocuments(widget.donorId, donor.country ?? ''),
      builder: (context, docSnapshot) {
        if (docSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (docSnapshot.hasError) {
          return Center(child: Text('Error: ${docSnapshot.error}'));
        } else if (!docSnapshot.hasData || docSnapshot.data!.isEmpty) {
          return const Center(child: Text('No documents found.'));
        }

        final documents = docSnapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Donor Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final document = documents[index];
                final documentFiles = document.files?.entries
                    .where((entry) => entry.value.isNotEmpty)
                    .toList() ??
                    [];

                return documentFiles.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Document ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...documentFiles.map((fileEntry) {
                            final fileName = fileEntry.key.split('/').last;
                            final fileValue = fileEntry.value.split('/').last;
                            return GestureDetector(
                              onTap: () => _openDocument(fileEntry.value),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '$fileName: ',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black
                                            ),
                                          ),
                                          TextSpan(
                                            text: fileValue,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black
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
                          const SizedBox(height: 20),
                        ],
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        );
      },
    );
  }

  void _openDocument(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not open the document';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donor Details')),
      body: FutureBuilder<bool>(
        future: _creditCheckFuture,
        builder: (context, creditSnapshot) {
          if (creditSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasCredits = creditSnapshot.data ?? false;
          
          if (!hasCredits && !_hasCheckedCredits) {
            _hasCheckedCredits = true;
            // Show subscription dialog after build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSubscriptionDialog();
            });
            return const Center(child: Text('Please subscribe to view details'));
          }

          return FutureBuilder<DonerDetails>(
            future: _donorDetailsFuture,
            builder: (context, donorSnapshot) {
              if (donorSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (donorSnapshot.hasError) {
                return Center(child: Text('Error: ${donorSnapshot.error}'));
              } else if (!donorSnapshot.hasData) {
                return const Center(child: Text('No donor found.'));
              }

              return _buildDonorDetails(donorSnapshot.data!);
            },
          );
        },
      ),
    );
  }
}