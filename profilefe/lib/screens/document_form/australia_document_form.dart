import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../../server_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AustraliaDocumentForm extends StatefulWidget {
  final Function(bool)? onValidationChanged;
  const AustraliaDocumentForm({Key? key, this.onValidationChanged}) : super(key: key);

  @override
  _AustraliaDocumentFormState createState() => _AustraliaDocumentFormState();
}

class _AustraliaDocumentFormState extends State<AustraliaDocumentForm> {
  final Map<String, PlatformFile?> selectedFiles = {
    'Medicare Card': null,
    'Passport': null,
    'Driver License': null,
    'Birth Certificate': null,
    'Permanent residency card': null,
  };

  final Map<String, bool> isValid = {
    'Medicare Card': false,
    'Passport': true,
    'Driver License': true,
    'Birth Certificate': true,
    'Permanent residency card': true,
  };

  final Map<String, bool> isUploading = {
    'Medicare Card': false,
    'Passport': false,
    'Driver License': false,
    'Birth Certificate': false,
    'Permanent residency card': false,
  };

  final Map<String, bool> isUploaded = {
    'Medicare Card': false,
    'Passport': false,
    'Driver License': false,
    'Birth Certificate': false,
    'Permanent residency card': false,
  };

  String? _token;
  static const _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
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
            isValid[documentType] = true;
            _validateForm();
          });
        } else {
          _showErrorSnackBar('File size must be less than 5MB');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting file: $e');
    }
  }

  Future<void> _uploadFile(String documentType, String endpoint) async {
    final fileData = selectedFiles[documentType];
    if (fileData == null) {
      _showErrorSnackBar('Please select a file for $documentType before uploading.');
      return;
    }

    setState(() => isUploading[documentType] = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(endpoint));
      request.headers['Authorization'] = 'Bearer $_token';
      request.headers['Content-Type'] = 'multipart/form-data';

      MediaType mediaType;
      final extension = fileData.extension?.toLowerCase() ?? '';
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mediaType = MediaType('image', 'jpeg');
          break;
        case 'png':
          mediaType = MediaType('image', 'png');
          break;
        case 'pdf':
          mediaType = MediaType('application', 'pdf');
          break;
        default:
          throw UnsupportedError('File type not supported. Only JPG, PNG, and PDF are allowed.');
      }

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          fileData.bytes!,
          filename: fileData.name,
          contentType: mediaType,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          fileData.path!,
          contentType: mediaType,
        ));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        setState(() => isUploaded[documentType] = true);
        _showSuccessSnackBar('$documentType uploaded successfully');
      } else {
        _showErrorSnackBar('Failed to upload $documentType');
      }
    } catch (e) {
      _showErrorSnackBar('Error uploading $documentType: $e');
    } finally {
      setState(() => isUploading[documentType] = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  void _validateForm() {
    bool hasAtLeastOneDocument = selectedFiles.values.any((file) => file != null);
    widget.onValidationChanged?.call(hasAtLeastOneDocument);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Required Documents',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(color: theme.colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please upload any one of the following documents (mandatory)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...selectedFiles.keys.map((docType) => _buildFileInputSection(
              docType,
              '${ServerConfig.baseUrl}aus/${docType.toLowerCase().replaceAll(' ', '-')}',
              theme,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInputSection(String docType, String endpoint, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            docType,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  readOnly: true,
                  onTap: isUploaded[docType]! ? null : () => _selectFile(docType),
                  decoration: InputDecoration(
                    hintText: selectedFiles[docType]?.name ?? 'No file selected',
                    hintStyle: TextStyle(
                      color: selectedFiles[docType] != null 
                          ? theme.textTheme.bodyMedium?.color 
                          : theme.hintColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: isUploaded[docType]! ? null : () => _selectFile(docType),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUploaded[docType]! 
                        ? theme.disabledColor 
                        : theme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Choose',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: isUploading[docType]! || isUploaded[docType]!
                      ? null
                      : () => _uploadFile(docType, endpoint),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUploading[docType]! || isUploaded[docType]!
                        ? theme.disabledColor
                        : Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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
                      : Text(
                          'Upload',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}