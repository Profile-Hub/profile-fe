import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../../server_config.dart';
import '../../routes.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

class IndiaDocumentForm extends StatefulWidget {
  final Function(bool)? onValidationChanged;
  const IndiaDocumentForm({Key? key, this.onValidationChanged}) : super(key: key);

  @override
  _IndiaDocumentFormState createState() => _IndiaDocumentFormState();
}

class _IndiaDocumentFormState extends State<IndiaDocumentForm> {
  final Map<String, PlatformFile?> selectedFiles = {
    'Aadhaar': null,
    'Passport': null,
    'Voter ID': null,
    'Driving License': null,
    'PAN': null,
    'Ration Card': null,
  };

  final Map<String, bool> isUploading = {
    'Aadhaar': false,
    'Passport': false,
    'Voter ID': false,
    'Driving License': false,
    'PAN': false,
    'Ration Card': false,
  };

  final Map<String, bool> isUploaded = {
    'Aadhaar': false,
    'Passport': false,
    'Voter ID': false,
    'Driving License': false,
    'PAN': false,
    'Ration Card': false,
  };

  final Map<String, bool> isRequired = {
    'Aadhaar': true,
    'Passport': false,
    'Voter ID': false,
    'Driving License': false,
    'PAN': false,
    'Ration Card': false,
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
          
          // Notify parent about validation change for required fields
          if (widget.onValidationChanged != null && isRequired[documentType] == true) {
            widget.onValidationChanged!(true);
          }
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

  Future<void> _uploadFile(String endpoint, String documentType) async {
    final selectedFile = selectedFiles[documentType];

    if (selectedFile == null) {
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
      final extension = selectedFile.extension;
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
            selectedFile.bytes!,
            filename: selectedFile.name,
            contentType: mediaType,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            selectedFile.path!,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            ...selectedFiles.keys.map((documentType) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          documentType,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        if (isRequired[documentType] == true)
                          const Text(
                            ' *',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
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
                            onTap: isUploaded[documentType]! ? null : () => _selectFile(documentType),
                            decoration: InputDecoration(
                              hintText: selectedFiles[documentType]?.name ?? 'No file selected',
                              hintStyle: TextStyle(
                                color: selectedFiles[documentType] != null ? Colors.black : Colors.grey,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              errorText: isRequired[documentType] == true && selectedFiles[documentType] == null
                                  ? 'This document is required'
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isUploaded[documentType]! ? null : () => _selectFile(documentType),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isUploaded[documentType]! ? Colors.grey : Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Choose File'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isUploading[documentType]! || isUploaded[documentType]!
                              ? null
                              : () => _uploadFile('${ServerConfig.baseUrl}india/upload', documentType),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isUploading[documentType]! || isUploaded[documentType]! ? Colors.grey : Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isUploading[documentType]!
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
                    const SizedBox(height: 16),
                  ],
                )),
          ],
        ),
      ),
    );
  }
}