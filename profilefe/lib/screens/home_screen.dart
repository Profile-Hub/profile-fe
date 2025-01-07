import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_completion_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'edit_profile_screen.dart';
import 'document_upload_screen.dart';
import 'doner_screen.dart';
import 'adminVerify_screen.dart';
import 'allReciptent_Screen.dart';
import 'allDonorAdmin_dart.dart';
import './widgets/profile_avatar.dart';
import '../providers/user_provider.dart';
import '../routes.dart';
import 'package:provider/provider.dart';


class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  final ProfileCompletionService _profileCompletionService = ProfileCompletionService();
  late User currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _checkProfileCompletion();
  }

  Future<void> _checkProfileCompletion() async {
    try {
      final response = await _profileCompletionService.checkProfileCompletion();
      
      if (response.success && response.notify && context.mounted) {
        _showProfileCompletionDialog(response.missingFields);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking profile completion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProfileCompletionDialog(List<String> missingFields) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Your Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please complete the following fields in your profile:'),
              const SizedBox(height: 16),
              ...missingFields.map((field) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      field,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToEditProfile();
              },
              child: const Text('Complete Profile'),
            ),
          ],
        );
      },
    );
  }

   Future<void> _navigateToEditProfile() async {
    final result = await Navigator.pushNamed(
      context,
      Routes.editProfile,
      arguments: currentUser,
    );
    if (result != null && result is User) {
      setState(() {
        currentUser = result;
      });
      Provider.of<UserProvider>(context, listen: false).setUser(result);
    }
  }

   Future<void> _handleLogout() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Logging out..."),
              ],
            ),
          );
        },
      );

      final success = await _authService.logout();

      if (context.mounted) {
        Navigator.pop(context);
      }

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('authToken');
        
        
        if (context.mounted) {
          Provider.of<UserProvider>(context, listen: false).clearUser();
          Navigator.pushNamedAndRemoveUntil(
            context,
            Routes.login,
            (route) => false,
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logout failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);
                _handleLogout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Home'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: ProfileAvatar(
                user: currentUser,
                radius: 30,
                showEditButton: false,
              ),
              accountName: Text('${currentUser.firstname} ${currentUser.lastname}'),
              accountEmail: Text(currentUser.email),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  Routes.profile,
                  arguments: currentUser,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(currentUser.usertype == 'Admin' ? 'User Requests' : 'Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                if (currentUser.usertype == 'Admin') {
                  Navigator.pushNamed(context, Routes.adminVerify);
                } else {
                  _navigateToEditProfile();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text(currentUser.usertype == 'Admin' ? 'All Donors' : 'Upload Documents'),
              onTap: () {
                Navigator.pop(context);
                if (currentUser.usertype == 'Admin') {
                  Navigator.pushNamed(context, Routes.allDonors);
                } else {
                  Navigator.pushNamed(
                    context,
                    Routes.documentUpload,
                    arguments: currentUser,
                  );
                }
              },
            ),
            if (currentUser.usertype == 'Admin')
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('All Recipients'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, Routes.allRecipients);
                },
              ),
            const Divider(),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: currentUser.usertype == 'donor'
          ? const Center(
              child: Text(
                'Welcome to Dashboard',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            )
          : currentUser.usertype == 'Admin'
              ? const Center(
                  child: Text(
                    'Welcome to Admin Dashboard',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                )
              : DonorListPage(),
    );
  }
}