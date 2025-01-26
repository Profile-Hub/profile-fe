import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/AllRecipitentDetails.dart';
import '../models/Documentmodel.dart';
import '../services/getdoner_service.dart';
import '../services/getReciptent_services.dart';
import '../services/chat_services.dart';
import  './Chat_screen.dart';
import '../routes.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';


class RecipitentDetailPage extends StatelessWidget {
  final String recipientId;

  RecipitentDetailPage({required this.recipientId});

  Future<RecipitentDetails> fetchRecipitentDetails(String id) async {
    final reciptentService = RecipitentService();
    return await reciptentService.getRecipitentById(id);
  }

  Future<List<Document>> fetchDonorDocuments(String recipientId, String country) async {
    final documentService = DonnerService();
    return await documentService.getDonorDocuments(recipientId, country);
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
        title: const Text('All Details')),
      body: FutureBuilder<RecipitentDetails>(
        future: fetchRecipitentDetails(recipientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No donor found.'));
          } else {
            final recipient = snapshot.data!;
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
                          backgroundImage: NetworkImage("${recipient.avatar!.url}"),
                          radius: 50,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Name: ${recipient.firstname} ${recipient.lastname}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Date of Birth: ${recipient.dateofbirth != null ? DateFormat.yMMMd().format(recipient.dateofbirth!) : 'N/A'}',
                      ),
                      Text('Gender: ${recipient.gender ?? 'N/A'}'),
                      Text('City: ${recipient.city ?? 'N/A'}'),
                      Text('State: ${recipient.state ?? 'N/A'}'),
                      Text('Country: ${recipient.country ?? 'N/A'}'),
                      Text('Blood Group: ${recipient.bloodGroup ?? 'N/A'}'),
                      const SizedBox(height: 20),
                      FutureBuilder<List<Document>>(
                        future: fetchDonorDocuments(recipientId, recipient.country ?? ''),
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
                        'No document are available.',
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
                        'No document are available.',
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
                                            .toList() ??
                                        [];

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
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, 
        padding: const EdgeInsets.symmetric(vertical: 15), 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () async {
        try {
          final recipientId =recipient.id; 
           final chatService = ChatServices(); 
          final conversationSid = await chatService.getOrCreateConversation(recipient.id);

          GoRouter.of(context).go(
            '${Routes.chat}/$conversationSid',
            extra: {
         'conversationSid':conversationSid,
         'userName':recipient.firstname,
         'profileImage':recipient.avatar!.url,
      },
          );
        } catch (e) {
          print("Error fetching conversation SID: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to initiate chat")),
          );
        }
      },
      child: const Text(
        'Let\'s Chat',
        style: TextStyle(color: Colors.white, fontSize: 16), // Ensure text color is white
      ),
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

  void _openDocument(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not open the document';
    }
  }
}
