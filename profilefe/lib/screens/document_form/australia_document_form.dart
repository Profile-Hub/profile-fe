import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AustraliaDocumentForm extends StatefulWidget {
  const AustraliaDocumentForm({Key? key}) : super(key: key);

  @override
  _AustraliaDocumentFormState createState() => _AustraliaDocumentFormState();
}

class _AustraliaDocumentFormState extends State<AustraliaDocumentForm> {
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
      appBar:  AppBar(
        title: Text('Australia Document Form'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Passport File Upload
              _buildFileUpload('Passport', _passportFile),

              // Driver's License File Upload
              _buildFileUpload('Driver License', _driverLicenseFile),

              // Medicare Card File Upload
              _buildFileUpload('Medicare Card', _medicareFile),

              // Birth Certificate File Upload
              _buildFileUpload('Birth Certificate', _birthCertificateFile),

              // Proof of Age Card File Upload
              _buildFileUpload('Proof of Age Card', _proofOfAgeFile),

              // Submit Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Processing Data')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // Corrected parameter
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for file upload
  Widget _buildFileUpload(String docType, File? file) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: () => _pickFile(docType),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Corrected parameter
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Upload $docType'),
          ),
          const SizedBox(width: 8),
          Text(
            file != null ? 'File Selected' : 'No file selected',
            style: TextStyle(
              color: file != null ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
