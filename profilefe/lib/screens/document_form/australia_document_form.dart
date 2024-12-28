import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AustraliaDocumentForm extends StatefulWidget {
  const AustraliaDocumentForm({Key? key}) : super(key: key);

  @override
  _AustraliaDocumentFormState createState() => _AustraliaDocumentFormState();
}

class _AustraliaDocumentFormState extends State<AustraliaDocumentForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _passportNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController = TextEditingController();
  final TextEditingController _medicareNumberController = TextEditingController();
  final TextEditingController _birthCertificateNumberController = TextEditingController();
  final TextEditingController _proofOfAgeNumberController = TextEditingController();

  // File upload variables
  File? _passportFile;
  File? _driverLicenseFile;
  File? _medicareFile;
  File? _birthCertificateFile;
  File? _proofOfAgeFile;

  // File picker function
  Future<void> _pickFile(String documentType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      // Check file size (less than 5 MB)
      if (file.lengthSync() <= 5 * 1024 * 1024) {
        setState(() {
          switch (documentType) {
            case 'Passport':
              _passportFile = file;
              break;
            case 'Driver License':
              _driverLicenseFile = file;
              break;
            case 'Medicare Card':
              _medicareFile = file;
              break;
            case 'Birth Certificate':
              _birthCertificateFile = file;
              break;
            case 'Proof of Age Card':
              _proofOfAgeFile = file;
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
        title: const Text('Australia Document Form'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Passport
              _buildTextField('Passport', 'Passport Number', _passportNumberController),
              _buildFileUpload('Passport', 'Upload Passport Document', _passportFile),

              // Driver's License
              _buildTextField('Driver License', 'License Number', _driverLicenseNumberController),
              _buildFileUpload('Driver License', 'Upload Driver License Document', _driverLicenseFile),

              // Medicare Card
              _buildTextField('Medicare Card', 'Medicare Number', _medicareNumberController),
              _buildFileUpload('Medicare Card', 'Upload Medicare Document', _medicareFile),

              // Birth Certificate
              _buildTextField('Birth Certificate', 'Certificate Number', _birthCertificateNumberController),
              _buildFileUpload('Birth Certificate', 'Upload Birth Certificate Document', _birthCertificateFile),

              // Proof of Age Card
              _buildTextField('Proof of Age Card', 'Proof of Age Number', _proofOfAgeNumberController),
              _buildFileUpload('Proof of Age Card', 'Upload Proof of Age Document', _proofOfAgeFile),

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
