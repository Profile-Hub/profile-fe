import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'screens/Chat_screen.dart';
import 'screens/DonnerChat_Screen.Dart';
import 'screens/selectedDonerList_screen.dart';
import  'screens/sendermssg_screen.dart';
import  'screens/Reciptentmssg_screen.dart';
import   'screens/ReciptentDetails_screen.dart';
import   'screens/DocumentVerify_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'providers/language_provider.dart';
import 'theme.dart';

final secureStorage = FlutterSecureStorage();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  final userProvider = UserProvider();
  await userProvider.initializeFromSecureStorage();
  final languageProvider = LanguageProvider();
  await languageProvider.initializeLanguage();


  final router = GoRouter(
    debugLogDiagnostics: true, 
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
        builder: (context, state) => FutureBuilder<User?>(
          future: Provider.of<UserProvider>(context, listen: false).getCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return HomeScreen(user: snapshot.data!);
            }
            return LoginScreen();
          },
        ),
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
        path: '${Routes.recipientDetails}/:id',
        builder: (context, state) {
          final recipientId = state.pathParameters['id'] ?? '';
          return RecipitentDetailPage(recipientId: recipientId);
        },
      ),
      GoRoute(
        path: '${Routes.documentverify}/:id',
        builder: (context, state) {
          final donorId = state.pathParameters['id'] ?? '';
          return DocumentverifyPage(donorId: donorId);
        },
      ),
      GoRoute(
        path: Routes.documentUpload,
        builder: (context, state) => FutureBuilder<User?>(
          future: Provider.of<UserProvider>(context, listen: false).getCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return DocumentUploadScreen(user: snapshot.data!);
            }
            return LoginScreen();
          },
        ),
      ),
        GoRoute(
        path: '${Routes.chat}/:conversationSid',
        builder: (context, state) {
           final data = state.extra as Map<String, dynamic>? ?? {};
          return ChatScreen(
            conversationSid: data['conversationSid'] ?? '',
            userName: data['userName'] ?? '',
            profileImage: data['profileImage'] ?? '',
          );
        },
      ),
      
      GoRoute(
          path: Routes.senderscreen,
          builder: (context, state) => SenderScreen(),
        ),
         GoRoute(
  path: Routes.recipientMssgscreen,
  builder: (context, state) => FutureBuilder<User?>(
    future: Provider.of<UserProvider>(context, listen: false).getCurrentUser(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasData && snapshot.data != null) {
        return RecipientScreen(user: snapshot.data!);
      }
      return LoginScreen();
    },
  ),
),
    GoRoute(
        path: '${Routes.donnerchat}/:conversationSid',
        builder: (context, state) {
         final data = state.extra as Map<String, dynamic>? ?? {};
          return DonorChatScreen(
           conversationSid: data['conversationSid'] ?? '',
            userName: data['userName'] ?? '',
            profileImage: data['profileImage'] ?? '',
          );
        },
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => FutureBuilder<User?>(
          future: Provider.of<UserProvider>(context, listen: false).getCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return ProfileScreen(user: snapshot.data!);
            }
            return LoginScreen();
          },
        ),
      ),
      GoRoute(
        path: Routes.editProfile,
        builder: (context, state) => FutureBuilder<User?>(
          future: Provider.of<UserProvider>(context, listen: false).getCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return EditProfileScreen(user: snapshot.data!);
            }
            return LoginScreen();
          },
        ),
      ),
      GoRoute(
        path: Routes.changeEmail,
        builder: (context, state) => FutureBuilder<User?>(
          future: Provider.of<UserProvider>(context, listen: false).getCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return ChangeEmailScreen(user: snapshot.data!);
            }
            return LoginScreen();
          },
        ),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (context, state) => ChangePasswordScreen(),
      ),
       GoRoute(
      path: Routes.selectedDonorsScreen,
      builder: (context, state) => SelectedDonersScreen(),
    ),
      GoRoute(
        path: Routes.subscriptionPlans,
        builder: (context, state) => SubscriptionPlansScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = await userProvider.getCurrentUser();
      
      final isLoginRoute = state.matchedLocation == Routes.login;
      final isSignupRoute = state.matchedLocation == Routes.signup;
      final isForgotPasswordRoute = state.matchedLocation == Routes.forgotPassword;
      final isSplashRoute = state.matchedLocation == Routes.splashScreen;

      // Allow access to auth routes even when not logged in
      if (isLoginRoute || isSignupRoute || isForgotPasswordRoute || isSplashRoute) {
        if (user != null) {
          return Routes.home;
        }
        return null;
      }

      // Redirect to login if not authenticated
      if (user == null) {
        return Routes.login;
      }

      return null;
    },
    observers: [
      CustomRouteObserver(),
    ],
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => userProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
         ChangeNotifierProvider(create: (_) => languageProvider),
      ],
      child: MainApp(router: router),
    ),
  );
}

class MainApp extends StatelessWidget {
  final GoRouter router;
  
  const MainApp({
    Key? key,
    required this.router,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp.router(
          title: 'Need a Donor',
          theme: AppTheme.lightTheme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: LanguageProvider.supportedLocales,
          locale: languageProvider.currentLocale,
        );
      },
    );
  }
}