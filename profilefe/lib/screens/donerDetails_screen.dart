import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/donerDetails.dart';
import '../models/Documentmodel.dart';
import '../services/getdoner_service.dart';
import '../services/getdoner_service.dart';
import '../services/chat_services.dart';
import  './Chat_screen.dart';
import '../routes.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


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
     final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
       GoRouter.of(context).go(Routes.home);
    },
  ),
        title:  Text(localizations.allDetails)),
      body: FutureBuilder<DonerDetails>(
        future: fetchDonorDetails(donorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${localizations.error}: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return  Center(child: Text(localizations.noDonorFound));
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
    backgroundImage: (donor.avatar?.url != null && donor.avatar!.url.isNotEmpty)
        ? NetworkImage(donor.avatar!.url)
        : null,
    radius: 50,
    child: (donor.avatar?.url == null || donor.avatar!.url.isEmpty)
        ? Icon(Icons.account_circle, size: 50)
        : null,
  ),
),
                      const SizedBox(height: 20),
                      Text(
                        '${localizations.name}: ${donor.firstname} ${donor.lastname}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${localizations.date_of_birth_label}: ${donor.dateofbirth != null ? DateFormat.yMMMd().format(donor.dateofbirth!) : 'N/A'}',
                      ),
                      Text('${localizations.gender_label}: ${donor.gender ?? 'N/A'}'),
                      Text('${localizations.email}: ${donor.email}'),
                      Text(
                        '${localizations.phoneNumber}: ${donor.phoneCode != null && donor.phoneNumber != null ? '${donor.phoneCode} ${donor.phoneNumber}' : 'N/A'}',
                      ),
                      Text('${localizations.city_label}: ${donor.city ?? 'N/A'}'),
                      Text('${localizations.state_label}: ${donor.state ?? 'N/A'}'),
                      Text('${localizations.country_label}: ${donor.country ?? 'N/A'}'),
                      Text('${localizations.user_type_label}: ${donor.usertype ?? 'N/A'}'),
                      Text('${localizations.bloodGroup}: ${donor.bloodGroup ?? 'N/A'}'),
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
                       Text(
                        localizations.noDocumentsFound,
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
                       Text(
                        localizations.noDocumentsFound,
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
                                 Text(
                                 localizations.donorDocuments,
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
                         return Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        fileName,
        style: const TextStyle(fontSize: 16, color: Colors.black),
        overflow: TextOverflow.ellipsis,
      ),
    ),
    const SizedBox(width: 10), 
    Padding(
      padding: const EdgeInsets.only(top: 9.0), // Add space above the button
      child: ElevatedButton(
        onPressed: () => _openDocument(context,fileEntry.value),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 4), 
          textStyle: const TextStyle(fontSize: 14), 
        ),
        child:  Text(localizations.preview),
      ),
    ),
  ],
);

                        }).toList(),
                        const SizedBox(height: 10),
                      ],
                    )
                  : const SizedBox.shrink();
            },
          ),
                                const SizedBox(height: 10),
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
          final donorId = donor.id; 
           final chatService = ChatServices(); 
          final conversationSid = await chatService.getOrCreateConversation(donor.id);

          GoRouter.of(context).go(
            '${Routes.chat}/$conversationSid',
            extra: {
         'conversationSid':conversationSid,
         'userName':donor.firstname,
         'profileImage':donor.avatar!.url,
      },
          );
        } catch (e) {
          print("Error fetching conversation SID: $e");
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(localizations.failedInititeChat)),
          );
        }
      },
      child:  Text(
        localizations.letChat,
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

  void _openDocument(BuildContext context,String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw '${AppLocalizations.of(context)!.notopenDocument}';;
    }
  }
}
