import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/allDoner.dart';
import '../server_config.dart';
import '../models/donerDetails.dart';
import '../models/Documentmodel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/selectedDonerModel.dart';
import '../models/doner_filter_model.dart';

class DonnerService {
  final String baseUrl = ServerConfig.baseUrl;
  String? _token;
  static final _storage = FlutterSecureStorage();

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }

  Future<List<Doner>> getAllDoner({DonorFilter? filter}) async {
    await _loadToken(); 
     
    try {
      final queryParams = filter?.toJson() ?? {};
      
      final uri = Uri.parse('$baseUrl/getallProvider').replace(
        queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())),
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
       
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Accessing the 'userdetail' list within the response body
        if (data['userdetail'] is List) {
          return data['userdetail'].map<Doner>((donor) => Doner.fromJson(donor)).toList();
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

  // Function to fetch donor details by ID 
 Future<DonerDetails> getDonorById(String id) async {
    await _loadToken();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/doner/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['UserDetails'] != null) {
          return DonerDetails.fromJson(data['UserDetails']);
          
        } else {
          throw Exception('UserDetails not found in response');
        }
      } else {
        throw Exception('Failed to load donor details. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
  Future<List<Document>> getDonorDocuments(String donorId, String country) async {
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
      default:
        return '';
    }
  }
   Future<List<SelectedDoner>> getAllSelectedDoner() async {
    await _loadToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-allSelected-doner'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Decoding the response into the SelectedDonerResponse model
        final selectedDonerResponse = SelectedDonerResponse.fromJson(data);
        
        if (selectedDonerResponse.success) {
          return selectedDonerResponse.data;
        } else {
          throw Exception('Failed to load selected donors');
        }
      } else {
        throw Exception('Failed to load selected donors. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

}
