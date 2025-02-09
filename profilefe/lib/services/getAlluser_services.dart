import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/adminmodel.dart';
import '../server_config.dart';
import '../models/donerDetails.dart';
import '../models/Documentmodel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/allUserAdmin.dart';


class AlluserData {
  final String baseUrl = ServerConfig.baseUrl;
  String? _token;
  static final _storage = FlutterSecureStorage();

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }

  Future<List<Alluser>> getAllUser() async {
    await _loadToken(); 
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin-get-AllUser'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
       
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Accessing the 'userdetail' list within the response body
        if (data['userdetail'] is List) {
          return data['userdetail'].map<Alluser>((donor) => Alluser.fromJson(donor)).toList();
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }  
 Future<Alluser > getUserById(String id) async {
    await _loadToken();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin-get-AllUserby-id/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['userprofile'] != null) {
          return Alluser.fromJson(data['userprofile']);
          
        } else {
          throw Exception('userprofile not found in response');
        }
      } else {
        throw Exception('Failed to load donor details. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
  Future<List<Document>> getUserDocuments(String donorId, String country) async {
  await _loadToken();
  String endpoint = _getCountryEndpoint(country);
  if (endpoint.isEmpty) {
    throw Exception('Invalid country');
  }

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint/getAlldocument/$donorId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
       if (data != null && data['userDocuments'] != null) {
        return List<Document>.from(
          data['userDocuments'].map((doc) => Document.fromJson(doc))
        );
      } else {
        throw Exception('Documents not found in response');
      }
    } else {
      throw Exception('Failed to fetch documents. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to connect to server: $e');
  }
}

  String _getCountryEndpoint(String country) {
    switch (country) {
      case 'United States':
        return 'us';
      case 'United Kingdom':
        return 'uk';
      case 'Australia':
        return 'aus';
      case 'New Zealand':
        return 'nwz';
      case 'United Arab Emirates':
        return 'uae';
      case 'China':
        return 'china';
      case 'India':
        return 'india';
      default:
        return '';
    }
  }

}
