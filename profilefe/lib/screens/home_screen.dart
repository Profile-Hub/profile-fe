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
import '../theme.dart';
import '../services/subscription_service.dart';
import './subscriptionStatusScreen.dart';

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
  final SubscriptionService _subscriptionService = SubscriptionService();
  late User currentUser;
  final unreadMessagesCount = 0;
  int userCredits = 0;
  bool isLoadingCredits = true;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _updateUserLocation();
    if (currentUser.usertype == 'recipient') {
      _loadCreditStatus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkProfileCompletion();
  }
  Future<void> _loadCreditStatus() async {
    try {
      final creditStatus = await _subscriptionService.getCreditStatus(context);
      if (mounted) {
        setState(() {
          userCredits = creditStatus.credit;
          isLoadingCredits = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingCredits = false;
        });
      }
    }
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
    final theme = Theme.of(context);
    
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
        final localization = AppLocalizations.of(context)!;
            return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: AppTheme.backgroundColor,
                title: Text(
                    localization.profileCompletion,
                    style: theme.textTheme.headlineMedium,
                ),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        if (missingFields.isNotEmpty || missingDocuments.isNotEmpty)
                            Text(
                                localization.profileCompletionMessage,
                                style: theme.textTheme.bodyLarge,
                            ),
                        if (missingFields.isNotEmpty)
                            Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                    localization.completeFields,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        color: AppTheme.textDark,
                                        fontWeight: FontWeight.w600,
                                    ),
                                ),
                            ),
                        ...missingFields.map((field) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
                            child: Row(
                                children: [
                                    Icon(
                                        Icons.arrow_right, 
                                        size: 20,
                                        color: AppTheme.textDark,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            field,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textDark,
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        )),
                        if (missingDocuments.isNotEmpty)
                            Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                    localization.uploadRequiredDocuments,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                        color: AppTheme.textDark,
                                        fontWeight: FontWeight.w600,
                                    ),
                                ),
                            ),
                        ...missingDocuments.map((doc) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
                            child: Row(
                                children: [
                                    Icon(
                                        Icons.arrow_right, 
                                        size: 20,
                                        color: AppTheme.textDark,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            doc,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textDark,
                                            ),
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
                                        style: TextButton.styleFrom(
                                            foregroundColor: AppTheme.primaryBlue,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                            ),
                                        ),
                                        onPressed: () {
                                            GoRouter.of(context).pop();
                                            GoRouter.of(context).go(Routes.documentUpload, extra: currentUser);
                                        },
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                                Icon(
                                                    Icons.upload_file,
                                                    color: AppTheme.primaryBlue,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                    localization.uploadDocumentsButton,
                                                    style: theme.textTheme.labelLarge?.copyWith(
                                                        color: AppTheme.primaryBlue,
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                ),
                            if (missingFields.isNotEmpty)
                                Center(
                                    child: TextButton(
                                        style: TextButton.styleFrom(
                                            foregroundColor: AppTheme.primaryBlue,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                            ),
                                        ),
                                        onPressed: () {
                                            GoRouter.of(context).pop();
                                            GoRouter.of(context).go(Routes.editProfile, extra: currentUser);
                                        },
                                        child: Text(
                                            localization.completeProfile,
                                            style: theme.textTheme.labelLarge?.copyWith(
                                                color: AppTheme.primaryBlue,
                                            ),
                                        ),
                                    ),
                                ),
                            Center(
                                child: TextButton(
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.textGrey,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                        ),
                                    ),
                                    onPressed: () => GoRouter.of(context).pop(),
                                    child: Text(
                                        localization.cancel,
                                        style: theme.textTheme.labelLarge?.copyWith(
                                            color: AppTheme.textGrey,
                                        ),
                                    ),
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
  final theme = Theme.of(context);
  
  return Scaffold(
    key: _scaffoldKey,
    backgroundColor: theme.scaffoldBackgroundColor,
    appBar: AppBar(
      leading: IconButton(
        icon: Icon(Icons.menu, color: AppTheme.textDark),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: const Text(''),
      centerTitle: true,
      backgroundColor: AppTheme.backgroundColor,
      elevation: 0,
      actions: [
        if (currentUser.usertype == 'recipient')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3B82F6).withOpacity(0.1),
                    Color(0xFF3B82F6).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color(0xFF3B82F6).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.stars_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isLoadingCredits)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Text(
                          '$userCredits',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Credits',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        if (currentUser.usertype == 'donor' || currentUser.usertype == 'recipient')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  localization.chat,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Stack(
                    children: [
                      Icon(Icons.message, color: AppTheme.textDark),
                      if (unreadMessagesCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: AppTheme.errorRed,
                            child: Text(
                              '$unreadMessagesCount',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
            icon: Icon(Icons.person, color: AppTheme.textDark),
            onPressed: _navigateToEditProfile,
          ),
        ),
      ],
    ),
    drawer: Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
            ),
            currentAccountPicture: ProfileAvatar(
              user: currentUser,
              radius: 30,
              showEditButton: false,
            ),
            accountName: Text(
              '${currentUser.firstname} ${currentUser.lastname}',
              style: theme.textTheme.labelLarge,
            ),
            accountEmail: Text(
              currentUser.email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person_outline, color: AppTheme.textDark),
            title: Text(
              localization.viewProfile,
              style: theme.textTheme.bodyLarge,
            ),
            onTap: () {
              GoRouter.of(context).pop();
              GoRouter.of(context).go(Routes.profile, extra: currentUser);
            },
          ),
          ListTile(
            leading: Icon(Icons.edit, color: AppTheme.textDark),
            title: Text(
              currentUser.usertype == 'Admin' 
                ? localization.adminRequests 
                : localization.editProfile,
              style: theme.textTheme.bodyLarge,
            ),
            onTap: () {
              GoRouter.of(context).pop();
              if (currentUser.usertype == 'Admin') {
                GoRouter.of(context).go(Routes.adminVerify);
              } else {
                _navigateToEditProfile();
              }
            },
          ),
          if (currentUser.usertype == 'recipient')
            ListTile(
              leading: Icon(Icons.card_membership, color: AppTheme.textDark),
              title: Text(
                localization.subscriptionStatus,
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                GoRouter.of(context).pop();
                GoRouter.of(context).go(Routes.subscriptionStatus);
              },
            ),
          if (currentUser.usertype == 'recipient')
            ListTile(
              leading: Icon(Icons.people, color: AppTheme.textDark),
              title: Text(
                localization.unlockedDonors,
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                GoRouter.of(context).go(Routes.selectedDonorsScreen);
              },
            ),
          ListTile(
            leading: Icon(Icons.upload_file, color: AppTheme.textDark),
            title: Text(
              currentUser.usertype == 'Admin' 
                ? localization.allDonors 
                : localization.uploadDocuments,
              style: theme.textTheme.bodyLarge,
            ),
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
              leading: Icon(Icons.people, color: AppTheme.textDark),
              title: Text(
                localization.allRecipients,
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                GoRouter.of(context).pop();
                GoRouter.of(context).go(Routes.allRecipients);
              },
            ),
          const Divider(),
          const Spacer(),
          ListTile(
            leading: Icon(Icons.logout, color: AppTheme.errorRed),
            title: Text(
              localization.logout,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.errorRed,
              ),
            ),
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
        ? Center(
            child: Text(
              localization.welcomeAdmin,
              style: theme.textTheme.headlineLarge,
            ),
          )
        : DonorListPage(),
  );
}
}