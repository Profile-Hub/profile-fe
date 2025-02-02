import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:go_router/go_router.dart';
import '../routes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  // Removed the 'const' constructor
  ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final response = await _authService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'])),
          );
          GoRouter.of(context).pop();
        }
      } else {
        _showError(response['message'] ?? 'Failed to update password');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
     final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      GoRouter.of(context).pop();
    },
  ),
        title:  Text(localizations.changePassword),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Old Password Field
                _buildPasswordField(
                  controller: _oldPasswordController,
                  label: localizations.oldPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.enterOldPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // New Password Field
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: localizations.newPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.enterNewPasssword;
                    }
                    if (value.length < 8) {
                      return localizations.passwordMinLength;
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return localizations.passwordUppercase;
                    }
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return localizations.passwordLowercase;
                    }
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return localizations.passwordDigit;
                    }
                    if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
                      return localizations.passwordSpecialChar;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Confirm Password Field
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: localizations.confirm_password,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.confirmPassword;
                    }
                    if (value != _newPasswordController.text) {
                      return localizations.passwordMismatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Change Password Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _changePassword,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : Text(localizations.changePassword),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
