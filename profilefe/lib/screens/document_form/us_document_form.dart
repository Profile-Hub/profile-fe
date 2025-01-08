import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Add this import
import 'package:flutter/foundation.dart';
import '../../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class USDocumentForm extends StatefulWidget {
    USDocumentForm({Key? key}) : super(key: key);

  @override
  _USDocumentFormState createState() => _USDocumentFormState();
}

class _USDocumentFormState extends State<USDocumentForm> {
  // Map to store selected files or bytes for each document type
  Map<String, PlatformFile?> selectedFiles = {
    'Social Security Card': null,
    'Passport': null,
    'Driver License': null,
    'Birth Certificate': null,
    'Green Card': null,
  };

  // Map to store uploading state for each document type
  Map<String, bool> isUploading = {
    'Social Security Card': false,
    'Passport': false,
    'Driver License': false,
    'Birth Certificate': false,
    'Green Card': false,
  };

  // Map to store uploaded state for each document type
  Map<String, bool> isUploaded = {
    'Social Security Card': false,
    'Passport': false,
    'Driver License': false,
    'Birth Certificate': false,
    'Green Card': false,
  };

  String? _token;
  static final _storage = FlutterSecureStorage();

  // Load token
  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }

  @override
  void initState() {
    super.initState();
    _loadToken(); // Load token when the widget is initialized
  }

  // Method to select a file for a given document type with file type filter
  Future<void> _selectFile(String documentType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf'], // Restrict to specific file types
      );

      if (result != null) {
        final file = result.files.first;

        if (file.size <= 5 * 1024 * 1024) { // File size limit (5MB)
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

  // Method to upload a file to the server
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

      // Add the token to the headers
      request.headers['Authorization'] = 'Bearer $_token';
      request.headers['Content-Type'] = 'multipart/form-data';
      MediaType mediaType; 
      final extension = fileData.extension;
      if (extension == 'jpg' || extension == 'jpeg') {
         mediaType = MediaType('image', 'jpeg');
          } 
          else if (extension == 'png') {
             mediaType = MediaType('image', 'png'); 
             }
              else if (extension == 'pdf') {
                 mediaType = MediaType('application', 'pdf'); 
                 } 
                 else {
                   throw UnsupportedError('File type not supported. Only JPG, PNG, and PDF are allowed.'); 
                   }
      if (kIsWeb) {
        // Web-specific handling: use bytes for file upload
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileData.bytes!,
            filename: fileData.name,
            contentType: mediaType, 
          ),
        );
      } else {
        // Android/iOS specific handling: use file path for file upload
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            fileData.path!,
            contentType: mediaType, // Automatically handled by Flutter
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('US Document Form'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFileInputSection(
              'Social Security Card',
              '${ServerConfig.baseUrl}/us/social-security-card',
            ),
            _buildFileInputSection(
              'Passport',
              '${ServerConfig.baseUrl}us/passport',
            ),
            _buildFileInputSection(
              'Driver License',
              '${ServerConfig.baseUrl}us/drivers-license',
            ),
            _buildFileInputSection(
              'Birth Certificate',
              '${ServerConfig.baseUrl}us/birth-certificate',
            ),
            _buildFileInputSection(
              'Green Card',
              '${ServerConfig.baseUrl}us/green-card',
            ),
          ],
        ),
      ),
    );
  }

  // Method to build UI for each file input section
  Widget _buildFileInputSection(String docType, String endpoint) {
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
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  onTap: isUploaded[docType]! ? null : () async {
                    await _selectFile(docType);  // Ensure file selection completes before interacting with the input
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
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isUploaded[docType]! ? null : () async {
                  await _selectFile(docType);  // Ensure file selection completes before interacting with the button
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
}
