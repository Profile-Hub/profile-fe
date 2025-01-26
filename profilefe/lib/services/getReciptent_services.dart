import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/AllReciptentmodel.dart';
import '../server_config.dart';
import '../models/donerDetails.dart';
import '../models/Documentmodel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/Recipitent_filter_modal.dart';
import '../models/AllRecipitentDetails.dart';

class RecipitentService {
  final String baseUrl = ServerConfig.baseUrl;
  String? _token;
  static final _storage = FlutterSecureStorage();

  Future<void> _loadToken() async {
    _token = await _storage.read(key: 'auth_token');
  }
   Future<List<Recipient>> getAllReciptent({RecipientFilter? filter}) async {
    await _loadToken(); 
     
    try {
      final queryParams = filter?.toJson() ?? {};
      
      final uri = Uri.parse('$baseUrl/getallRecipitent').replace(
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

        if (data['userdetail'] is List) {
          return data['userdetail'].map<Recipient>((donor) => Recipient.fromJson(donor)).toList();
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

Future<RecipitentDetails> getRecipitentById(String id) async {
  await _loadToken();

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/recipitent/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data);
      if (data != null && data['transformedUserDetails'] != null) {
        return RecipitentDetails.fromJson(data['transformedUserDetails']);
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
  }
  