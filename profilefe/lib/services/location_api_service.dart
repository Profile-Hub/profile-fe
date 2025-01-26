import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/location_models.dart';

class LocationApiService {
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _cities = [];

  LocationApiService() {
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadCountries();
    await _loadStates();
    await _loadCities();
  }

  Future<void> _loadCountries() async {
    try {
      String jsonString = await rootBundle.loadString('countries.json');
      List<dynamic> jsonList = json.decode(jsonString);
      _countries = jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      try {
        var response = await http.get(Uri.parse('/assets/countries.json'));
        List<dynamic> jsonList = json.decode(response.body);
        _countries = jsonList.cast<Map<String, dynamic>>();
      } catch (networkError) {
        print('Error loading countries: $networkError');
      }
    }
  }

  Future<void> _loadStates() async {
    try {
      String jsonString = await rootBundle.loadString('states.json');
      List<dynamic> jsonList = json.decode(jsonString);
      _states = jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      try {
        var response = await http.get(Uri.parse('/assets/states.json'));
        List<dynamic> jsonList = json.decode(response.body);
        _states = jsonList.cast<Map<String, dynamic>>();
      } catch (networkError) {
        print('Error loading states: $networkError');
      }
    }
  }

  Future<void> _loadCities() async {
    try {
      String jsonString = await rootBundle.loadString('cities.json');
      List<dynamic> jsonList = json.decode(jsonString);
      _cities = jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      try {
        var response = await http.get(Uri.parse('/assets/cities.json'));
        List<dynamic> jsonList = json.decode(response.body);
        _cities = jsonList.cast<Map<String, dynamic>>();
      } catch (networkError) {
        print('Error loading cities: $networkError');
      }
    }
  }

  // Rest of the code remains the same as in your original implementation
  Future<List<Country>> getCountries() async {
    if (_countries.isEmpty) await _loadCountries();

    return _countries.map((countryData) => Country(
      name: countryData['name'],
      phoneCode: countryData['phoneCode']
    )).toList();
  }

  Future<List<State>> getStatesByCountryId(String countryId) async {
    if (_states.isEmpty) await _loadStates();

    List<Map<String, dynamic>> filteredStates = _states
      .where((state) => state['countryId'] == countryId)
      .toList();

    return filteredStates.map((stateData) => State(
      name: stateData['name']
    )).toList();
  }

  Future<List<City>> getCitiesByStateId(String stateId) async {
    if (_cities.isEmpty) await _loadCities();

    List<Map<String, dynamic>> filteredCities = _cities
      .where((city) => city['stateId'] == stateId)
      .toList();

    return filteredCities.map((cityData) => City(
      name: cityData['name']
    )).toList();
  }

  // Legacy methods maintained for compatibility
  Future<List<State>> getStates(String countryName) async {
    if (_countries.isEmpty) await _loadCountries();

    var country = _countries.firstWhere(
      (c) => c['name'].toUpperCase() == countryName.toUpperCase(),
      orElse: () => throw Exception('Country not found')
    );
    return getStatesByCountryId(country['id']);
  }

  Future<List<City>> getCities(String stateName) async {
    if (_states.isEmpty) await _loadStates();

    var state = _states.firstWhere(
      (s) => s['name'].toUpperCase() == stateName.toUpperCase(),
      orElse: () => throw Exception('State not found')
    );
    return getCitiesByStateId(state['id']);
  }
}