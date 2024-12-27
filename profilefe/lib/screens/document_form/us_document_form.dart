import 'package:flutter/material.dart';

class USDocumentForm extends StatelessWidget {
  const USDocumentForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('US Document Form')),
      body: Center(child: const Text('Upload your documents for the United States.')),
    );
  }
}
