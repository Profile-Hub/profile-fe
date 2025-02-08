import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/donerDetails.dart';
import '../models/Documentmodel.dart';
import '../services/getdoner_service.dart';
import '../services/chat_services.dart';
import './Chat_screen.dart';
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
        title: Text(localizations.allDetails),
      ),
      body: SingleChildScrollView( // Wrap with SingleChildScrollView to prevent overflow
        child: FutureBuilder<DonerDetails>(
          future: fetchDonorDetails(donorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('${localizations.error}: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return Center(child: Text(localizations.noDonorFound));
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
                                ? const Icon(Icons.account_circle, size: 50)
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
                              return _buildErrorCard(localizations);
                            } else if (!docSnapshot.hasData || docSnapshot.data!.isEmpty) {
                              return _buildNoDocumentsCard(localizations);
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizations.donorDocuments,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  ...docSnapshot.data!.expand((document) {
                                    final documentFiles = document.files?.entries
                                            .where((entry) => entry.value.isNotEmpty)
                                            .toList() ??
                                        [];

                                    return documentFiles.map((fileEntry) {
                                      final fileName = fileEntry.key.split('/').last;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                fileName,
                                                style: const TextStyle(fontSize: 16),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 100, // Fixed width for the button
                                              child: ElevatedButton(
                                                onPressed: () => _openDocument(context, fileEntry.value),
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                ),
                                                child: Text(localizations.preview),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    });
                                  }).toList(),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => _initiateChat(context, donor, localizations),
                                      child: Text(
                                        localizations.letChat,
                                        style: const TextStyle(color: Colors.white, fontSize: 16),
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
      ),
    );
  }

  Widget _buildErrorCard(AppLocalizations localizations) {
    return _buildMessageCard(
      icon: Icons.insert_drive_file,
      iconColor: Colors.red,
      message: localizations.noDocumentsFound,
    );
  }

  Widget _buildNoDocumentsCard(AppLocalizations localizations) {
    return _buildMessageCard(
      icon: Icons.insert_drive_file,
      iconColor: Colors.grey,
      message: localizations.noDocumentsFound,
    );
  }

  Widget _buildMessageCard({
    required IconData icon,
    required Color iconColor,
    required String message,
  }) {
    return Card(
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
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateChat(BuildContext context, DonerDetails donor, AppLocalizations localizations) async {
    try {
      final chatService = ChatServices();
      final conversationSid = await chatService.getOrCreateConversation(donor.id);

      GoRouter.of(context).go(
        '${Routes.chat}/$conversationSid',
        extra: {
          'conversationSid': conversationSid,
          'userName': donor.firstname,
          'profileImage': donor.avatar!.url,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.failedInititeChat)),
      );
    }
  }

  Future<void> _openDocument(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw AppLocalizations.of(context)!.notopenDocument;
    }
  }
}