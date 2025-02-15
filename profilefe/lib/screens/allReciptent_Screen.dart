import 'package:flutter/material.dart';
import '../models/allUserAdmin.dart';
import '../models/donerDetails.dart';
import '../models/Documentmodel.dart';
import '../services/getAlluser_services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../routes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AllRecipientPage extends StatefulWidget {
  @override
  _AllRecipientPageState createState() => _AllRecipientPageState();
}

class _AllRecipientPageState extends State<AllRecipientPage> {
  late Future<List<Alluser>> _recipientsFuture;
  String searchQuery = '';

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
     final localizations = AppLocalizations.of(context)!;
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
  hintText:localizations.searchRecipitent,
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
        future: _recipientsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${localizations.error}: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(localizations.noDocumentsFound));
          } else {
            final recipients = snapshot.data!;
  final searchParts = searchQuery.split(' ');
  final filteredRecipients = recipients.where((recipient) {
    
    return recipient.usertype == 'recipient' &&
        searchParts.every((part) =>
            recipient.firstname.toLowerCase().contains(part) ||
            recipient.lastname.toLowerCase().contains(part));
  }).toList();

            return ListView.builder(
              itemCount: filteredRecipients.length,
              itemBuilder: (context, index) {
                final recipient = filteredRecipients[index];
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
     final localization = AppLocalizations.of(context)!;
  try {
    Alluser recipientDetails = await AlluserData().getUserById(recipient.id);
    GoRouter.of(context).push(
      '/donorDetails/${recipient.id}',  // Use your predefined route
      extra: {'recipient': recipient, 'recipientDetails': recipientDetails},  // Pass data using 'extra'
    );
  } catch (e) {
    _showErrorDialog(context, '${localization.failedReciptentDetails}: $e');
  }
}

  void _showErrorDialog(BuildContext context, String message) {
     final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.error),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
               GoRouter.of(context).pop();
              },
              child: Text(localizations.close),
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

  // Non-const constructor
  RecipientDetailsPage({required this.recipient, required this.recipientDetails});

  Future<List<Document>> fetchRecipientDocuments(String donorId, String country) async {
    final documentService = AlluserData();
    return await documentService.getUserDocuments(donorId, country);
  }

  @override
  Widget build(BuildContext context) {
     final localizations = AppLocalizations.of(context)!;
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
            Text('${localizations.phoneNumber}: ${recipient.phoneNumber ?? "N/A"}'),
            Text('${localizations.country_label}: ${recipient.country ?? "N/A"}'),
            Text('${localizations.email}: ${recipient.email}'),
            Text('${localizations.date_of_birth_label}: ${recipient.dateofbirth != null ? recipient.dateofbirth!.toLocal().toString().split(' ')[0] : 'N/A'}'),
            Text('${localizations.bloodGroup}: ${recipient.bloodGroup ?? 'N/A'}'),
            Expanded(
              child: FutureBuilder<List<Document>>(
                future: fetchRecipientDocuments(recipient.id, recipient.country ?? ''),
                builder: (context, docSnapshot) {
                  if (docSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (docSnapshot.hasError) {
                    return Center(child: Text('${localizations.error}: ${docSnapshot.error}'));
                  } else if (!docSnapshot.hasData || docSnapshot.data!.isEmpty) {
                    return Center(child: Text(localizations.noDocumentsFound));
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
                                    '${localizations.document} ${index + 1}',
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
     final localizations = AppLocalizations.of(context)!;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw localizations.notopenDocument;
    }
  }
}
