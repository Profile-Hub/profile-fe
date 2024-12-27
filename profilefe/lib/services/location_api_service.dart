import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_models.dart';

class LocationApiService {
  static const String baseUrl = 'https://www.universal-tutorial.com/api';
  static const String email = 'rishumehta7370@gmail.com'; 
  static const String apiKey = 'avgKXjKnsBh-P8j6RSpFR-eplSHfkQdLnWmUeUtrBx93TKqfTmxnZvqdvEOp4SaU3L0';

  String? _authToken;

  // Fetch auth token dynamically
  Future<String> _fetchAuthToken() async {
    final response = await http.get(
      Uri.parse('$baseUrl/getaccesstoken'),
      headers: {
        'Accept': 'application/json',
        'api-token': apiKey,
        'user-email': email,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _authToken = data['auth_token'];
      return _authToken!;
    } else {
      throw Exception('Failed to fetch auth token');
    }
  }

  // Ensure token is available
  Future<String> _getAuthToken() async {
    if (_authToken == null) {
      _authToken = await _fetchAuthToken();
    }
    return _authToken!;
  }

  // General API call method
  Future<List<T>> _getData<T>(String endpoint, T Function(Map<String, dynamic>) fromJson) async {
    final authToken = await _getAuthToken();

    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => fromJson(json)).toList();
    } else {
      throw Exception('Failed to load data from $endpoint');
    }
  }

  // Fetch countries
  Future<List<Country>> getCountries() async {
    return _getData('countries/', (json) => Country.fromJson(json));
  }

  // Fetch states by country
  Future<List<State>> getStates(String countryName) async {
    return _getData('states/$countryName', (json) => State.fromJson(json));
  }

  // Fetch cities by state
  Future<List<City>> getCities(String stateName) async {
    return _getData('cities/$stateName', (json) => City.fromJson(json));
  }
}
