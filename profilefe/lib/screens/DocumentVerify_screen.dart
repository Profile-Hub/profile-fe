import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/donerDetails.dart';
import '../models/Documentmodel.dart';
import '../services/getdoner_service.dart';
import '../services/admin_services.dart';
import '../theme.dart';
import 'package:go_router/go_router.dart';
import '../routes.dart';

class DocumentverifyPage extends StatefulWidget {
  final String donorId;
  
  DocumentverifyPage({required this.donorId});

  @override
  State<DocumentverifyPage> createState() => _DocumentverifyPageState();
}

class _DocumentverifyPageState extends State<DocumentverifyPage> {
  final AdminService _adminService = AdminService();
  bool _isProcessing = false;
  
  Future<DonerDetails> fetchDonorDetails(String id) async {
    final donorService = DonnerService();
    return await donorService.getDonorById(id);
  }

  Future<List<Document>> fetchDonorDocuments(String donorId, String country) async {
    final documentService = DonnerService();
    return await documentService.getDonorDocuments(donorId, country);
  }

  Future<void> handleApproveReject(String documentId, bool approve, BuildContext context) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final response = await _adminService.approveOrRejectVerification(documentId, approve);
      if (response == 'success') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(approve ? 'Document Approved' : 'Document Rejected')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to process the document')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    await Future.delayed(const Duration(seconds: 2));
    
    if (context.mounted) {
      GoRouter.of(context).go(Routes.adminVerify);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            GoRouter.of(context).go(Routes.adminVerify);
          },
        ),
        title: const Text('All Details'),
      ),
      body: FutureBuilder<DonerDetails>(
        future: fetchDonorDetails(widget.donorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No donor found.'));
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
                  _buildAboutSection(donor, context),
                  const SizedBox(height: 24),
                  _buildDocumentsSection(context, donor),
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

  Widget _buildAboutSection(DonerDetails donor, BuildContext context) {
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
        _buildInfoItem('Blood Group', donor.bloodGroup ?? 'N/A'),
        _buildInfoItem('Gender', donor.gender ?? 'N/A'),
        _buildInfoItem('Email', donor.email),
        _buildInfoItem('Phone Number', '+${donor.phoneCode ?? ""} ${donor.phoneNumber ?? "N/A"}'),
        _buildInfoItem('Date of Birth', donor.dateofbirth != null ? DateFormat.yMMMd().format(donor.dateofbirth!) : 'N/A'),
        _buildInfoItem('City', donor.city ?? 'N/A'),
        _buildInfoItem('State', donor.state ?? 'N/A'),
        _buildInfoItem('Country', donor.country ?? 'N/A'),
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
    return FutureBuilder<List<Document>>(
      future: fetchDonorDocuments(widget.donorId, donor.country ?? ''),
      builder: (context, docSnapshot) {
        if (docSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (docSnapshot.hasError || !docSnapshot.hasData || docSnapshot.data!.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No documents available.',
                        style: TextStyle(fontSize: 16, color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        final documents = docSnapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...documents.expand((document) {
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
                        onPressed: () => _openDocument(fileEntry.value),
                        child: Text('Preview'),
                      ),
                    ],
                  ),
                );
              });
            }).toList(),
            const SizedBox(height: 24),
            _buildButtonsSection(context, docSnapshot.data!),
          ],
        );
      },
    );
  }

  Widget _buildButtonsSection(BuildContext context, List<Document> documents) {
    if (documents.isEmpty) return SizedBox.shrink();
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              // Add disabledBackgroundColor for when button is disabled
              disabledBackgroundColor: Colors.green.withOpacity(0.5),
            ),
            onPressed: _isProcessing 
                ? null 
                : () async {
                    final documentId = documents[0].id;
                    await handleApproveReject(documentId, true, context);
                  },
            child: const Text(
              'Approve',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              // Add disabledBackgroundColor for when button is disabled
              disabledBackgroundColor: Colors.red.withOpacity(0.5),
            ),
            onPressed: _isProcessing 
                ? null 
                : () async {
                    final documentId = documents[0].id;
                    await handleApproveReject(documentId, false, context);
                  },
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not open document';
    }
  }
}