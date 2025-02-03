import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LanguageProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  Locale _currentLocale = const Locale('en');
  
  Locale get currentLocale => _currentLocale;
  
  static const String _storageKey = 'selected_language';
  
  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('hi'), 
   
    // Add more supported languages here
  ];
  
  Future<void> initializeLanguage() async {
    final savedLanguage = await _storage.read(key: _storageKey);
    if (savedLanguage != null) {
      _currentLocale = Locale(savedLanguage);
      notifyListeners();
    }
  }
  
  Future<void> setLanguage(Locale locale) async {
    if (_currentLocale == locale) return;
    
    _currentLocale = locale;
    await _storage.write(key: _storageKey, value: locale.languageCode);
    notifyListeners();
  }
}