import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class USDocumentForm extends StatefulWidget {
  const USDocumentForm({Key? key}) : super(key: key);

  @override
  _USDocumentFormState createState() => _USDocumentFormState();
}

class _USDocumentFormState extends State<USDocumentForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _ssnController = TextEditingController();
  final TextEditingController _passportNumberController = TextEditingController();
  final TextEditingController _driverLicenseController = TextEditingController();
  final TextEditingController _stateIDController = TextEditingController();
  final TextEditingController _birthCertificateController = TextEditingController();
  final TextEditingController _greenCardController = TextEditingController();

  // File upload variables
  File? _ssnFile;
  File? _passportFile;
  File? _driverLicenseFile;
  File? _stateIDFile;
  File? _birthCertificateFile;
  File? _greenCardFile;

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
            case 'SSN':
              _ssnFile = file;
              break;
            case 'Passport':
              _passportFile = file;
              break;
            case 'Driver License':
              _driverLicenseFile = file;
              break;
            case 'State ID':
              _stateIDFile = file;
              break;
            case 'Birth Certificate':
              _birthCertificateFile = file;
              break;
            case 'Green Card':
              _greenCardFile = file;
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
        title: const Text('US Document Form'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Social Security Card
              _buildTextField('SSN', 'Social Security Number', _ssnController),
              _buildFileUpload('SSN', 'Upload SSN Document', _ssnFile),

              // Passport
              _buildTextField('Passport', 'Passport Number', _passportNumberController),
              _buildFileUpload('Passport', 'Upload Passport Document', _passportFile),

              // Driver's License
              _buildTextField('Driver License', 'License Number', _driverLicenseController),
              _buildFileUpload('Driver License', 'Upload Driver License Document', _driverLicenseFile),

              // State ID Card
              _buildTextField('State ID', 'ID Number', _stateIDController),
              _buildFileUpload('State ID', 'Upload State ID Document', _stateIDFile),

              // Birth Certificate
              _buildTextField('Birth Certificate', 'Certificate Number', _birthCertificateController),
              _buildFileUpload('Birth Certificate', 'Upload Birth Certificate Document', _birthCertificateFile),

              // Green Card
              _buildTextField('Green Card', 'Green Card Number', _greenCardController),
              _buildFileUpload('Green Card', 'Upload Green Card Document', _greenCardFile),

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
