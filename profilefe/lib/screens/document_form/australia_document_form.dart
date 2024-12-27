import 'package:flutter/material.dart';

class AustraliaDocumentForm extends StatelessWidget {
  const AustraliaDocumentForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Australia Document Form')),
      body: Center(child: const Text('Upload your documents for Australia and New Zealand.')),
    );
  }
}
