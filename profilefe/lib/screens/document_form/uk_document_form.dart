import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../../server_config.dart';
import '../../services/getdoner_service.dart';
import '../../models/Documentmodel.dart';
import '../../models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../routes.dart';

class UKDocumentForm extends StatefulWidget {
  final Function(bool)? onValidationChanged;
  final User user;
  const UKDocumentForm({Key? key, this.onValidationChanged,required this.user}) : super(key: key);

  @override
  _UKDocumentFormState createState() => _UKDocumentFormState();
}

class _UKDocumentFormState extends State<UKDocumentForm> {
  final Map<String, PlatformFile?> selectedFiles = {
    'National Insurance Number': null,
    'Passport': null,
    'Driver License': null,
    'Birth Certificate': null,
    'Biometric Residence Permit': null,
  };

  final Map<String, bool> isUploading = {
    'National Insurance Number': false,
    'Passport': false,
    'Driver License': false,
    'Birth Certificate': false,
    'Biometric Residence Permit': false,
  };

  final Map<String, bool> isUploaded = {
    'National Insurance Number': false,
    'Passport': false,
    'Driver License': false,
    'Birth Certificate': false,
    'Biometric Residence Permit': false,
  };

  final Map<String, bool> isRequired = {
    'National Insurance Number': true,
    'Passport': true,
    'Driver License': false,
    'Birth Certificate': false,
    'Biometric Residence Permit': false,
  };
final Map<String, String> documentKeyMap= {
    'National Insurance Number': "nationalInsuranceNumber",
    'Passport': "passport",
    'Driver License': "driversLicense",
    'Birth Certificate': "birthCertificate",
    'Biometric Residence Permit': "biometricResidencePermit",
  };
  String? _token;
  static const _storage = FlutterSecureStorage();
List<Document> documents = [];
  bool isLoadingDocuments = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
     _loadDocuments();
  }

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }
  Future<void> _loadDocuments() async {
    try {
      final docs = await fetchReciptentDocuments(widget.user.id, widget.user.country!);
      setState(() {
        documents = docs;
        isLoadingDocuments = false;
      });
    } catch (e) {
      print('Error loading documents: $e');
      setState(() => isLoadingDocuments = false);
    }
  } 
   Future<List<Document>> fetchReciptentDocuments(String recipientId, String country) async {
    final documentService = DonnerService();
    return await documentService.getDonorDocuments(recipientId, country);
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
            widget.onValidationChanged?.call(true);
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
         _loadDocuments();
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
                            'National Insurance Number and Passport are mandatory. Other documents are optional.',
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
                    '${ServerConfig.baseUrl}uk/${docType.toLowerCase().replaceAll(' ', '-')}',
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
    final dbKey = documentKeyMap[docType] ?? docType.toLowerCase().replaceAll(' ', '');
    String getFileNameFromUrl(String url) {
      return url.split('/').last;
    }
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
          if (isLoadingDocuments)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Center(child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )),
            )
          else ...[
            for (var doc in documents)
              if (doc.files?.containsKey(dbKey) ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            getFileNameFromUrl(doc.files![dbKey]!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}