import 'package:flutter/material.dart';
import '../models/location_models.dart' as location_models;
import '../services/location_api_service.dart';
import '../services/signup_service.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

final SignupService _signupService = SignupService();

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocationApiService _locationService = LocationApiService();

  // Location data
  List<location_models.Country> _countries = [];
  List<location_models.State> _states = [];
  List<location_models.City> _cities = [];

  // Selected values
  location_models.Country? selectedCountry;
  location_models.State? selectedState;
  location_models.City? selectedCity;
  String? selectedUserType;
  String? selectedGender;
  DateTime? selectedDate;
  bool _isLoading = false;

  // Form field controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoading = true);
    try {
      final countries = await _locationService.getCountries();
      setState(() {
        _countries = countries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load countries');
    }
  }

  Future<void> _loadStates(String countryName) async {
    setState(() => _isLoading = true);
    try {
      final states = await _locationService.getStates(countryName);
      setState(() {
        _states = states;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load states');
    }
  }

  Future<void> _loadCities(String stateName) async {
    setState(() => _isLoading = true);
    try {
      final cities = await _locationService.getCities(stateName);
      setState(() {
        _cities = cities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load cities');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _middleNameController,
                    decoration: InputDecoration(
                      labelText: 'Middle Name (Optional)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        selectedDate != null
                            ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                            : 'Select Date',
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    value: selectedGender,
                    hint: Text('Select Gender'),
                    items: ['Male', 'Female', 'Other']
                        .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        })
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedGender = newValue;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<location_models.Country>(
                    decoration: InputDecoration(
                      labelText: 'Country',
                      prefixIcon: Icon(Icons.public),
                    ),
                    value: selectedCountry,
                    hint: Text('Select Country'),
                    items: _countries.map((location_models.Country country) {
                      return DropdownMenuItem<location_models.Country>(
                        value: country,
                        child: Text(country.name),
                      );
                    }).toList(),
                    onChanged: _isLoading
                        ? null
                        : (location_models.Country? value) {
                            setState(() {
                              selectedCountry = value;
                              selectedState = null;
                              selectedCity = null;
                              _states.clear();
                              _cities.clear();
                            });
                            if (value != null) {
                              _loadStates(value.name);
                            }
                          },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<location_models.State>(
                    decoration: InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(Icons.map),
                    ),
                    value: selectedState,
                    hint: Text(selectedCountry == null
                        ? 'Select a country first'
                        : 'Select State'),
                    items: _states.map((location_models.State state) {
                      return DropdownMenuItem<location_models.State>(
                        value: state,
                        child: Text(state.name),
                      );
                    }).toList(),
                    onChanged: _isLoading || selectedCountry == null
                        ? null
                        : (location_models.State? value) {
                            setState(() {
                              selectedState = value;
                              selectedCity = null;
                              _cities.clear();
                            });
                            if (value != null) {
                              _loadCities(value.name);
                            }
                          },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<location_models.City>(
                    decoration: InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    value: selectedCity,
                    hint: Text(selectedState == null
                        ? 'Select a state first'
                        : 'Select City'),
                    items: _cities.map((location_models.City city) {
                      return DropdownMenuItem<location_models.City>(
                        value: city,
                        child: Text(city.name),
                      );
                    }).toList(),
                    onChanged: _isLoading || selectedState == null
                        ? null
                        : (location_models.City? value) {
                            setState(() {
                              selectedCity = value;
                            });
                          },
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'User Type',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    value: selectedUserType,
                    hint: Text('Select User Type'),
                    items: ['Provider', 'Seeker']
                        .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        })
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedUserType = newValue;
                      });
                    },
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isLoading = true);
                              final success = await _signupService.signup(
                                firstName: _firstNameController.text.trim(),
                                middleName: _middleNameController.text.trim(),
                                lastName: _lastNameController.text.trim(),
                                email: _emailController.text.trim(),
                                dateOfBirth: selectedDate?.toIso8601String() ?? '',
                                gender: selectedGender ?? '',
                                userType: selectedUserType ?? '',
                                country: selectedCountry?.name ?? '',
                                state: selectedState?.name ?? '',
                                city: selectedCity?.name ?? '',
                              );
                              setState(() => _isLoading = false);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Signup successful!')),
                                );
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Signup failed. Please try again.')),
                                );
                              }
                            }
                          },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Sign Up',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_isLoading)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
