import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../../server_config.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../routes.dart';

class UAEDocumentForm extends StatefulWidget {
  final Function(bool)? onValidationChanged;
  const UAEDocumentForm({Key? key, this.onValidationChanged}) : super(key: key);

  @override
  _UAEDocumentFormState createState() => _UAEDocumentFormState();
}

class _UAEDocumentFormState extends State<UAEDocumentForm> {
  final Map<String, PlatformFile?> selectedFiles = {
    'Emirates Id': null,
    'Passport': null,
    'Residence Visa': null,
    'Labor Card': null,
  };

  final Map<String, bool> isValid = {
    'Emirates Id': true,
    'Passport': true,
    'Residence Visa': true,
    'Labor Card': true,
  };

  final Map<String, bool> isUploading = {
    'Emirates Id': false,
    'Passport': false,
    'Residence Visa': false,
    'Labor Card': false,
  };

  final Map<String, bool> isUploaded = {
    'Emirates Id': false,
    'Passport': false,
    'Residence Visa': false,
    'Labor Card': false,
  };

  final Map<String, bool> isRequired = {
    'Emirates Id': true,
    'Passport': true,
    'Residence Visa': false,
    'Labor Card': false,
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
    widget.onValidationChanged?.call(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
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
                            'Emirates ID and Passport are mandatory. Other documents are optional.',
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
                    '${ServerConfig.baseUrl}uae/${docType.toLowerCase().replaceAll(' ', '-')}',
                    theme,
                    constraints.maxWidth,
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileInputSection(String docType, String endpoint, ThemeData theme, double maxWidth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                docType,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isRequired[docType] == true) ...[
                const SizedBox(width: 8),
                Text(
                  '*',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.5),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
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
                        'Choose File',
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
              );
            },
          ),
        ],
      ),
    );
  }
}