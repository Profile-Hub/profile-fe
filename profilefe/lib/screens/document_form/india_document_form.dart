import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class IndiaDocumentForm extends StatefulWidget {
  final Function(bool)? onValidationChanged;
  const IndiaDocumentForm({Key? key, this.onValidationChanged}) : super(key: key);

  @override
  _IndiaDocumentFormState createState() => _IndiaDocumentFormState();
}

class _IndiaDocumentFormState extends State<IndiaDocumentForm> {
   Map<String, PlatformFile?> selectedFiles = {
  'Aadhaar': null,
  'Passport': null,
  'Driver License': null,
  'Voter ID': null,
  'PAN': null,
  'Ration Card': null,
};
Map<String, bool> isValid = {
  'Aadhaar': true,
    'Passport': true,
    'Driver License': true,
    'Voter ID': true,
    'PAN': true,
    'Ration Card': true,
};
   Map<String, bool> isUploading = {
    'Aadhaar': false,
    'Passport': false,
    'Driver License': false,
    'Voter ID': false,
    'PAN': false,
    'Ration Card': false,
  };

   Map<String, bool> isUploaded = {
    'Aadhaar': false,
    'Passport': false,
    'Driver License': false,
    'Voter ID': false,
    'PAN': false,
    'Ration Card': false,
  };

  final Map<String, bool> isRequired = {
    'Aadhaar': true,
    'Passport': false,
    'Driver License': false,
    'Voter ID': false,
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
    _loadToken(); // Load token when the widget is initialized
  }

  // Method to select a file for a given document type with file type filter
  Future<void> _selectFile(String documentType) async {
     final localizations = AppLocalizations.of(context)!;
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
            isValid[documentType] = true; // Mark as valid when a file is selected
            _validateForm(); // Re-validate the form
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('${localizations.fileSize} 5MB')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.errorFile}: $e')),
      );
    }
  }

  // Method to upload a file to the server
  Future<void> _uploadFile(String documentType, String endpoint) async {
    final localizations = AppLocalizations.of(context)!;
    final fileData = selectedFiles[documentType];
    if (fileData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.pleaseSelect} $documentType before uploading.')),
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
      } else if (extension == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (extension == 'pdf') {
        mediaType = MediaType('application', 'pdf');
      } else {
        throw UnsupportedError('${localizations.unsupportedFile}');
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
          SnackBar(content: Text('$documentType ${localizations.uploadedsuccessfully}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.uploadfail}$documentType')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.errorFile} $documentType: $e')),
      );
    } finally {
      setState(() {
        isUploading[documentType] = false;
      });
    }
  }

  // Form validation
  void _validateForm() {
    final isFormValid = isValid['Aadhaar'] == true;
    widget.onValidationChanged?.call(isFormValid);
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
              'Aadhaar',
              '${ServerConfig.baseUrl}india/Aadhaar-card',
            ),
            _buildFileInputSection(
              'Passport',
              '${ServerConfig.baseUrl}india/passport',
            ),
            _buildFileInputSection(
              'Driver License',
              '${ServerConfig.baseUrl}india/drivers-license',
            ),
            _buildFileInputSection(
              'Voter ID',
              '${ServerConfig.baseUrl}india/voter-Id',
            ),
             _buildFileInputSection(
              'PAN',
              '${ServerConfig.baseUrl}/india/PANCard',
            ),
             _buildFileInputSection(
              'Ration Card',
              '${ServerConfig.baseUrl}india/rationCard',
            ),
          ],
        ),
      ),
    );
  }

  // Method to build UI for each file input section
  Widget _buildFileInputSection(String docType, String endpoint, {bool isRequired = false}) {
    final localizations = AppLocalizations.of(context)!;

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
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
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
                        : isRequired
                            ? localizations.requiredfile
                            : localizations.noFileSelected,
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
                child:Text(localizations.chooseFile),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isUploading[docType]! || isUploaded[docType]!
                    ? null
                    : () => _uploadFile(docType, endpoint),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUploading[docType]! || isUploaded[docType]!
                      ? Colors.grey
                      : Colors.green,
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
                    :  Text(localizations.upload),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
