import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class IndiaDocumentForm extends StatefulWidget {
   IndiaDocumentForm({Key? key}) : super(key: key);

  @override
  _IndiaDocumentFormState createState() => _IndiaDocumentFormState();
}

class _IndiaDocumentFormState extends State<IndiaDocumentForm> {
  final _formKey = GlobalKey<FormState>();

  // Controller for each text field
  final TextEditingController _aadhaarNameController = TextEditingController();
  final TextEditingController _aadhaarNumberController = TextEditingController();
  final TextEditingController _aadhaarAddressController = TextEditingController();
  final TextEditingController _aadhaarFatherNameController = TextEditingController();
  final TextEditingController _passportNumberController = TextEditingController();
  final TextEditingController _voterIdNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController = TextEditingController();
  final TextEditingController _panNumberController = TextEditingController();
  final TextEditingController _rationCardNumberController = TextEditingController();

  // Selected file paths for document uploads
  File? _aadhaarFile;
  File? _passportFile;
  File? _voterIdFile;
  File? _driverLicenseFile;
  File? _panCardFile;
  File? _rationCardFile;

  // Method to pick a file
  Future<void> _pickFile(String documentType) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'pdf']);
    if (result != null) {
      setState(() {
        switch (documentType) {
          case 'Aadhaar':
            _aadhaarFile = File(result.files.single.path!);
            break;
          case 'Passport':
            _passportFile = File(result.files.single.path!);
            break;
          case 'Voter ID':
            _voterIdFile = File(result.files.single.path!);
            break;
          case 'Driver License':
            _driverLicenseFile = File(result.files.single.path!);
            break;
          case 'PAN Card':
            _panCardFile = File(result.files.single.path!);
            break;
          case 'Ration Card':
            _rationCardFile = File(result.files.single.path!);
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('Upload Documents - India'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTextField('Aadhaar Card', 'Full Name', _aadhaarNameController),
              _buildTextField('Aadhaar Card', 'Aadhaar Number', _aadhaarNumberController),
              _buildTextField('Aadhaar Card', 'Address', _aadhaarAddressController),
              _buildTextField('Aadhaar Card', 'Father\'s Name', _aadhaarFatherNameController),
              _buildFileUpload('Aadhaar Card', 'Upload Aadhaar Document', _aadhaarFile),

              _buildTextField('Passport', 'Passport Number', _passportNumberController),
              _buildFileUpload('Passport', 'Upload Passport Document', _passportFile),

              _buildTextField('Voter ID', 'Voter ID Number', _voterIdNumberController),
              _buildFileUpload('Voter ID', 'Upload Voter ID Document', _voterIdFile),

              _buildTextField('Driver License', 'Driver License Number', _driverLicenseNumberController),
              _buildFileUpload('Driver License', 'Upload Driver License Document', _driverLicenseFile),

              _buildTextField('PAN Card', 'PAN Number', _panNumberController),
              _buildFileUpload('PAN Card', 'Upload PAN Card Document', _panCardFile),

              _buildTextField('Ration Card', 'Ration Card Number', _rationCardNumberController),
              _buildFileUpload('Ration Card', 'Upload Ration Card Document', _rationCardFile),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Form submission logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Processing Data')),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to create text fields for input
  Widget _buildTextField(String documentType, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  // Helper method to create a file upload button
  Widget _buildFileUpload(String documentType, String label, File? file) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () => _pickFile(documentType),
            child: Text('Upload $documentType'),
          ),
          const SizedBox(width: 8),
          Text(file != null ? 'File Selected' : 'No file selected'),
        ],
      ),
    );
  }
}
