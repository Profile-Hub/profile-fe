import 'package:flutter/material.dart';
import '../models/location_models.dart' as location_models;
import '../services/location_api_service.dart';
import '../services/signup_service.dart';
import '../services/email_service.dart';
import 'dart:async';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocationApiService _locationService = LocationApiService();
  final SignupService _signupService = SignupService();
  final EmailVerificationService _emailVerificationService = EmailVerificationService();

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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isEmailVerified = false;
  bool _isOtpSent = false;
  String? _otpError;
  int _resendTimer = 0;

  // Form field controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());

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

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty || 
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      final response = await _emailVerificationService.sendOtp(_emailController.text.trim());
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );

      if (response.success) {
        setState(() {
          _isOtpSent = true;
        });
      }
    } catch (e) {
      _showError('Failed to send OTP');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
     String otp = _otpControllers.map((controller) => controller.text).join();

  if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
    setState(() {
      _otpError = 'Please enter a valid 6-digit OTP';
    });
    return;
  }

    setState(() {
      _isLoading = true;
      _otpError = null;
    });

    try {
      final response = await _emailVerificationService.verifyOtp(
        _emailController.text.trim(),
        _otpControllers.map((controller) => controller.text).join()
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );

      if (response.success) {
        setState(() {
          _isEmailVerified = true;
        });
      }
    } catch (e) {
      _showError('Failed to verify OTP');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

Widget _buildEmailVerificationSection() {
  return Column(
    children: [
      // Email Input Field
     TextFormField(
  controller: _emailController,
  enabled: !_isEmailVerified,
  decoration: InputDecoration(
    labelText: 'Email',
    prefixIcon: Icon(Icons.email_outlined),
    suffixIcon: !_isEmailVerified && !_isOtpSent
        ? IconButton(
            icon: Icon(Icons.send),
            onPressed: _isLoading ? null : _sendOtp,
          )
        : Icon(
            _isEmailVerified ? Icons.check_circle : Icons.pending,
            color: _isEmailVerified ? Colors.green : Colors.orange,
          ),
  ),
  keyboardType: TextInputType.emailAddress,
  validator: (value) {
    if (_isEmailVerified) {
      // If email is verified, bypass validation
      return null;
    }
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  },
),
      // OTP Input Section
      if (_isOtpSent && !_isEmailVerified) ...[
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 6-Digit OTP Input Boxes
            for (int i = 0; i < 6; i++)
              SizedBox(
                width: 40,
                child: TextFormField(
                  controller: _otpControllers[i],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true, // Set white background
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && i < 5) {
                      FocusScope.of(context).nextFocus(); // Move to next box
                    } else if (value.isEmpty && i > 0) {
                      FocusScope.of(context).previousFocus(); // Move to previous box
                    }
                  },
                ),
              ),
          ],
        ),

        SizedBox(height: 16),
        // Submit OTP Button
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          child: Text('Verify OTP'),
        ),

        SizedBox(height: 16),
        // Resend OTP Feature
        if (_resendTimer > 0)
          Text('Resend OTP in $_resendTimer seconds'),
        if (_resendTimer == 0)
          TextButton(
            onPressed: _isLoading ? null : _resendOtp,
            child: Text('Resend OTP'),
          ),
      ],

      // Error Message
      if (_otpError != null)
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            _otpError!,
            style: TextStyle(color: Colors.red),
          ),
        ),
    ],
  );
}

void _startResendTimer() {
  _resendTimer = 60; // Set initial timer value
  Timer.periodic(Duration(seconds: 1), (timer) {
    if (_resendTimer > 0) {
      setState(() => _resendTimer--);
    } else {
      timer.cancel();
    }
  });
}

void _resendOtp() {
  _sendOtp(); // Reuse send OTP logic
  _startResendTimer(); // Restart timer after resend
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
                  _buildEmailVerificationSection(),
                  if (_isEmailVerified) ...[
                    SizedBox(height: 24),
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
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                          return 'Password must contain at least one uppercase letter';
                        }
                        if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
                          return 'Password must contain at least one lowercase letter';
                        }
                        if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
                          return 'Password must contain at least one number';
                        }
                        if (!RegExp(r'(?=.*[!@#$%^&*])').hasMatch(value)) {
                          return 'Password must contain at least one special character';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
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
                      items: ['donor', 'recipient']
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value.capitalize()),
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
                                  password: _passwordController.text,
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
                  ],
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