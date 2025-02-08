import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/AllRecipitentDetails.dart';
import '../models/Documentmodel.dart';
import '../services/getdoner_service.dart';
import '../services/getReciptent_services.dart';
import '../services/chat_services.dart';
import './Chat_screen.dart';
import '../routes.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../theme.dart';

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
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            GoRouter.of(context).go(Routes.home);
          },
        ),
      ),
      body: FutureBuilder<RecipitentDetails>(
        future: fetchRecipitentDetails(recipientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${localizations.error}: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text(localizations.noDonorFound));
          } else {
            final recipient = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: (recipient.avatar?.url != null && 
                              recipient.avatar!.url.isNotEmpty)
                              ? NetworkImage(recipient.avatar!.url)
                              : null,
                          child: (recipient.avatar?.url == null || 
                              recipient.avatar!.url.isEmpty)
                              ? const Icon(Icons.account_circle, size: 40)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${recipient.firstname} ${recipient.lastname}',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${recipient.city ?? ""}, ${recipient.state ?? ""}',
                                style: TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                             
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stats Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(localizations.bloodGroup, recipient.bloodGroup ?? 'N/A'),
                          _buildVerticalDivider(),
                          _buildStatColumn(localizations.gender_label, recipient.gender ?? 'N/A'),
                          _buildVerticalDivider(),
                          _buildStatColumn(localizations.date_of_birth_label, 
                            recipient.dateofbirth != null 
                              ? '${DateTime.now().year - recipient.dateofbirth!.year}'
                              : 'N/A'
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Chat Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final chatService = ChatServices();
                            final conversationSid = await chatService.getOrCreateConversation(recipient.id);

                            GoRouter.of(context).go(
                              '${Routes.chat}/$conversationSid',
                              extra: {
                                'conversationSid': conversationSid,
                                'userName': recipient.firstname,
                                'profileImage': recipient.avatar?.url,
                              },
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(localizations.failedInititeChat)),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          localizations.letChat,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppTheme.textGrey.withOpacity(0.2),
    );
  }

  void _openDocument(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw '${AppLocalizations.of(context)!.notopenDocument}';
    }
  }
}