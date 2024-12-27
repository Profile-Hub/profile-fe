import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:intl/intl.dart'; 

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
  bool isEditing = false;

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
    super.dispose();
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
void _saveProfile() {
  // Implement your save logic here
  setState(() {
    isEditing = false;
  });
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Profile saved successfully!')),
  );
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

  // ... rest of the code remains the same until the build method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  if (isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onPressed: () {
                            // Implement image picker logic
                          },
                        ),
                      ),
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
                      _buildProfileField('City', widget.user.city, controller: cityController),
                      _buildProfileField('State', widget.user.state, controller: stateController),
                      _buildProfileField('Country', widget.user.country, controller: countryController),
                      _buildProfileField('User Type', widget.user.usertype, controller: userTypeController),
                      if (isEditing) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                isEditing = false;
                              });
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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