
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/profile_service.dart';
import '../services/location_api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'email_change_screen.dart';
import '../models/location_models.dart' as location_models;
import 'change_password_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../routes.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;
  EditProfileScreen({Key? key, required this.user}) : super(key: key);

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
  final Map<String, List<String>> organCategories = {
    'Organs': [
      'Heart', 'Lungs', 'Liver', 'Kidneys', 'Pancreas', 'Intestines'
    ],
    'Tissues': [
      'Corneas', 'Skin', 'Heart Valves', 'Blood Vessels and Veins',
      'Tendons and Ligaments', 'Bone'
    ],
    'Reproductive Organs': [
      'Uterus', 'Ovaries', 'Eggs (Oocytes)', 'Fallopian Tubes',
      'Testicles', 'Sperm'
    ],
    'Other Donations': [
      'Bone Marrow and Stem Cells', 'Blood and Plasma', 'Umbilical Cord Blood'
    ],
    'Living Donations': [
      'Liver Segment', 'Kidney', 'Lung Lobe', 'Skin (partial)',
      'Bone Marrow and Stem Cells (regenerative)'
    ],
  };
    File? _imageFile;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();
  bool isImageUploading = false;
  bool isLoadingNetworkImage = false;
   Uint8List? _cachedNetworkImage; 
  
  Set<String> selectedOrgans = {};


  @override
  void initState() {
    super.initState();
    selectedOrgans = Set.from(widget.user.organDonations);
    _initializeScreen();
      if (widget.user.avatar?.url != null) {
      _preloadNetworkImage();
    }
  }
    void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _preloadNetworkImage() async {
    if (!mounted) return;
    
    setState(() => isLoadingNetworkImage = true);
    
    try {
      final response = await http.get(
        
        Uri.parse(widget.user.avatar!.url),
        
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET',
        },
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _cachedNetworkImage = response.bodyBytes;
            isLoadingNetworkImage = false;
          });
        }
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cachedNetworkImage = null;
          isLoadingNetworkImage = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load profile image. Please try again later.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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

 Future<void> _handleImageUpload() async {
    if (!mounted) return;
    
    try {
      setState(() => isImageUploading = true);
      
      final imageData = _webImage ?? await _imageFile?.readAsBytes();
      if (imageData == null) return;

      final updatedUser = await _profileService.uploadProfileImage(
        imageFile: imageData,
        fileName: 'profile_image.jpg',
        mimeType: 'image/jpeg',
      );

      if (mounted) {
        setState(() {
          widget.user.avatar = updatedUser.avatar;
          // Preload the new image
          if (updatedUser.avatar?.url != null) {
            _preloadNetworkImage();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isImageUploading = false);
      }
    }
  }


Future<void> _selectImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = null;
          });
        } else {
          setState(() {
            _imageFile = File(image.path);
            _webImage = null;
          });
        }
        await _handleImageUpload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e')),
        );
      }
    }
  }

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = null;
          });
        } else {
          setState(() {
            _imageFile = File(image.path);
            _webImage = null;
          });
        }
        await _handleImageUpload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    }
  }
 void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  GoRouter.of(context).pop();
                  _selectImage();
                },
              ),
              if (!kIsWeb) // Show camera option only for mobile platforms
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    GoRouter.of(context).pop();
                    _captureImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[300],
          child: isImageUploading
              ? const CircularProgressIndicator()
              : _getProfileImage(),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: isImageUploading ? null : _showImageSourceDialog,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isImageUploading 
                    ? Colors.grey 
                    : Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.camera_alt,
                color: isImageUploading ? Colors.white.withOpacity(0.5) : Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
   Widget _getProfileImage() {
    if (isImageUploading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
        ),
      );
    }
    
    if (_webImage != null) {
      return _buildCircularImage(
        child: Image.memory(
          _webImage!,
          fit: BoxFit.cover,
        ),
      );
    } 
    
    if (_imageFile != null) {
      return _buildCircularImage(
        child: Image.file(
          _imageFile!,
          fit: BoxFit.cover,
        ),
      );
    }
    
    if (_cachedNetworkImage != null) {
      return _buildCircularImage(
        child: Image.memory(
          _cachedNetworkImage!,
          fit: BoxFit.cover,
        ),
      );
    }
    
    if (isLoadingNetworkImage) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
        ),
      );
    }
    
    return const Icon(
      Icons.person,
      size: 60,
      color: Colors.white,
    );
  }

  Widget _buildCircularImage({required Widget child}) {
    return ClipOval(
      child: SizedBox(
        width: 120,
        height: 120,
        child: child,
      ),
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
    Widget _buildOrganDonationSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        title: const Text('Organ Donation Preferences'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: organCategories.entries.map((category) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        category.key,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: category.value.map((organ) {
                        return FilterChip(
                          label: Text(organ),
                          selected: selectedOrgans.contains(organ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedOrgans.add(organ);
                              } else {
                                selectedOrgans.remove(organ);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
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
     bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: isRequired ? label : '$label (Optional)',
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
        validator: isRequired 
            ? (value) => value == null ? 'Please select $label' : null
            : null,  // No validation for optional fields
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
        if (selectedUserType?.toLowerCase() == 'donor') 'organDonations': selectedOrgans.toList(),
      };

      await _profileService.updateProfile(profileData);
      final updatedUser = await _profileService.getProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
       GoRouter.of(context).pop(updatedUser);
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
        leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
       GoRouter.of(context).go(Routes.home);
    },
  ),
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
                
                 const SizedBox(height: 20),
            Center(child: _buildProfileImage()),
            const SizedBox(height: 30),
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
                  isRequired: false,
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
                    if (selectedUserType?.toLowerCase() == 'donor') 
                  _buildOrganDonationSection(),
                
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
                       GoRouter.of(context).push(
                       Routes.changeEmail, 
                       extra: widget.user,   
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
                         GoRouter.of(context).push(
                        Routes.changePassword,  
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