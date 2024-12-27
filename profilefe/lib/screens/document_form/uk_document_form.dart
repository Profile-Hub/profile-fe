import 'package:flutter/material.dart';

class UKDocumentForm extends StatelessWidget {
  const UKDocumentForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UK Document Form')),
      body: Center(child: const Text('Upload your documents for the United Kingdom.')),
    );
  }
}
