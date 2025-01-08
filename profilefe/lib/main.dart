import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'routes.dart';
import 'route_observer.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/adminVerify_screen.dart';
import 'screens/allDonorAdmin_dart.dart';
import 'screens/allReciptent_Screen.dart';
import 'screens/donerDetails_screen.dart';
import 'screens/document_upload_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/email_change_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/subscription_plans_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? lastRoute = prefs.getString('lastRoute') ?? Routes.splashScreen;

  // Initialize UserProvider and load user data
  final userProvider = UserProvider();
  await userProvider.loadUser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => userProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MainApp(initialRoute: lastRoute),
    ),
  );
}

class MainApp extends StatelessWidget {
  final String initialRoute;

  const MainApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: initialRoute,
      routes: [
        GoRoute(
          path: Routes.splashScreen,
          builder: (context, state) => SplashScreen(),
        ),
        GoRoute(
          path: Routes.signup,
          builder: (context, state) => SignupScreen(),
        ),
        GoRoute(
          path: Routes.forgotPassword,
          builder: (context, state) => ForgotPasswordScreen(),
        ),
        GoRoute(
          path: Routes.login,
          builder: (context, state) => LoginScreen(),
        ),
        GoRoute(
          path: Routes.home,
          builder: (context, state) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            print(userProvider.user);
            return userProvider.user != null
                ? HomeScreen(user: userProvider.user!)
                : LoginScreen();
          },
        ),
        GoRoute(
          path: Routes.adminVerify,
          builder: (context, state) => AdminPage(),
        ),
        GoRoute(
          path: Routes.allDonors,
          builder: (context, state) => AllDonorPage(),
        ),
        GoRoute(
          path: Routes.allRecipients,
          builder: (context, state) => AllRecipientPage(),
        ),
       GoRoute(
          path: '${Routes.donorDetails}/:id',  
             builder: (context, state) {
            final donorId = state.pathParameters['id'] ?? '';  
              return DonorDetailPage(donorId: donorId);
               },
            ),
        GoRoute(
          path: Routes.documentUpload,
          builder: (context, state) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            return userProvider.user != null
                ? DocumentUploadScreen(user: userProvider.user!)
                : LoginScreen();
          },
        ),
        GoRoute(
          path: Routes.profile,
          builder: (context, state) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            return userProvider.user != null
                ? ProfileScreen(user: userProvider.user!)
                : LoginScreen();
          },
        ),
        GoRoute(
          path: Routes.editProfile,
          builder: (context, state) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            return userProvider.user != null
                ? EditProfileScreen(user: userProvider.user!)
                : LoginScreen();
          },
        ),
        GoRoute(
          path: Routes.changeEmail,
          builder: (context, state) {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            return userProvider.user != null
                ? ChangeEmailScreen(user: userProvider.user!)
                : LoginScreen();
          },
        ),
        GoRoute(
          path: Routes.changePassword,
          builder: (context, state) => ChangePasswordScreen(),
        ),
        GoRoute(
          path: Routes.subscriptionPlans,
          builder: (context, state) => SubscriptionPlansScreen(),
        ),
      ],
      observers: [
        CustomRouteObserver(),
      ],
    );

    return MaterialApp.router(
      title: 'Profile Hub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: router,
    );
  }
}
