import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Add this import
import 'package:flutter/foundation.dart';
import '../../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChinaDocumentForm extends StatefulWidget {
   ChinaDocumentForm({Key? key}) : super(key: key);

  @override
  _ChinaDocumentFormState createState() => _ChinaDocumentFormState();
}

class _ChinaDocumentFormState extends State<ChinaDocumentForm> {
  Map<String, PlatformFile?> selectedFiles = {
    'Resident Identity Card': null,
    'House hold Registration': null,
    'Passport': null,
    'Driver License': null,
  };


  Map<String, bool> isUploading = {
    'Resident Identity Card': false,
    'House hold Registration': false,
    'Passport': false,
    'Driver License': false,
  };

  Map<String, bool> isUploaded = {
    'Resident Identity Card': false,
    'House hold Registration': false,
    'Passport': false,
    'Driver License': false,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('China Document Form'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFileInputSection(
              'Resident Identity Card',
              '${ServerConfig.baseUrl}china/resident-identity-card',
            ),
            _buildFileInputSection(
              'House hold Registration',
              '${ServerConfig.baseUrl}china/household-registration',
            ),
            _buildFileInputSection(
              'Passport',
              '${ServerConfig.baseUrl}china/passport',
            ),
            _buildFileInputSection(
              'Driver License',
              '${ServerConfig.baseUrl}china/drivers-license',
            ),
          ],
        ),
      ),
    );
  }


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
}
