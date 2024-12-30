import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

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
          Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
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
                  label: 'Old Password',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your old password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // New Password Field
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'New Password',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters long';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'Password must contain at least one uppercase letter';
                    }
                    if (!RegExp(r'[a-z]').hasMatch(value)) {
                      return 'Password must contain at least one lowercase letter';
                    }
                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      return 'Password must contain at least one digit';
                    }
                    if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
                      return 'Password must contain at least one special character (!@#\$&*~)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Confirm Password Field
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
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
                        : const Text('Change Password'),
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
