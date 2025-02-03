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
          _errorMessage = 'Location permissions are required for this app.';
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
      setState(() {
        _errorMessage = 'Error getting location: $e';
      });
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
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
                  color: Colors.black87,
                ),
              ),
              const Text(
                'भाषा चुनें',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<Locale>(
                  value: languageProvider.currentLocale,
                  hint: const Text('Select / चुनें'),
                  isExpanded: true,
                  underline: Container(),
                  items: LanguageProvider.supportedLocales.map((Locale locale) {
                    return DropdownMenuItem(
                      value: locale,
                      child: Text(
                        _getLanguageName(locale.languageCode),
                        style: TextStyle(
                          color: languageProvider.currentLocale == locale 
                            ? Colors.blue 
                            : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (Locale? newLocale) {
                    if (newLocale != null) {
                      languageProvider.setLanguage(newLocale);
                      setState(() {
                        _isLanguageSelected = true;
                      });
                      _getCurrentLocation();
                    }
                  },
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
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
              Color.fromARGB(255, 58, 151, 250),
              Color.fromARGB(255, 36, 144, 245),
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