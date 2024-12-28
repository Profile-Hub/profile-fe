import 'package:flutter/material.dart';
import '../services/forgot_password_service.dart';


class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ForgotPasswordService _forgotPasswordService = ForgotPasswordService();
  bool _isLoading = false;
  bool _otpSent = false;
  bool _otpVerified = false;

  Future<void> _sendOtp() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackbar('Please enter your email');
      return;
    }

    setState(() => _isLoading = true);

    final response = await _forgotPasswordService.sendOtp(_emailController.text.trim());
    setState(() => _isLoading = false);

    if (response.success) {
      setState(() => _otpSent = true);
      _showSnackbar(response.message);
    } else {
      _showSnackbar(response.message);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      _showSnackbar('Please enter the OTP');
      return;
    }

    setState(() => _isLoading = true);

    final response = await _forgotPasswordService.verifyOtp(
       _emailController.text.trim(),
       _otpController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (response.success) {
      setState(() => _otpVerified = true);
      _showSnackbar(response.message);
    } else {
      _showSnackbar(response.message);
    }
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showSnackbar('Passwords do not match');
        return;
      }

      setState(() => _isLoading = true);

      final response = await _forgotPasswordService.resetPassword(
        email: _emailController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );
      setState(() => _isLoading = false);

      _showSnackbar(response.message);

      if (response.success) {
        Navigator.pop(context); // Navigate back to the login screen
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Forgot Password')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter your email' : null,
              ),
              if (_otpSent) ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  decoration: InputDecoration(labelText: 'OTP'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Please enter the OTP' : null,
                ),
              ],
              if (_otpVerified) ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your new password'
                      : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please confirm your password'
                      : null,
                ),
              ],
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : !_otpSent
                        ? _sendOtp
                        : !_otpVerified
                            ? _verifyOtp
                            : _resetPassword,
                child: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text(
                        !_otpSent
                            ? 'Send OTP'
                            : !_otpVerified
                                ? 'Verify OTP'
                                : 'Reset Password',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
