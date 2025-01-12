import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:profilefe/main.dart';
import 'package:profilefe/providers/auth_provider.dart';
import 'package:profilefe/providers/user_provider.dart';
import 'package:profilefe/routes.dart';

void main() {
  late GoRouter testRouter;
  late UserProvider userProvider;
  late AuthProvider authProvider;

  setUp(() {
    userProvider = UserProvider();
    authProvider = AuthProvider();
    
    testRouter = GoRouter(
      initialLocation: Routes.login,
      routes: [
        GoRoute(
          path: Routes.login,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Login Screen')),
          ),
        ),
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home Screen')),
          ),
        ),
      ],
    );
  });

  testWidgets('App should show login screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>(create: (_) => userProvider),
          ChangeNotifierProvider<AuthProvider>(create: (_) => authProvider),
        ],
        child: MainApp(router: testRouter),
      ),
    );
    
    await tester.pumpAndSettle();

    // Verify we're on the login screen
    expect(find.text('Login Screen'), findsOneWidget);
    expect(find.text('Home Screen'), findsNothing);
  });

  testWidgets('App should initialize with required providers', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>(create: (_) => userProvider),
          ChangeNotifierProvider<AuthProvider>(create: (_) => authProvider),
        ],
        child: MainApp(router: testRouter),
      ),
    );

    // Verify providers are available
    expect(
      tester.element(find.byType(MaterialApp)).read<UserProvider>(),
      isNotNull,
    );
    expect(
      tester.element(find.byType(MaterialApp)).read<AuthProvider>(),
      isNotNull,
    );
  });

  // Example of a navigation test - add more based on your app's requirements
  testWidgets('Router should work correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>(create: (_) => userProvider),
          ChangeNotifierProvider<AuthProvider>(create: (_) => authProvider),
        ],
        child: MainApp(router: testRouter),
      ),
    );

    await tester.pumpAndSettle();

    // Initially on login screen
    expect(find.text('Login Screen'), findsOneWidget);

    // You can add more navigation tests here based on your app's flow
    // For example, simulating login and checking if it navigates to home
  });
}