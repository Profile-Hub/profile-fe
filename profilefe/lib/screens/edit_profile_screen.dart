
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/profile_service.dart';
import '../services/location_api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'email_change_screen.dart';
import '../models/location_models.dart' as location_models;
import 'change_password_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;
  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _locationService = LocationApiService();
  
  late TextEditingController firstNameController;
  // late TextEditingController middleNameController;
  late TextEditingController lastNameController;
  late TextEditingController genderController;
  late TextEditingController dobController;
  late TextEditingController phoneNumberController;
  String? selectedBloodGroup;
  
  List<location_models.Country> countries = [];
  List<location_models.State> states = [];
  List<location_models.City> cities = [];
  
  location_models.Country? selectedCountry;
  location_models.State? selectedState;
  location_models.City? selectedCity;
  String? selectedUserType;
  
  bool isLoading = false;
  bool isLoadingLocations = false;
  bool isInitializing = true;

  final List<String> userTypes = ['donor', 'recipient'];
  final List<String> genderTypes = ['Male', 'Female', 'Other'];
  final List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];


  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    setState(() => isInitializing = true);
    
    try {
      firstNameController = TextEditingController(text: widget.user.firstname);
      // middleNameController = TextEditingController(text: widget.user.middlename ?? '');
      lastNameController = TextEditingController(text: widget.user.lastname);
      genderController = TextEditingController(text: widget.user.gender ?? '');
      dobController = TextEditingController(
        text: widget.user.dateofbirth != null 
            ? DateFormat('dd/MM/yyyy').format(widget.user.dateofbirth!)
            : ''
      );
      phoneNumberController = TextEditingController(text: widget.user.phoneNumber ?? '');
      selectedUserType = widget.user.usertype;
      selectedBloodGroup = widget.user.bloodGroup;
      await _loadCountries();
    } catch (e) {
      _showError('Failed to initialize screen: $e');
    } finally {
      if (mounted) {
        setState(() => isInitializing = false);
      }
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    // middleNameController.dispose();
    lastNameController.dispose();
    genderController.dispose();
    dobController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() => isLoadingLocations = true);
    try {
      countries = await _locationService.getCountries();
      
      if (widget.user.country != null) {
        selectedCountry = countries.firstWhere(
          (country) => country.name.toLowerCase() == widget.user.country?.toLowerCase(),
          orElse: () => countries.first,
        );
        await _loadStates();
      }
    } catch (e) {
      _showError('Failed to load countries: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingLocations = false);
      }
    }
  }

  Future<void> _loadStates() async {
    if (selectedCountry == null) return;
    
    setState(() => isLoadingLocations = true);
    try {
      states = await _locationService.getStates(selectedCountry!.name);
      
      if (widget.user.state != null) {
        selectedState = states.firstWhere(
          (state) => state.name.toLowerCase() == widget.user.state?.toLowerCase(),
          orElse: () => states.first,
        );
        await _loadCities();
      }
    } catch (e) {
      _showError('Failed to load states: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingLocations = false);
      }
    }
  }

  Future<void> _loadCities() async {
    if (selectedState == null) return;
    
    setState(() => isLoadingLocations = true);
    try {
      cities = await _locationService.getCities(selectedState!.name);
      
      if (widget.user.city != null) {
        selectedCity = cities.firstWhere(
          (city) => city.name.toLowerCase() == widget.user.city?.toLowerCase(),
          orElse: () => cities.first,
        );
      }
    } catch (e) {
      _showError('Failed to load cities: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingLocations = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.user.dateofbirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        // Handle image upload
        await _profileService.updateProfileImage(image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully!')),
          );
        }
      }
    } catch (e) {
      _showError('Failed to update profile picture: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: isRequired ? label : '$label (Optional)',
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
        ),
        validator: isRequired ? (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        } : null,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) displayName,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: isLoading ? 
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ) : null,
        ),
        items: items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(displayName(item)),
        )).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select $label' : null,
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);
    
    try {
      final DateTime? dob = dobController.text.isNotEmpty 
          ? DateFormat('dd/MM/yyyy').parse(dobController.text)
          : null;

      final profileData = {
        'firstname': firstNameController.text,
        // 'middlename': middleNameController.text.isEmpty ? null : middleNameController.text,
        'lastname': lastNameController.text,
        'gender': genderController.text,
        'dateofbirth': dob?.toIso8601String(),
        'country': selectedCountry?.name,
        'state': selectedState?.name,
        'city': selectedCity?.name,
        'usertype': selectedUserType,
        'phoneCode': selectedCountry?.phoneCode,
        'phoneNumber': phoneNumberController.text,
        'bloodGroup': selectedBloodGroup,
      };

      await _profileService.updateProfile(profileData);
      final updatedUser = await _profileService.getProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Avatar section
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: widget.user.avatar?.url != null
                          ? NetworkImage(widget.user.avatar!.url)
                          : null,
                      child: widget.user.avatar?.url == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Form fields
                _buildTextField(
                  label: 'First Name',
                  controller: firstNameController,
                ),
                // _buildTextField(
                //   label: 'Middle Name',
                //   controller: middleNameController,
                //   isRequired: false,
                // ),
                _buildTextField(
                  label: 'Last Name',
                  controller: lastNameController,
                ),
                _buildDropdown<String>(
                  label: 'Gender',
                  value: genderController.text.isEmpty ? null : genderController.text,
                  items: genderTypes,
                  onChanged: (value) => setState(() => genderController.text = value ?? ''),
                  displayName: (gender) => gender,
                ),
                _buildTextField(
                  label: 'Date of Birth',
                  controller: dobController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  suffixIcon: Icons.calendar_today,
                ),
                _buildDropdown<String>(
                  label: 'User Type',
                  value: selectedUserType,
                  items: userTypes,
                  onChanged: (value) => setState(() => selectedUserType = value),
                  displayName: (type) => type[0].toUpperCase() + type.substring(1),
                ),
                _buildDropdown<String>(
                  label: 'Blood Group',
                  value: selectedBloodGroup,
                  items: bloodGroups,
                  onChanged: (group) => setState(() => selectedBloodGroup = group),
                  displayName: (group) => group,
                ),
                
                // Location dropdowns
                _buildDropdown<location_models.Country>(
                  label: 'Country',
                  value: selectedCountry,
                  items: countries,
                  onChanged: (country) async {
                    setState(() {
                      selectedCountry = country;
                      selectedState = null;
                      selectedCity = null;
                      states = [];
                      cities = [];
                    });
                    if (country != null) {
                      await _loadStates();
                    }
                  },
                  displayName: (country) => country.name,
                  isLoading: isLoadingLocations,
                ),
                if (selectedCountry != null) _buildDropdown<location_models.State>(
                  label: 'State',
                  value: selectedState,
                  items: states,
                  onChanged: (state) async {
                    setState(() {
                      selectedState = state;
                      selectedCity = null;
                      cities = [];
                    });
                    if (state != null) {
                      await _loadCities();
                    }
                  },
                  displayName: (state) => state.name,
                  isLoading: isLoadingLocations,
                ),
                if (selectedState != null) _buildDropdown<location_models.City>(
                  label: 'City',
                  value: selectedCity,
                  items: cities,
                  onChanged: (city) => setState(() => selectedCity = city),
                  displayName: (city) => city.name,
                  isLoading: isLoadingLocations,
                ),
                if (selectedCountry != null) ...[
                    Row(
                      children: [
                        // Phone Code Display
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+${selectedCountry!.phoneCode}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Phone Number Field
                        Expanded(
                          child: _buildTextField(
                            label: 'Phone Number',
                            controller: phoneNumberController,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                
                // Action buttons
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _updateProfile,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Update Profile'),
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                         Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangeEmailScreen(
                               user: widget.user, 
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                           foregroundColor: Colors.white,
                        ),
                        child: const Text('Change Email'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Implement change password navigation
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Change Password'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                         Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangePasswordScreen( 
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                           foregroundColor: Colors.white,
                        ),
                        child: const Text('Change Phone Number'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}