import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ChinaDocumentForm extends StatefulWidget {
  const ChinaDocumentForm({Key? key}) : super(key: key);

  @override
  _ChinaDocumentFormState createState() => _ChinaDocumentFormState();
}

class _ChinaDocumentFormState extends State<ChinaDocumentForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _idCardNameController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _idCardAddressController = TextEditingController();

  final TextEditingController _householdAddressController = TextEditingController();
  final TextEditingController _householdMembersController = TextEditingController();

  final TextEditingController _passportNumberController = TextEditingController();
  final TextEditingController _driverLicenseNumberController = TextEditingController();
  final TextEditingController _socialSecurityNumberController = TextEditingController();

  // File upload variables
  File? _idCardFile;
  File? _householdFile;
  File? _passportFile;
  File? _driverLicenseFile;
  File? _socialSecurityFile;

  // Method to select a file
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
            case 'ID Card':
              _idCardFile = file;
              break;
            case 'Household Registration Book':
              _householdFile = file;
              break;
            case 'Passport':
              _passportFile = file;
              break;
            case 'Driver License':
              _driverLicenseFile = file;
              break;
            case 'Social Security Card':
              _socialSecurityFile = file;
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
        title: const Text('Upload Documents - China'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Resident Identity Card Fields
              _buildTextField('ID Card', 'Full Name', _idCardNameController),
              _buildTextField('ID Card', 'ID Number', _idCardNumberController),
              _buildTextField('ID Card', 'Address', _idCardAddressController),
              _buildFileUpload('ID Card', 'Upload ID Card Document', _idCardFile),

              // Household Registration Book Fields
              _buildTextField('Household', 'Household Address', _householdAddressController),
              _buildTextField('Household', 'Number of Members', _householdMembersController),
              _buildFileUpload('Household Registration Book', 'Upload Household Document', _householdFile),

              // Passport Fields
              _buildTextField('Passport', 'Passport Number', _passportNumberController),
              _buildFileUpload('Passport', 'Upload Passport Document', _passportFile),

              // Driver's License Fields
              _buildTextField('Driver License', 'License Number', _driverLicenseNumberController),
              _buildFileUpload('Driver License', 'Upload Driver License Document', _driverLicenseFile),

              // Social Security Card Fields
              _buildTextField('Social Security', 'Security Number', _socialSecurityNumberController),
              _buildFileUpload('Social Security Card', 'Upload Social Security Document', _socialSecurityFile),

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

  // Helper for input fields
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
