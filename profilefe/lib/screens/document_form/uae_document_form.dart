import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UAEDocumentForm extends StatefulWidget {
  const UAEDocumentForm({Key? key}) : super(key: key);

  @override
  _UAEDocumentFormState createState() => _UAEDocumentFormState();
}

class _UAEDocumentFormState extends State<UAEDocumentForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _emiratesIDNumberController = TextEditingController();
  final TextEditingController _passportNumberController = TextEditingController();
  final TextEditingController _visaNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController = TextEditingController();
  final TextEditingController _labourCardNumberController = TextEditingController();

  // File upload variables
  File? _emiratesIDFile;
  File? _passportFile;
  File? _visaFile;
  File? _driverLicenseFile;
  File? _labourCardFile;

  // File picker function
  Future<void> _pickFile(String documentType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      // Validate file size (less than 5 MB)
      if (file.lengthSync() <= 5 * 1024 * 1024) {
        setState(() {
          switch (documentType) {
            case 'Emirates ID':
              _emiratesIDFile = file;
              break;
            case 'Passport':
              _passportFile = file;
              break;
            case 'Residence Visa':
              _visaFile = file;
              break;
            case 'Driver License':
              _driverLicenseFile = file;
              break;
            case 'Labour Card':
              _labourCardFile = file;
              break;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size must be less than 5MB')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UAE Document Form'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Emirates ID
              _buildTextField('Emirates ID', 'ID Number', _emiratesIDNumberController),
              _buildFileUpload('Emirates ID', 'Upload Emirates ID Document', _emiratesIDFile),

              // Passport
              _buildTextField('Passport', 'Passport Number', _passportNumberController),
              _buildFileUpload('Passport', 'Upload Passport Document', _passportFile),

              // Residence Visa
              _buildTextField('Residence Visa', 'Visa Number', _visaNumberController),
              _buildFileUpload('Residence Visa', 'Upload Residence Visa Document', _visaFile),

              // Driver's License
              _buildTextField('Driver License', 'License Number', _driverLicenseNumberController),
              _buildFileUpload('Driver License', 'Upload Driver License Document', _driverLicenseFile),

              // Labour Card
              _buildTextField('Labour Card', 'Labour Card Number', _labourCardNumberController),
              _buildFileUpload('Labour Card', 'Upload Labour Card Document', _labourCardFile),

              // Submit Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
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

  // Helper for text input
  Widget _buildTextField(String docType, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$docType - $label',
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

  // Helper for file upload
  Widget _buildFileUpload(String docType, String label, File? file) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () => _pickFile(docType),
            child: Text('Upload $docType'),
          ),
          const SizedBox(width: 8),
          Text(file != null ? 'File Selected' : 'No file selected'),
        ],
      ),
    );
  }
}
