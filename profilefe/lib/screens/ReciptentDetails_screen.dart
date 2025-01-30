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
    backgroundImage: (recipient.avatar?.url != null && recipient.avatar!.url.isNotEmpty)
        ? NetworkImage(recipient.avatar!.url)
        : null,
    radius: 50,
    child: (recipient.avatar?.url == null || recipient.avatar!.url.isEmpty)
        ? Icon(Icons.account_circle, size: 50)
        : null,
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
