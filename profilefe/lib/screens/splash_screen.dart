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
    _checkLanguageAndInitialize();
  }

  void _checkLanguageAndInitialize() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (languageProvider.currentLocale != null) {
      setState(() {
        _isLanguageSelected = true;
      });
      _initializeApp();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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

      if (UniversalPlatform.isIOS) {
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
      } else if (UniversalPlatform.isAndroid) {
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
      }

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

      return true;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking location permissions in web: $e';
      });
      return false;
    }
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    
    if (!hasPermission) return;

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

  Future<void> _initializeApp() async {
    if (!_isLanguageSelected) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _animationController.forward();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await Future.wait([
        _getCurrentLocation(),
        authProvider.initialize(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (authProvider.isAuthenticated) {
          GoRouter.of(context).go(Routes.home);
        } else {
          GoRouter.of(context).go(Routes.login);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error initializing app: $e';
      });
    }
  }

  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_errorMessage == null) 
          Column(
            children: [
              Image.asset(
                'assets/icon.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        if (_errorMessage == null || !_errorMessage!.contains('permanently denied'))
          TextButton(
            onPressed: _isLoading ? null : _initializeApp,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _errorMessage != null ? 'Retry' : 'Loading...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return DropdownButton<Locale>(
          value: languageProvider.currentLocale,
          dropdownColor: Colors.white,
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
              _initializeApp();
            }
          },
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isLanguageSelected)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Select Language / भाषा चुनें',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        _buildLanguageSelector(),
                      ],
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: Center(
                  child: !_isLanguageSelected
                    ? Container()
                    : _buildLoadingIndicator(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}