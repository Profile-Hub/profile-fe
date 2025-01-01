import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      appBar: AppBar(title: Text('Donor Details')),
      body: FutureBuilder<DonerDetails>(
        future: fetchDonorDetails(donorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No donor found.'));
          } else {
            final donor = snapshot.data!;
            return Padding(
              padding: EdgeInsets.all(16),
              child: ListView(
                children: [
                  if (donor.avatar != null)
                    CircleAvatar(
                      backgroundImage: NetworkImage(donor.avatar!.url),
                      radius: 50,
                    ),
                  SizedBox(height: 20),
                  Text('Name: ${donor.firstname} ${donor.lastname}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
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
                  
                  // Add a section to fetch and display documents
                  SizedBox(height: 20),
                  FutureBuilder<List<Document>>(
  future: fetchDonorDocuments(donorId, donor.country ?? ''),
  builder: (context, docSnapshot) {
    if (docSnapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    } else if (docSnapshot.hasError) {
      return Center(child: Text('Error: ${docSnapshot.error}'));
    } else if (!docSnapshot.hasData || docSnapshot.data!.isEmpty) {
      return Center(child: Text('No documents found.'));
    } else {
      final documents = docSnapshot.data!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Donor Documents',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              // List to store document names and their file URLs from the 'files' map
              final documentFiles = document.files?.entries.toList() ?? [];
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document ${index + 1}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  // Display all files in the 'files' map of each document
                  ...documentFiles.map((fileEntry) {
                    return ListTile(
                      title: Text(fileEntry.key), // Document name (key)
                      subtitle: Text(fileEntry.value), // Document URL (value)
                      trailing: IconButton(
                        icon: Icon(Icons.open_in_new),
                        onPressed: () {
                          // Open the document URL (you can modify this based on your requirement)
                          _openDocument(fileEntry.value);
                        },
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 20), // Space between document entries
                ],
              );
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

  void _openDocument(String url) {
    // Implement logic to open the document URL (e.g., using a web view or browser)
  }
}
