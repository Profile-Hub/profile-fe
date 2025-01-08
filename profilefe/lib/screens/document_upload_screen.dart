import 'package:flutter/material.dart';
import '../models/user.dart';
import 'document_form/india_document_form.dart';
import 'document_form/us_document_form.dart';
import 'document_form/uk_document_form.dart';
import 'document_form/australia_document_form.dart';
import 'document_form/uae_document_form.dart';
import 'document_form/china_document_form.dart';

class DocumentUploadScreen extends StatefulWidget {
  final User user;

  // Removed 'const' constructor to make it work with GoRouter
  DocumentUploadScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  late String country;

  @override
  void initState() {
    super.initState();
    country = widget.user.country!;
  }

  Widget navigateToDocumentForm() {
    switch (country) {
      case 'India':
        return  IndiaDocumentForm();
      case 'United States':
        return  USDocumentForm();
      case 'United Kingdom':
        return  UKDocumentForm();
      case 'Australia':
      case 'New Zealand': 
        return  AustraliaDocumentForm();
      case 'United Arab Emirates':
        return  UAEDocumentForm();
      case 'China':
        return  ChinaDocumentForm();
      default:
        return const Scaffold(
          body: Center(child: Text('Document form is not available for this country.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigateToDocumentForm(),
    );
  }
}
