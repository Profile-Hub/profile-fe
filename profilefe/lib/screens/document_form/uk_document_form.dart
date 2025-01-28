import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../routes.dart';

class UKDocumentForm extends StatefulWidget {
  final Function(bool)? onValidationChanged;
  UKDocumentForm({Key? key, this.onValidationChanged}) : super(key: key);

  @override
  _UKDocumentFormState createState() => _UKDocumentFormState();
}

class _UKDocumentFormState extends State<UKDocumentForm> {
  Map<String, PlatformFile?> selectedFiles = {
    'National Insurance Number': null,
    'Passport': null,
    'Drivers License': null,
    'Birth Certificate': null,
    'Biometric Residence Permit': null,
  };

  Map<String, bool> isUploading = {
    'National Insurance Number': false,
    'Passport': false,
    'Drivers License': false,
    'Birth Certificate': false,
    'Biometric Residence Permit': false,
  };

  Map<String, bool> isUploaded = {
    'National Insurance Number': false,
    'Passport': false,
    'Drivers License': false,
    'Birth Certificate': false,
    'Biometric Residence Permit': false,
  };

  // Map to track which documents are required
  Map<String, bool> isRequired = {
    'National Insurance Number': true,  // Making this document required
    'Passport': false,
    'Drivers License': false,
    'Birth Certificate': false,
    'Biometric Residence Permit': false,
  };

  String? _token;
  static final _storage = FlutterSecureStorage();

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _selectFile(String documentType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf'],
      );

      if (result != null) {
        final file = result.files.first;

        if (file.size <= 5 * 1024 * 1024) {
          setState(() {
            selectedFiles[documentType] = file;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size must be less than 5MB')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  Future<void> _uploadFile(String documentType, String endpoint) async {
    final fileData = selectedFiles[documentType];
    if (fileData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a file for $documentType before uploading.')),
      );
      return;
    }

    setState(() {
      isUploading[documentType] = true;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(endpoint));

      request.headers['Authorization'] = 'Bearer $_token';
      request.headers['Content-Type'] = 'multipart/form-data';
      
      MediaType mediaType;
      final extension = fileData.extension;
      if (extension == 'jpg' || extension == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else if (extension == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (extension == 'pdf') {
        mediaType = MediaType('application', 'pdf');
      } else {
        throw UnsupportedError('File type not supported. Only JPG, PNG, and PDF are allowed.');
      }

      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileData.bytes!,
            filename: fileData.name,
            contentType: mediaType,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            fileData.path!,
            contentType: mediaType,
          ),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        setState(() {
          isUploaded[documentType] = true;
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
        isUploading[documentType] = false;
      });
    }
  }

  Widget _buildFileInputSection(String docType, String endpoint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                docType,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isRequired[docType] == true)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  onTap: isUploaded[docType]! ? null : () async {
                    await _selectFile(docType);
                  },
                  decoration: InputDecoration(
                    hintText: selectedFiles[docType] != null
                        ? selectedFiles[docType]!.name
                        : 'No file selected',
                    hintStyle: TextStyle(
                      color: selectedFiles[docType] != null ? Colors.black : Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: isRequired[docType] == true && 
                             !isUploaded[docType]! && 
                             selectedFiles[docType] == null
                        ? 'This document is required'
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isUploaded[docType]! ? null : () async {
                  await _selectFile(docType);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUploaded[docType]! ? Colors.grey : Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Choose File'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isUploading[docType]! || isUploaded[docType]!
                    ? null
                    : () => _uploadFile(docType, endpoint),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUploading[docType]! || isUploaded[docType]! ? Colors.grey : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isUploading[docType]!
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFileInputSection(
              'National Insurance Number',
              '${ServerConfig.baseUrl}uk/national-insurance-number',
            ),
            _buildFileInputSection(
              'Passport',
              '${ServerConfig.baseUrl}uk/passport',
            ),
            _buildFileInputSection(
              'Drivers License',
              '${ServerConfig.baseUrl}uk/drivers-license',
            ),
            _buildFileInputSection(
              'Birth Certificate',
              '${ServerConfig.baseUrl}uk/birth-certificate',
            ),
            _buildFileInputSection(
              'Biometric Residence Permit',
              '${ServerConfig.baseUrl}uk/biometric-residence-permit',
            ),
          ],
        ),
      ),
    );
  }
}