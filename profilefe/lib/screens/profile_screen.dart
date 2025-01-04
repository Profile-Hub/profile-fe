import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:intl/intl.dart';
import 'widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController countryController;
  late TextEditingController genderController;
  late TextEditingController userTypeController;
  late TextEditingController dobController;
  late TextEditingController bloodGroupController;
  late TextEditingController phoneNumberController;
  bool isEditing = false;

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

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.user.firstname);
    lastNameController = TextEditingController(text: widget.user.lastname);
    emailController = TextEditingController(text: widget.user.email);
    cityController = TextEditingController(text: widget.user.city ?? '');
    stateController = TextEditingController(text: widget.user.state ?? '');
    countryController = TextEditingController(text: widget.user.country ?? '');
    genderController = TextEditingController(text: widget.user.gender ?? '');
    userTypeController = TextEditingController(text: widget.user.usertype ?? '');
    bloodGroupController = TextEditingController(text: widget.user.bloodGroup ?? '');
    phoneNumberController = TextEditingController(text: widget.user.phoneNumber ?? '');
    dobController = TextEditingController(
      text: widget.user.dateofbirth != null 
          ? DateFormat('dd/MM/yyyy').format(widget.user.dateofbirth!)
          : ''
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    genderController.dispose();
    userTypeController.dispose();
    dobController.dispose();
    bloodGroupController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
    Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.user.dateofbirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }


  Widget _buildProfileField(String label, String? value, {TextEditingController? controller, bool isDateField = false}) {
    final displayValue = value ?? 'Not specified';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: isEditing && controller != null
          ? isDateField
              ? GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: label,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                )
              : TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Divider(),
              ],
            ),
    );
  }

  Widget _buildOrganDonationsSection() {
    if (widget.user.organDonations.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Organ Donations'),
          const Text('No organ donations specified'),
          const Divider(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Organ Donations'),
        ...organCategories.entries.map((category) {
          final organsInCategory = widget.user.organDonations
              .where((organ) => category.value.contains(organ))
              .toList();

          if (organsInCategory.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  category.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: organsInCategory.map((organ) => Chip(
                  label: Text(organ),
                  backgroundColor: Colors.blue.shade100,
                )).toList(),
              ),
              const SizedBox(height: 8),
            ],
          );
        }).where((widget) => widget != const SizedBox.shrink()).toList(),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                   ProfileAvatar(
                  user: widget.user,
                  radius: 50,
                  showEditButton: false,
                ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Personal Information'),
                      _buildProfileField('First Name', widget.user.firstname, controller: firstNameController),
                      _buildProfileField('Last Name', widget.user.lastname, controller: lastNameController),
                      _buildProfileField('Email', widget.user.email, controller: emailController),
                      _buildProfileField(
                        'Date of Birth', 
                        widget.user.dateofbirth != null 
                            ? DateFormat('dd/MM/yyyy').format(widget.user.dateofbirth!)
                            : null,
                        controller: dobController,
                        isDateField: true
                      ),
                      _buildProfileField('Gender', widget.user.gender, controller: genderController),
                      _buildProfileField('Blood Group', widget.user.bloodGroup, controller: bloodGroupController),
                      
                      _buildSectionTitle('Contact Information'),
                      _buildProfileField(
                        'Phone Number', 
                        widget.user.phoneCode != null && widget.user.phoneNumber != null
                            ? '+${widget.user.phoneCode} ${widget.user.phoneNumber}'
                            : null, 
                        controller: phoneNumberController
                      ),
                      _buildProfileField('City', widget.user.city, controller: cityController),
                      _buildProfileField('State', widget.user.state, controller: stateController),
                      _buildProfileField('Country', widget.user.country, controller: countryController),
                      
                      _buildSectionTitle('Account Information'),
                      _buildProfileField('User Type', widget.user.usertype?.toUpperCase() ?? '', controller: userTypeController),
                      
                       if (widget.user.usertype?.toLowerCase() == 'donor') 
                        _buildOrganDonationsSection(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}