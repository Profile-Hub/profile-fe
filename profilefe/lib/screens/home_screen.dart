import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_completion_service.dart';
import 'doner_screen.dart';
import './widgets/profile_avatar.dart';
import '../providers/user_provider.dart';
import '../routes.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/geolocatorservice.dart';
import './Reciptent_screen.dart';
class HomeScreen extends StatefulWidget {
  final User user;

   HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  final ProfileCompletionService _profileCompletionService = ProfileCompletionService();
  final GeolocatorService _geolocatorService = GeolocatorService();
  late User currentUser;
  final unreadMessagesCount = 0;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _checkProfileCompletion();
    _updateUserLocation();
  }
 Future<void> _updateUserLocation() async {
    try {
      final success = await _geolocatorService.postLocation();
      if (success) {
        debugPrint("Location updated successfully.");
      } else {
        debugPrint("Failed to update location.");
      }
    } catch (e) {
      debugPrint("Error updating location: $e");
    }
  }

Future<void> _checkProfileCompletion() async {
    try {
        final response = await _profileCompletionService.checkProfileCompletion();

        if (currentUser.usertype != 'Admin') {
            if (response.success && response.notify && context.mounted) {
                _showProfileCompletionDialog(response.missingFields, response.missingDocuments);
            }
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

void _showProfileCompletionDialog(List<String> missingFields, List<String> missingDocuments) {
   

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
                        if (missingFields.isNotEmpty || missingDocuments.isNotEmpty)
                            const Text('To become a verified user, please:'),
                        if (missingFields.isNotEmpty)
                            const Text('Complete the following profile fields:'),
                        ...missingFields.map((field) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Row(
                                children: [
                                    const Icon(Icons.arrow_right, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                        (field),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                ],
                            ),
                        )),
                        if (missingDocuments.isNotEmpty)
                            const Text('Upload the following required documents:'),
                        ...missingDocuments.map((doc) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Row(
                               children: [
  const Icon(Icons.arrow_right, size: 20),
  const SizedBox(width: 8),
  Expanded(
    child: Text(
      doc,
      style: const TextStyle(fontWeight: FontWeight.bold),
      overflow: TextOverflow.ellipsis, 
      maxLines: 1, 
    ),
  ),
],

                            ),
                        )),
                    ],
                ),
                actions: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            TextButton(
                                onPressed: () => GoRouter.of(context).pop(),
                                child: const Text('Cancel'),
                            ),
                            if (missingDocuments.isNotEmpty)
                                TextButton(
                                    onPressed: () {
                                        GoRouter.of(context).pop();
                                        GoRouter.of(context).go(Routes.documentUpload, extra: currentUser);
                                    },
                                    child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            Icon(Icons.upload_file),
                                            SizedBox(width: 8),
                                            Text('Upload Documents'),
                                        ],
                                    ),
                                ),
                            if (missingFields.isNotEmpty)
                                TextButton(
                                    onPressed: () {
                                        GoRouter.of(context).pop();
                                        GoRouter.of(context).go(Routes.editProfile, extra: currentUser);
                                    },
                                    child: const Text('Complete Profile'),
                                ),
                        ],
                    ),
                ],
            );
        },
    );
}

  Future<void> _navigateToEditProfile() async {
  final result = await GoRouter.of(context).push<User>(
    Routes.editProfile,
    extra: currentUser,
  );

  if (result != null) {
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
         GoRouter.of(context).pop();
      }

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('authToken');
        
        
        if (context.mounted) {
          Provider.of<UserProvider>(context, listen: false).clearUser();
          GoRouter.of(context).go(Routes.login);
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
                GoRouter.of(context).pop();
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
        title: const Text(''),
        centerTitle: true,
        actions: [
          if (currentUser.usertype == 'donor' || currentUser.usertype == 'recipient')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4), // Space between text and icon
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.message),
                        if (unreadMessagesCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.red,
                              child: Text(
                                '$unreadMessagesCount',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      GoRouter.of(context).go(
                        currentUser.usertype == 'donor' 
                          ? Routes.senderscreen 
                          : Routes.recipientMssgscreen
                      );
                    },
                  ),
                ],
              ),
            ),
            
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: IconButton(
              icon: const Icon(Icons.person),
              onPressed: _navigateToEditProfile,
            ),
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
                GoRouter.of(context).pop();
                GoRouter.of(context).go(
                Routes.profile,
                extra: currentUser, 
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(currentUser.usertype == 'Admin' ? 'User Requests' : 'Edit Profile'),
              onTap: () {
                GoRouter.of(context).pop();
                if (currentUser.usertype == 'Admin') {
                  GoRouter.of(context).go(Routes.adminVerify);
                } else {
                  _navigateToEditProfile();
                }
              },
            ),
           if (currentUser.usertype == 'recipient') ...[
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Unlocked Donors'),
              onTap: () {
                GoRouter.of(context).go(Routes.selectedDonorsScreen); 
              },
            ),
          ],
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text(currentUser.usertype == 'Admin' ? 'All Donors' : 'Upload Documents'),
              onTap: () {
                GoRouter.of(context).pop();
                if (currentUser.usertype == 'Admin') {
                  GoRouter.of(context).go(Routes.allDonors);
                } else {
                  GoRouter.of(context).go(Routes.documentUpload, extra: currentUser);
                }
              },
            ),
            if (currentUser.usertype == 'Admin')
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('All Recipients'),
                onTap: () {
                  GoRouter.of(context).pop();
                  GoRouter.of(context).go(Routes.allRecipients);
                },
              ),
            const Divider(),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                GoRouter.of(context).pop();
                _showLogoutConfirmation();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: currentUser.usertype == 'donor'
           ? RecipientListPage()
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