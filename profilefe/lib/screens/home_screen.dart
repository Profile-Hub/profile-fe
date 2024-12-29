import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'edit_profile_screen.dart';
import 'document_upload_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  late User currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  Future<void> _navigateToEditProfile() async {
    final updatedUser = await Navigator.push<User>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: currentUser),
      ),
    );

    if (updatedUser != null) {
      setState(() {
        currentUser = updatedUser;
      });
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
                Text("Logging out...")
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
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
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
              accountName: Text('${currentUser.firstname} ${currentUser.lastname}'),
              accountEmail: Text(currentUser.email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.grey[200],
                backgroundImage: currentUser.avatar?.url != null
                    ? NetworkImage(currentUser.avatar!.url)
                    : null,
                child: currentUser.avatar?.url == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              decoration: const BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(user: currentUser),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload Documents'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentUploadScreen(user: currentUser),
                  ),
                );
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
      body: const Center(
        child: Text(
          'Welcome to Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}