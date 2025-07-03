import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneVerificationPage extends StatefulWidget {
  static const String routeName = '/phone-verification';

  const PhoneVerificationPage({super.key});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  String _verificationId = '';
  bool _codeSent = false;
  bool _loading = false;
  String _statusMessage = '';

  void _sendOTP() async {
    setState(() {
      _loading = true;
      _statusMessage = '';
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91${_phoneController.text.trim()}',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        setState(() {
          _statusMessage = 'Phone number automatically verified!';
        });
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _loading = false;
          _statusMessage = 'Verification failed: ${e.message}';
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _loading = false;
          _codeSent = true;
          _verificationId = verificationId;
          _statusMessage = 'OTP sent to your number.';
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _verifyOTP() async {
    setState(() {
      _loading = true;
      _statusMessage = '';
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      setState(() {
        _loading = false;
        _statusMessage = 'Phone number verified successfully!';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _statusMessage = 'Invalid OTP. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Verification')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Enter phone number',
                prefixText: '+91 ',
              ),
            ),
            if (_codeSent)
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : _codeSent
                      ? _verifyOTP
                      : _sendOTP,
              child: Text(_codeSent ? 'Verify OTP' : 'Send OTP'),
            ),
            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
