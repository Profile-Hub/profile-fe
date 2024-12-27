import 'package:flutter/material.dart';

class IndiaDocumentForm extends StatelessWidget {
  const IndiaDocumentForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Documents - India'),
      ),
      body: const Center(
        child: Text('Upload your documents for India here.'),
      ),
    );
  }
}
