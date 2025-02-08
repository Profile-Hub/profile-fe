import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/donerDetails.dart';
import '../models/Documentmodel.dart';
import '../services/getdoner_service.dart';
import '../services/chat_services.dart';
import '../routes.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../theme.dart';

class DonorDetailPage extends StatelessWidget {
  final String donorId;

  const DonorDetailPage({Key? key, required this.donorId}) : super(key: key);

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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go(Routes.home),
        ),
      ),
      body: FutureBuilder<DonerDetails>(
        future: fetchDonorDetails(donorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${localizations.error}: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text(localizations.noDonorFound));
          }

          final donor = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildDonorHeader(context, donor),
                  const SizedBox(height: 24),
                  _buildAboutSection(donor,context),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  _buildDocumentsSection(context, donor),
                  const SizedBox(height: 24),
                  _buildAppointmentSection(context, donor, localizations),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDonorHeader(BuildContext context, DonerDetails donor) {
    return Row(
      children: [
        _buildAvatar(donor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${donor.firstname} ${donor.lastname}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${donor.usertype ?? ''} - ${donor.city ?? ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(DonerDetails donor) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.grey[200],
      child: ClipOval(
        child: donor.avatar?.url != null && donor.avatar!.url.isNotEmpty
            ? Image.network(
                donor.avatar!.url,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.account_circle, size: 40);
                },
              )
            : const Icon(Icons.account_circle, size: 40),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryBlue),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(DonerDetails donor,context) {
     final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Donor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoItem(localizations.bloodGroup, donor.bloodGroup ?? 'N/A'),
        _buildInfoItem(localizations.gender_label, donor.gender ?? 'N/A'),
        _buildInfoItem(localizations.email, donor.email),
        _buildInfoItem(localizations.phoneNumber, '+${donor.phoneCode ?? ""} ${donor.phoneNumber ?? "N/A"}'),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textGrey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context, DonerDetails donor) {
     final localization = AppLocalizations.of(context)!;
    return FutureBuilder<List<Document>>(
      future: fetchDonorDocuments(donorId, donor.country ?? ''),
      builder: (context, docSnapshot) {
        if (docSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (docSnapshot.hasError || !docSnapshot.hasData || docSnapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.document,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...docSnapshot.data!.expand((document) {
              final documentFiles = document.files?.entries
                  .where((entry) => entry.value.isNotEmpty)
                  .toList() ?? [];

              return documentFiles.map((fileEntry) {
                final fileName = fileEntry.key.split('/').last;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openDocument(context, fileEntry.value),
                        child:  Text(localization.preview),
                      ),
                    ],
                  ),
                );
              });
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentSection(BuildContext context, DonerDetails donor, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _initiateChat(context, donor, localizations),
            child: Text(localizations.letChat),
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton(String text, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: MaterialButton(
        onPressed: () {},
        color: isSelected ? AppTheme.primaryBlue : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
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
          'profileImage': donor.avatar?.url,
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.failedInititeChat)),
        );
      }
    }
  }

  Future<void> _openDocument(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw AppLocalizations.of(context)!.notopenDocument;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}