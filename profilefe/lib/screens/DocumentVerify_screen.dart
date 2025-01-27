import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/donerDetails.dart';
import '../models/Documentmodel.dart';
import '../services/getdoner_service.dart';
import '../services/admin_services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../routes.dart';

class DocumentverifyPage extends StatelessWidget {
  final String donorId;
  final AdminService _adminService = AdminService();
  
  DocumentverifyPage({required this.donorId});

  Future<DonerDetails> fetchDonorDetails(String id) async {
    final donorService = DonnerService();
    return await donorService.getDonorById(id);
  }

  Future<List<Document>> fetchDonorDocuments(String donorId, String country) async {
    final documentService = DonnerService();
    return await documentService.getDonorDocuments(donorId, country);
  }

  Future<void> handleApproveReject(String documentId, bool approve, BuildContext context) async {
    try {
      final response = await _adminService.approveOrRejectVerification(documentId, approve);
      print(response);
      if (response == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'Document Approved' : 'Document Rejected')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process the document')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            GoRouter.of(context).go(Routes.adminVerify);
          },
        ),
        title: const Text('All Details'),
      ),
      body: FutureBuilder<DonerDetails>(
        future: fetchDonorDetails(donorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No donor found.'));
          } else {
            final donor = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          backgroundImage: NetworkImage("${donor.avatar!.url}"),
                          radius: 50,
                        ),
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
                      FutureBuilder<List<Document>>(
                        future: fetchDonorDocuments(donorId, donor.country ?? ''),
                        builder: (context, docSnapshot) {
                          if (docSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (docSnapshot.hasError) {
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
                                        Icons.insert_drive_file,
                                        size: 48,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No documents available.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.blue, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else if (!docSnapshot.hasData || docSnapshot.data!.isEmpty) {
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
                                        Icons.insert_drive_file,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No documents available.',
                                        style: TextStyle(fontSize: 16, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else {
                            final documents = docSnapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Donor Documents',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
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
                                              const SizedBox(height: 10),
                                              ...documentFiles.map((fileEntry) {
                                                final fileName = fileEntry.key.split('/').last;
                                                final fileValue = fileEntry.value.split('/').last;
                                                return GestureDetector(
                                                  onTap: () {
                                                    _openDocument(fileEntry.value);
                                                  },
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    children: [
                                                      Expanded(
                                                        child: RichText(
                                                          text: TextSpan(
                                                            children: [
                                                              TextSpan(
                                                                text: '$fileName: ',
                                                                style: const TextStyle(fontSize: 16, color: Colors.black),
                                                              ),
                                                              TextSpan(
                                                                text: fileValue,
                                                                style: const TextStyle(fontSize: 16, color: Colors.black),
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
                                const SizedBox(height: 20),
                                Center(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(vertical: 15),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final documentId = documents[0].id; 
                                            await handleApproveReject(documentId, true, context);
                                          },
                                          child: const Text(
                                            'Approve',
                                            style: TextStyle(color: Colors.white, fontSize: 16),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(vertical: 15),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final documentId = documents[0].id; 
                                            await handleApproveReject(documentId, false, context);
                                          },
                                          child: const Text(
                                            'Reject',
                                            style: TextStyle(color: Colors.white, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _openDocument(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not open document';
    }
  }
}
