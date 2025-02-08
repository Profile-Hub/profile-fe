import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../routes.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _isLanguageSelected = false;
  bool _hasLocationPermission = false;
  String? _errorMessage;
 Locale? _selectedLocale;
 
  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en': return 'English';
      case 'hi': return 'हिंदी';
      default: return languageCode;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _handleLocationPermission() async {
    if (kIsWeb) {
      return await _handleWebLocationPermission();
    }

    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them.';
        });
        return false;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are required for this app.';
          });
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied. Please enable them in settings.';
        });
        return false;
      }

      setState(() {
        _hasLocationPermission = true;
      });
      return true;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking location permissions: $e';
      });
      return false;
    }
  }

  Future<bool> _handleWebLocationPermission() async {
    try {
      final permission = await html.window.navigator.permissions?.query({
        'name': 'geolocation'
      });

      if (permission?.state == 'denied') {
        setState(() {
         _hasLocationPermission = true;
        });
        return false;
      }

      setState(() {
        _hasLocationPermission = true;
      });
      return true;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking location permissions in web: $e';
      });
      return false;
    }
  }

  Future<void> _getCurrentLocation() async {
  if (!_hasLocationPermission) {
    final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;
    }

  try {
    Position position;
    
    if (kIsWeb) {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } else if (UniversalPlatform.isIOS) {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 5),
      );
    } else {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }

    await _storage.write(key: 'user_latitude', value: position.latitude.toString());
    await _storage.write(key: 'user_longitude', value: position.longitude.toString());
    await _storage.write(key: 'platform', value: _getPlatformName());
    
    if (_isLanguageSelected && mounted) {
      _proceedToNextScreen();
    }
  } catch (e) {
    _proceedToNextScreen();
    debugPrint('Error getting location: $e');
  }
}


  String _getPlatformName() {
    if (kIsWeb) return 'web';
    if (UniversalPlatform.isIOS) return 'ios';
    if (UniversalPlatform.isAndroid) return 'android';
    return 'unknown';
  }

  void _proceedToNextScreen() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    if (mounted) {
      if (authProvider.isAuthenticated) {
        GoRouter.of(context).go(Routes.home);
      } else {
        GoRouter.of(context).go(Routes.login);
      }
    }
  }

   Widget _buildLanguageSelector() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const Text(
                'भाषा चुनें',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 24),
              ...LanguageProvider.supportedLocales.map((Locale locale) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _selectedLocale == locale ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RadioListTile<Locale>(
                    title: Text(
                      _getLanguageName(locale.languageCode),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _selectedLocale == locale ? FontWeight.w600 : FontWeight.normal,
                        color: _selectedLocale == locale ? AppTheme.primaryBlue : AppTheme.textDark,
                      ),
                    ),
                    value: locale,
                    groupValue: _selectedLocale,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        setState(() {
                          _selectedLocale = newLocale;
                          _isLanguageSelected = true;
                        });
                        languageProvider.setLanguage(newLocale);
                        _getCurrentLocation();
                      }
                    },
                  ),
                );
              }).toList(),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppTheme.errorRed,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.secondaryBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icon.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 32),
                  _buildLanguageSelector(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}