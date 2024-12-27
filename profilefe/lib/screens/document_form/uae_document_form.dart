import 'package:flutter/material.dart';

class UAEDocumentForm extends StatelessWidget {
  const UAEDocumentForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UAE Document Form')),
      body: Center(child: const Text('Upload your documents for the United Arab Emirates.')),
    );
  }
}
