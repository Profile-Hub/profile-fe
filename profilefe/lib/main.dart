import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
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
import 'routes.dart';

class CustomRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) async {
    super.didPush(route, previousRoute);
    if (route.settings.name != null && route.settings.name != Routes.splashScreen) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastRoute', route.settings.name!);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) async {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null && newRoute?.settings.name != Routes.splashScreen) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastRoute', newRoute!.settings.name!);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? lastRoute = prefs.getString('lastRoute') ?? Routes.splashScreen;

  if (lastRoute == Routes.login || lastRoute == Routes.splashScreen) {
    lastRoute = Routes.home;
  }

  runApp(MainApp(initialRoute: lastRoute));
}

class MainApp extends StatelessWidget {
  final String initialRoute;

  const MainApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Profile Hub',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: initialRoute,
        navigatorObservers: [CustomRouteObserver()],
        onGenerateRoute: (RouteSettings settings) {
          // Create a builder function that will properly scope the Provider access
          Widget buildAuthenticatedRoute(BuildContext context, Widget Function(User user) builder) {
            return AuthWrapper(
              child: Consumer<UserProvider>(
                builder: (context, userProvider, _) => builder(userProvider.user!),
              ),
            );
          }

          // Simple wrapper for routes that don't need user data
          Widget buildSimpleAuthRoute(Widget child) {
            return AuthWrapper(child: child);
          }

          // Handle the splash screen case first
          if (settings.name == Routes.splashScreen) {
            return MaterialPageRoute(
              builder: (_) => SplashScreen(),
              settings: settings,
            );
          }

          // Use a builder pattern to create the routes
          Widget Function(BuildContext) builder;
          
          switch (settings.name) {
            case Routes.login:
              builder = (_) => LoginScreen();
              break;

            case Routes.home:
              builder = (context) => buildAuthenticatedRoute(
                context,
                (user) => HomeScreen(user: user),
              );
              break;

            case Routes.adminVerify:
              builder = (_) => buildSimpleAuthRoute(AdminPage());
              break;

            case Routes.allDonors:
              builder = (_) => buildSimpleAuthRoute(AllDonorPage());
              break;

            case Routes.allRecipients:
              builder = (_) => buildSimpleAuthRoute(AllRecipientPage());
              break;

            case Routes.donorDetails:
              builder = (context) => buildSimpleAuthRoute(
                Builder(
                  builder: (context) {
                    final args = settings.arguments;
                    final donorId = args is String ? args : '';
                    return DonorDetailPage(donorId: donorId);
                  },
                ),
              );
              break;

            case Routes.documentUpload:
              builder = (context) => buildAuthenticatedRoute(
                context,
                (user) => DocumentUploadScreen(user: user),
              );
              break;

            case Routes.profile:
              builder = (context) => buildAuthenticatedRoute(
                context,
                (user) => ProfileScreen(user: user),
              );
              break;

            case Routes.editProfile:
              builder = (context) => buildAuthenticatedRoute(
                context,
                (user) => EditProfileScreen(user: user),
              );
              break;

            case Routes.changeEmail:
              builder = (context) => buildAuthenticatedRoute(
                context,
                (user) => ChangeEmailScreen(user: user),
              );
              break;

            case Routes.changePassword:
              builder = (_) => buildSimpleAuthRoute(ChangePasswordScreen());
              break;

            case Routes.subscriptionPlans:
              builder = (_) => buildSimpleAuthRoute(SubscriptionPlansScreen());
              break;

            default:
              builder = (_) => SplashScreen();
          }

          return MaterialPageRoute(
            builder: builder,
            settings: settings,
          );
        },
      ),
    );
  }
}
class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (!authProvider.isAuthenticated) {
          return LoginScreen();
        }
        
        return child;
      },
    );
  }
}