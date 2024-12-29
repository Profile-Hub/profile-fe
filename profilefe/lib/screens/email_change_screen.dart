import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/email_service.dart';

class ChangeEmailScreen extends StatefulWidget {
  final User user;

  const ChangeEmailScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ChangeEmailScreenState createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _emailService = EmailVerificationService();
  final _otpController = TextEditingController();
  final _newOtpController = TextEditingController();
  final _newEmailController = TextEditingController();

  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _isNewOtpSent = false;
  bool _isNewOtpVerified = false;

  void _sendOtp() async {
    final response = await _emailService.sendOtp(widget.user.email);
    if (response.success) {
      setState(() {
        _isOtpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  void _verifyOtp() async {
    final response = await _emailService.verifyOtp(widget.user.email, _otpController.text);
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
        _isNewOtpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  void _verifyNewOtp() async {
    final response = await _emailService.verifyOtp(_newEmailController.text, _newOtpController.text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           TextFormField(
                initialValue: widget.user.email,
                readOnly: true, 
                decoration: const InputDecoration(
                  labelText: 'Current Email',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _sendOtp, child: const Text('Send OTP')),
            if (_isOtpSent) ...[
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
              ),
              ElevatedButton(onPressed: _verifyOtp, child: const Text('Verify OTP')),
            ],
            if (_isOtpVerified) ...[
              TextField(
                controller: _newEmailController,
                decoration: const InputDecoration(labelText: 'Enter New Email'),
              ),
              ElevatedButton(onPressed: _sendNewOtp, child: const Text('Send OTP for New Email')),
              if (_isNewOtpSent) ...[
                TextField(
                  controller: _newOtpController,
                  decoration: const InputDecoration(labelText: 'Enter OTP for New Email'),
                ),
                ElevatedButton(onPressed: _verifyNewOtp, child: const Text('Verify New Email OTP')),
              ],
              if (_isNewOtpVerified) ...[
                ElevatedButton(onPressed: _updateEmail, child: const Text('Update Email')),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
