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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    _updateUserLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkProfileCompletion();
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
    if (!mounted) return;
    
    final localization = AppLocalizations.of(context)!;
    try {
      final response = await _profileCompletionService.checkProfileCompletion();
      
      if (!mounted) return;
      
      if (currentUser.usertype != 'Admin' && response.success && response.notify) {
        _showProfileCompletionDialog(response.missingFields, response.missingDocuments);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localization.checkingProfileError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

void _showProfileCompletionDialog(List<String> missingFields, List<String> missingDocuments) {
   

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
        final localization = AppLocalizations.of(context)!;
            return AlertDialog(
                title:  Text(localization.profileCompletion),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        if (missingFields.isNotEmpty || missingDocuments.isNotEmpty)
                             Text(localization.profileCompletionMessage),
                        if (missingFields.isNotEmpty)
                            Text(localization.completeFields),
                        ...missingFields.map((field) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Row(
                                children: [
                                    const Icon(Icons.arrow_right, size: 20),
                                     SizedBox(width: 8),
                                    Text(
                                        (field),
                                        style:  TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                ],
                            ),
                        )),
                        if (missingDocuments.isNotEmpty)
                             Text(localization.uploadRequiredDocuments),
                        ...missingDocuments.map((doc) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Row(
                               children: [
  const Icon(Icons.arrow_right, size: 20),
  const SizedBox(width: 8),
  Expanded(
    child: Text(
      doc,
      style:  TextStyle(fontWeight: FontWeight.bold),
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
                            if (missingDocuments.isNotEmpty)
                                Center(
                                  child: TextButton(
                                      onPressed: () {
                                          GoRouter.of(context).pop();
                                          GoRouter.of(context).go(Routes.documentUpload, extra: currentUser);
                                      },
                                      child:  Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                              Icon(Icons.upload_file),
                                              SizedBox(width: 8),
                                              Text(localization.uploadDocumentsButton),
                                          ],
                                      ),
                                  ),
                                ),
                            if (missingFields.isNotEmpty)
                                Center(
                                  child: TextButton(
                                      onPressed: () {
                                          GoRouter.of(context).pop();
                                          GoRouter.of(context).go(Routes.editProfile, extra: currentUser);
                                      },
                                      child:  Text(localization.completeProfile),
                                  ),
                                ),
                            Center(
                              child: TextButton(
                                  onPressed: () => GoRouter.of(context).pop(),
                                  child:  Text(localization.cancel),
                              ),
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
     final localization = AppLocalizations.of(context)!;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return  AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(localization.loggingOut),
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
             SnackBar(
              content: Text("${localization.logoutFailed}"),
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
            content: Text('${localization.logoutError}: $e'),
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
      final localization = AppLocalizations.of(context)!;
        return AlertDialog(
          title:  Text(localization.confirmLogout),
          content:  Text(localization.logoutMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:  Text(localization.cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                GoRouter.of(context).pop();
                _handleLogout();
              },
              child:  Text(localization.logout),
            ),
          ],
        );
      },
    );
  }

   @override
  Widget build(BuildContext context) {
      final localization = AppLocalizations.of(context)!;
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
                   Text(
                    localization.chat,
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
                                style:  TextStyle(
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
              title:  Text(localization.viewProfile),
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
              title: Text(currentUser.usertype == 'Admin' ? '${localization.adminRequests}' : '${localization.editProfile}'),
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
              leading:  Icon(Icons.people),
              title:  Text(localization.unlockedDonors),
              onTap: () {
                GoRouter.of(context).go(Routes.selectedDonorsScreen); 
              },
            ),
          ],
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text(currentUser.usertype == 'Admin' ? '${localization.allDonors}' : '${localization.uploadDocuments}'),
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
                leading:  Icon(Icons.people),
                title:  Text(localization.allRecipients),
                onTap: () {
                  GoRouter.of(context).pop();
                  GoRouter.of(context).go(Routes.allRecipients);
                },
              ),
            const Divider(),
            const Spacer(),
            ListTile(
              leading:  Icon(Icons.logout, color: Colors.red),
              title:  Text(localization.logout, style: TextStyle(color: Colors.red)),
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
              ?  Center(
                  child: Text(
                    localization.welcomeAdmin,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                )
              : DonorListPage(),
    );
  }
}