import 'package:flutter/material.dart';
import '../models/user.dart';
import 'dart:async';
import '../services/email_service.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../theme.dart';

class ChangeEmailScreen extends StatefulWidget {
  final User user;

  ChangeEmailScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ChangeEmailScreenState createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _emailService = EmailVerificationService();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<TextEditingController> _newOtpControllers = List.generate(6, (_) => TextEditingController());
  final _newEmailController = TextEditingController();

  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _isNewOtpSent = false;
  bool _isNewOtpVerified = false;
  Timer? _timer;
  int _countdown = 120;
  String? _otpError;

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _sendOtp() async {
    final response = await _emailService.sendOtp(widget.user.email);
    if (response.success) {
      setState(() {
        _isOtpSent = true;
        _countdown = 120;
      });
      startTimer();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  void _verifyOtp() async {
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() {
        _otpError = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _otpError = null;
    });

    final response = await _emailService.verifyOtp(widget.user.email, otp);
    if (response.success) {
      setState(() {
        _isOtpVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  void _sendNewOtp() async {
    final response = await _emailService.sendOtp(_newEmailController.text);
    if (response.success) {
      setState(() {
        _countdown = 120;
        _isNewOtpSent = true;
      });
      startTimer();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  void _verifyNewOtp() async {
    String otp = _newOtpControllers.map((controller) => controller.text).join();

    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() {
        _otpError = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _otpError = null;
    });

    final response = await _emailService.verifyOtp(_newEmailController.text, otp);
    if (response.success) {
      setState(() {
        _isNewOtpVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  void _updateEmail() async {
    final response = await _emailService.updateEmail(widget.user.email, _newEmailController.text);
    if (response.success) {
      setState(() {
        widget.user.email = _newEmailController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email updated successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  Widget _buildOtpInput(List<TextEditingController> controllers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        6,
        (index) => SizedBox(
          width: 45,
          child: TextFormField(
            controller: controllers[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: AppTheme.otpInputDecoration,
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            GoRouter.of(context).pop();
          },
        ),
        title: Text(localization.changeEmail),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: widget.user.email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: localization.currentEmail,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _sendOtp,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(localization.sendOtp),
                ),
              ),
              if (_isOtpSent && !_isOtpVerified) ...[
                const SizedBox(height: 24),
                _buildOtpInput(_otpControllers),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _verifyOtp,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(localization.verifyOtp),
                  ),
                ),
                SizedBox(height: 24),
                GestureDetector(
                  onTap: _countdown == 0 ? _sendOtp : null,
                  child: RichText(
                    text: TextSpan(
                      text: localization.resend_otp,
                      style: TextStyle(
                        color: _countdown == 0 ? Colors.red : Colors.black87,
                      ),
                      children: [
                        TextSpan(
                          text: ' in $_countdown s',
                          style: TextStyle(
                            color: Color(0xFF6C3BF9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_otpError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _otpError!,
                    style: const TextStyle(color: AppTheme.errorRed),
                  ),
                ),
              if (_isOtpVerified) ...[
                const SizedBox(height: 24),
                TextField(
                  controller: _newEmailController,
                  decoration: InputDecoration(
                    labelText: localization.enterNewEmail,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _sendNewOtp,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(localization.sendNewEmailOtp),
                  ),
                ),
                if (_isNewOtpSent && !_isNewOtpVerified) ...[
                  const SizedBox(height: 24),
                  _buildOtpInput(_newOtpControllers),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _verifyNewOtp,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(localization.verifyNewEmailOtp),
                    ),
                  ),
                  SizedBox(height: 24),
                  GestureDetector(
                    onTap: _countdown == 0 ? _sendNewOtp : null,
                    child: RichText(
                      text: TextSpan(
                        text: localization.resend_otp,
                        style: TextStyle(
                          color: _countdown == 0 ? Colors.red : Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: ' in $_countdown s',
                            style: TextStyle(
                              color: Color(0xFF6C3BF9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_isNewOtpVerified) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _updateEmail,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(localization.updateEmail),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}