import 'package:flutter/material.dart';
import '../models/allUserAdmin.dart';
import '../models/Documentmodel.dart';
import '../services/getAlluser_services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../routes.dart'; 

class AllDonorPage extends StatefulWidget {
  @override
  _AllDonorPageState createState() => _AllDonorPageState();
}

class _AllDonorPageState extends State<AllDonorPage> {
  late Future<List<Alluser>> _donorsFuture;
  String searchQuery = '';
  @override
  void initState() {
    super.initState();
    _donorsFuture = AlluserData().getAllUser(); // Fetch the list of users
  }

  Future<List<Document>> donorDocuments(String donorId, String country) async {
    final documentService = AlluserData();
    return await documentService.getUserDocuments(donorId, country);
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
        title: TextField(
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

          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
        ),
      ),
      body: FutureBuilder<List<Alluser>>(
        future: _donorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No donors found.'));
          } else {
            final donors = snapshot.data!;
            final filteredDonors = donors.where((donor) {
  final searchTerms = searchQuery.split(' ');
  return donor.usertype == 'donor' &&
      searchTerms.every((term) =>
          donor.firstname.toLowerCase().contains(term) ||
          donor.lastname.toLowerCase().contains(term));
}).toList();

            return ListView.builder(
              itemCount: filteredDonors.length,
              itemBuilder: (context, index) {
                final donor = filteredDonors[index];
                return ListTile(
                  leading: donor.avatar != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(donor.avatar!.url),
                        )
                      : CircleAvatar(child: Icon(Icons.person)),
                  title: Text('${donor.firstname} ${donor.lastname}'),
                  subtitle:
                      Text('${donor.country ?? 'Unknown'} | ${donor.phoneNumber ?? 'N/A'}'),
                  onTap: () {
                    _navigateToDonorDetails(context, donor);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
  void _navigateToDonorDetails(BuildContext context, Alluser donor) async {
    try {
      Alluser donorDetails = await AlluserData().getUserById(donor.id);
      // Use GoRouter for navigation instead of Navigator.push
      GoRouter.of(context).go('/donorDetails/${donor.id}');
    } catch (e) {
      _showErrorDialog(context, 'Failed to load donor details: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                GoRouter.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class DonorDetailsPage extends StatelessWidget {
  final Alluser donor;
  final Alluser donorDetails;

  // Remove the 'const' keyword here
  DonorDetailsPage({required this.donor, required this.donorDetails});

  Future<List<Document>> fetchdonorDocuments(String donorId, String country) async {
    final documentService = AlluserData();
    return await documentService.getUserDocuments(donorId, country);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${donor.firstname} ${donor.lastname}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${donor.firstname} ${donor.lastname}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Phone: ${donor.phoneNumber ?? "N/A"}'),
            Text('Country: ${donor.country ?? "N/A"}'),
            Text('Email: ${donor.email}'),
            Text('Date of Birth: ${donor.dateofbirth != null ? donor.dateofbirth!.toLocal().toString().split(' ')[0] : 'N/A'}'),
            Text('Blood Group: ${donor.bloodGroup ?? 'N/A'}'),
            Expanded(
              child: FutureBuilder<List<Document>>(
                future: fetchdonorDocuments(donor.id, donor.country ?? ''),
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
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 10),
                                  Card(
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
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
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.black,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                            text: fileValue,
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              color: Colors.lightBlue,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Icon(Icons.image, color: Colors.blue),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                ],
                              )
                            : SizedBox.shrink();
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
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
