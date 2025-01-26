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

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _initializeApp();
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
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them.';
        });
        return false;
      }

      // Platform specific checks
      if (UniversalPlatform.isIOS) {
        // iOS specific location check
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
        // Android specific location check
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
        // Web specific implementation
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
      } else if (UniversalPlatform.isIOS) {
        // iOS specific implementation
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 5),
        );
      } else {
        // Android implementation
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      }

      // Store location in secure storage
      await _storage.write(key: 'user_latitude', value: position.latitude.toString());
      await _storage.write(key: 'user_longitude', value: position.longitude.toString());
      
      // Store platform information
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Start the animation
      _animationController.forward();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Initialize location and auth in parallel
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 58, 151, 250), // Bright doctor-blue theme
              const Color.fromARGB(255, 36, 144, 245), // Deeper blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: _buildLoadingIndicator(),
          ),
        ),
      ),
    );
  }
}