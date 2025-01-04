import 'package:flutter/material.dart';
import '../models/allUserAdmin.dart';
import '../models/donerDetails.dart';
import '../models/Documentmodel.dart';
import '../services/getAlluser_services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AllRecipientPage extends StatefulWidget {
  @override
  _AllRecipientPageState createState() => _AllRecipientPageState();
}

class _AllRecipientPageState extends State<AllRecipientPage> {
  late Future<List<Alluser>> _recipientsFuture;

  Future<List<Document>> fetchRecipientDocuments(String donorId, String country) async {
    final documentService = AlluserData();
    return await documentService.getUserDocuments(donorId, country);
  }

  @override
  void initState() {
    super.initState();
    _recipientsFuture = AlluserData().getAllUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Recipients'),
      ),
      body: FutureBuilder<List<Alluser>>(
        future: _recipientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No recipients found.'));
          } else {
            final recipients = snapshot.data!;
            return ListView.builder(
              itemCount: recipients.where((recipient) => recipient.usertype == 'recipient').length,
              itemBuilder: (context, index) {
                final recipient = recipients.where((recipient) => recipient.usertype == 'recipient').toList()[index];
                return ListTile(
                  leading: recipient.avatar != null && recipient.avatar!.url != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(recipient.avatar!.url!),
                        )
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text('${recipient.firstname} ${recipient.lastname}'),
                  subtitle: Text('${recipient.country ?? "N/A"} | ${recipient.phoneNumber ?? "N/A"}'),
                  onTap: () {
                    _navigateToRecipientDetails(context, recipient);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  void _navigateToRecipientDetails(BuildContext context, Alluser recipient) async {
    try {
      Alluser recipientDetails = await AlluserData().getUserById(recipient.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => RecipientDetailsPage(recipient: recipient, recipientDetails: recipientDetails),
        ),
      );
    } catch (e) {
      _showErrorDialog(context, 'Failed to load recipient details: $e');
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
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class RecipientDetailsPage extends StatelessWidget {
  final Alluser recipient;
  final Alluser recipientDetails;

  RecipientDetailsPage({required this.recipient, required this.recipientDetails});

  Future<List<Document>> fetchRecipientDocuments(String donorId, String country) async {
    final documentService = AlluserData();
    return await documentService.getUserDocuments(donorId, country);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${recipient.firstname} ${recipient.lastname}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${recipient.firstname} ${recipient.lastname}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Phone: ${recipient.phoneNumber ?? "N/A"}'),
            Text('Country: ${recipient.country ?? "N/A"}'),
            Text('Email: ${recipient.email}'),
            Text('Date of Birth: ${recipient.dateofbirth != null ? recipient.dateofbirth!.toLocal().toString().split(' ')[0] : 'N/A'}'),
            Text('Blood Group: ${recipient.bloodGroup ?? 'N/A'}'),
            Expanded(
              child: FutureBuilder<List<Document>>(
                future: fetchRecipientDocuments(recipient.id, recipient.country ?? ''),
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

