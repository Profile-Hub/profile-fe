import 'package:flutter/material.dart';
import '../services/forgot_password_service.dart';
import 'package:go_router/go_router.dart';
import '../routes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  // Removed const constructor for GoRouter compatibility
  ForgotPasswordScreen({Key? key}) : super(key: key);

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
      final localization = AppLocalizations.of(context)!;
    if (_emailController.text.trim().isEmpty) {
      _showSnackbar(localization.enterEmail);
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
      final localization = AppLocalizations.of(context)!;
    if (_otpController.text.trim().isEmpty) {
      _showSnackbar(localization.enterOtp);
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
      final localization = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showSnackbar(localization.passwordMismatch);
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
        GoRouter.of(context).pop();
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
      final localization = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localization.forgotPassword)),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: localization.email),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || value.isEmpty ? localization.enter_valid_email : null,
              ),
              if (_otpSent) ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  decoration: InputDecoration(labelText: localization.otp),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value == null || value.isEmpty ? localization.enterOtp : null,
                ),
              ],
              if (_otpVerified) ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(labelText: localization.newPassword),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty
                      ? localization.pleaseEnterNewPassword
                      : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(labelText: localization.confirmPassword),
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty
                      ? localization.pleaseConfirmPassword
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
                            ? localization.sendOtp
                            : !_otpVerified
                                ? localization.verifyOtp
                                : localization.resetPassword
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
