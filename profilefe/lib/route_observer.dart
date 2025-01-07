import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomRouteObserver extends NavigatorObserver {
  // Singleton pattern to ensure we have only one instance
  static final CustomRouteObserver _instance = CustomRouteObserver._internal();
  factory CustomRouteObserver() => _instance;
  CustomRouteObserver._internal();

  // Save the route when navigation occurs
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _saveCurrentRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _saveCurrentRoute(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _saveCurrentRoute(previousRoute);
    }
  }

  // Helper method to save the current route
  void _saveCurrentRoute(Route<dynamic> route) async {
    if (route.settings.name != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastRoute', route.settings.name!);
    }
  }

  // Method to get the last saved route
  static Future<String> getLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastRoute') ?? '/';
  }
}