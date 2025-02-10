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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class IndiaDocumentForm extends StatefulWidget {
  final Function(bool)? onValidationChanged;
  final User user;
  const IndiaDocumentForm({Key? key, this.onValidationChanged,required this.user}) : super(key: key);

  @override
  _IndiaDocumentFormState createState() => _IndiaDocumentFormState();
}

class _IndiaDocumentFormState extends State<IndiaDocumentForm> {
  final Map<String, PlatformFile?> selectedFiles = {
    'Aadhaar Card': null,
    'Passport': null,
    'Driver License': null,
    'Voter ID': null,
    'PAN Card': null,
    'Ration Card': null,
  };

  final Map<String, bool> isValid = {
    'Aadhaar Card': true,
    'Passport': true,
    'Driver License': true,
    'Voter ID': true,
    'PAN Card': true,
    'Ration Card': true,
  };

  final Map<String, bool> isUploading = {
    'Aadhaar Card': false,
    'Passport': false,
    'Driver License': false,
    'Voter ID': false,
    'PAN Card': false,
    'Ration Card': false,
  };

  final Map<String, bool> isUploaded = {
    'Aadhaar Card': false,
    'Passport': false,
    'Driver License': false,
    'Voter ID': false,
    'PAN Card': false,
    'Ration Card': false,
  };
final Map<String, String> documentKeyMap = {
  'Aadhaar Card': "AadhaarCard",
    'Passport': "passport",
    'Driver License': "driversLicense",
    'Voter ID': "voterId",
    'PAN Card': "PANCard",
    'Ration Card': "rationCard",
};
  final Map<String, bool> isRequired = {
    'Aadhaar Card': true,
    'Passport': false,
    'Driver License': false,
    'Voter ID': false,
    'PAN Card': false,
    'Ration Card': false,
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
    final localizations = AppLocalizations.of(context)!;
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
          _showErrorSnackBar('${localizations.fileSize} 5MB');
        }
      }
    } catch (e) {
      _showErrorSnackBar('${localizations.errorFile}: $e');
    }
  }

  Future<void> _uploadFile(String documentType, String endpoint) async {
    final localizations = AppLocalizations.of(context)!;
    final fileData = selectedFiles[documentType];
    if (fileData == null) {
      _showErrorSnackBar('${localizations.pleaseSelect} $documentType');
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
          throw UnsupportedError(localizations.unsupportedFile);
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
        _showSuccessSnackBar('$documentType ${localizations.uploadedsuccessfully}');
      } else {
        _showErrorSnackBar('${localizations.uploadfail} $documentType');
      }
    } catch (e) {
      _showErrorSnackBar('${localizations.errorFile} $documentType: $e');
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
    final localizations = AppLocalizations.of(context)!;
    
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
                    localizations.requiredDocuments,
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
                            localizations.mendatory_document,
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
                    '${ServerConfig.baseUrl}india/${docType.toLowerCase().replaceAll(' ', '-')}',
                    theme,
                    constraints.maxWidth,
                    localizations,
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
   Widget _buildFileInputSection(String docType, String endpoint, ThemeData theme,double maxWidth,AppLocalizations localizations,) {
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
                    hintText: selectedFiles[docType]?.name ?? localizations.noFileSelected,
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
                    localizations.chooseFile,
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
                          localizations.upload,
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