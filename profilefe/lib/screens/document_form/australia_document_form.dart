import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

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

  // Upload statuses
  bool _isLoading = false;

  // File picker and upload function
  Future<void> _pickAndUploadFile(String documentType, String endpoint) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      // Check file size (less than 5 MB)
      if (file.lengthSync() <= 5 * 1024 * 1024) {
        setState(() {
          _isLoading = true;
        });
        try {
          var request = http.MultipartRequest('POST', Uri.parse(endpoint));
          request.files.add(
            await http.MultipartFile.fromPath('file', file.path),
          );
          var response = await request.send();

          if (response.statusCode == 200) {
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$documentType uploaded successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload $documentType')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading $documentType: $e')),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
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
              _buildFileUploadSection('Passport', _passportFile, 'http://localhost:4000/api/v1/aus/passport'),

              // Driver's License File Upload
              _buildFileUploadSection('Driver License', _driverLicenseFile, 'http://localhost:4000/api/v1/aus/drivers-license'),

              // Medicare Card File Upload
              _buildFileUploadSection('Medicare Card', _medicareFile, 'http://localhost:4000/api/v1/aus/medicare-card'),

              // Birth Certificate File Upload
              _buildFileUploadSection('Birth Certificate', _birthCertificateFile, 'http://localhost:4000/api/v1/aus/birth-certificate'),

              // Proof of Age Card File Upload
              _buildFileUploadSection('Proof of Age Card', _proofOfAgeFile, 'http://localhost:4000/api/v1/aus/proof-of-age-card'),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for file upload section
  Widget _buildFileUploadSection(String docType, File? file, String endpoint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            docType,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: file != null ? file.path.split('/').last : 'No file selected',
                    hintStyle: TextStyle(
                      color: file != null ? Colors.black : Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _pickAndUploadFile(docType, endpoint),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Upload'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}