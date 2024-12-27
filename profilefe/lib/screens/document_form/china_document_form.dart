import 'package:flutter/material.dart';

class ChinaDocumentForm extends StatelessWidget {
  const ChinaDocumentForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('China Document Form')),
      body: Center(child: const Text('Upload your documents for China.')),
    );
  }
}
