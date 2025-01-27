import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import './signup_screen.dart';
import 'home_screen.dart';
import './forgot_password_screen.dart';
import '../routes.dart'; 
import '../routes.dart'; 
import 'package:go_router/go_router.dart';
import '../routes.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        final loginResponse = await _authService.login(email, password);

        if (loginResponse != null && loginResponse.success) {
          print('Login successful!');

          // Save token for future use
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', loginResponse.token);
          final token = loginResponse.token;
          if (token.isNotEmpty) {
            GoRouter.of(context).go(Routes.home);
          } else {
            print('Token is empty');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loginResponse?.message ?? 'Login failed')),
          );
        }
      } catch (e) {
        print('Error during login: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred. Please try again.')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loader
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final loginResponse = await _authService.signInWithGoogle();

      if (loginResponse != null && loginResponse.success) {
        GoRouter.of(context).go(Routes.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign in failed')),
        );
      }
    } catch (e) {
      print('Error during Google sign in: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during Google sign in')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 50),
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                'Login',
                                style: TextStyle(fontSize: 16),
                              ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            GoRouter.of(context).go(Routes.forgotPassword);
                          },
                          child: Text('Forgot Password?'),
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Or continue with'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _socialLoginButton(
                            'assets/google_logo.png',
                            'Google',
                            _handleGoogleSignIn,
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? "),
                          TextButton(
                            onPressed: () {
                              GoRouter.of(context).go(Routes.signup);
                            },
                            child: Text('Sign Up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _socialLoginButton(String iconPath, String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, height: 24),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
