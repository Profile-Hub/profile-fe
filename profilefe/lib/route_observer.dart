import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomRouteObserver extends RouteObserver<PageRoute> {
 
  String  routeName = '/';
  bool _isRefreshing = false;

  String get currentRoute => routeName;
  bool get isRefreshing => _isRefreshing;
  Future<void> saveCurrentRoute(String? routeName) async {
    if (routeName != null && !_isRefreshing) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastRoute', routeName);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    saveCurrentRoute(route.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    saveCurrentRoute(newRoute?.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    saveCurrentRoute(previousRoute?.settings.name);
  }

  Future<void> setRefreshing(bool isRefreshing) async {
    _isRefreshing = isRefreshing;
  }

  static Future<String> getLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastRoute') ?? '/';
  }
}
