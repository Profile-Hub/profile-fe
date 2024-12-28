import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UKDocumentForm extends StatefulWidget {
  const UKDocumentForm({Key? key}) : super(key: key);

  @override
  _UKDocumentFormState createState() => _UKDocumentFormState();
}

class _UKDocumentFormState extends State<UKDocumentForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _passportNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController = TextEditingController();
  final TextEditingController _niNumberController = TextEditingController();
  final TextEditingController _birthCertificateController = TextEditingController();
  final TextEditingController _residencePermitController = TextEditingController();

  // File upload variables
  File? _passportFile;
  File? _driverLicenseFile;
  File? _niCardFile;
  File? _birthCertificateFile;
  File? _residencePermitFile;

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
            case 'Passport':
              _passportFile = file;
              break;
            case 'Driver License':
              _driverLicenseFile = file;
              break;
            case 'NI Card':
              _niCardFile = file;
              break;
            case 'Birth Certificate':
              _birthCertificateFile = file;
              break;
            case 'Residence Permit':
              _residencePermitFile = file;
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
        title: const Text('UK Document Form'),
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

              // NI Card
              _buildTextField('NI Card', 'NI Number', _niNumberController),
              _buildFileUpload('NI Card', 'Upload NI Card Document', _niCardFile),

              // Birth Certificate
              _buildTextField('Birth Certificate', 'Certificate Number', _birthCertificateController),
              _buildFileUpload('Birth Certificate', 'Upload Birth Certificate Document', _birthCertificateFile),

              // Residence Permit
              _buildTextField('Residence Permit', 'Permit Number', _residencePermitController),
              _buildFileUpload('Residence Permit', 'Upload Residence Permit Document', _residencePermitFile),

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
