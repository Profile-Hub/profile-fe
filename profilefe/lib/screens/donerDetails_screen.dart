import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/donerDetails.dart';
import '../models/Documentmodel.dart';
import '../services/getdoner_service.dart';

class DonorDetailPage extends StatelessWidget {
  final String donorId;

  DonorDetailPage({required this.donorId});

  Future<DonerDetails> fetchDonorDetails(String id) async {
    final donorService = DonnerService();
    return await donorService.getDonorById(id);
  }

  Future<List<Document>> fetchDonorDocuments(String donorId, String country) async {
    final documentService = DonnerService();
    return await documentService.getDonorDocuments(donorId, country);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donor Details')),
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
                  FutureBuilder<List<Document>>(
                    future: fetchDonorDocuments(donorId, donor.country ?? ''),
                    builder: (context, docSnapshot) {
                      if (docSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (docSnapshot.hasError) {
                        return Center(child: Text('Error: ${docSnapshot.error}'));
                      } else if (!docSnapshot.hasData || docSnapshot.data!.isEmpty) {
                        return const Center(child: Text('No documents found.'));
                      } else {
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
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
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
                          ],
                        );
                      }
                    },
                  )
                ],
              ),
            );
          }
        },
      ),
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
}
