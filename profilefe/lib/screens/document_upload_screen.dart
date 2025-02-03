import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:go_router/go_router.dart'; 
import '../routes.dart';
import 'document_form/india_document_form.dart';
import 'document_form/us_document_form.dart';
import 'document_form/uk_document_form.dart';
import 'document_form/australia_document_form.dart';
import 'document_form/uae_document_form.dart';
import 'document_form/china_document_form.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DocumentUploadScreen extends StatelessWidget {
  final User user;

  DocumentUploadScreen({Key? key, required this.user}) : super(key: key);

  Widget _getFormForCountry(String country) {
    switch (country) {
      case 'India':
        return IndiaDocumentForm();
      case 'United States':
        return USDocumentForm();
      case 'United Kingdom':
        return UKDocumentForm();
      case 'Australia':
      case 'New Zealand':
        return AustraliaDocumentForm();
      case 'United Arab Emirates':
        return UAEDocumentForm();
      case 'China':
        return ChinaDocumentForm();
      default:
        return Center(
          child: Text(
            'Document form is not available for this country.',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
     final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.documentUpload),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
           onPressed: () {
      GoRouter.of(context).go(Routes.home);
    },
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Expanded(child: _getFormForCountry(user.country!)), // Embed the form here
          ],
        ),
      ),
    );
  }
}
