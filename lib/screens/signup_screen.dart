import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:barkati_frits/resources/auth_methods.dart';
import 'package:barkati_frits/widgets/custom_button.dart';
import 'package:barkati_frits/widgets/custom_textfield.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:http/http.dart' as http;
import 'package:barkati_frits/screens/fingerprintauth_screen.dart';

class SignupScreen extends StatefulWidget {
  static const String routeName = '/signup';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final AuthMethods _authMethods = AuthMethods();

  String _countryCode = '+91';
  bool _isPhoneVerified = false;
  bool _isOtpSent = false;
  bool _showPassword = false;
  bool _agreedToTerms = false;
  String? _verificationId;

  final String _twoFactorApiKey =
      '7e388030-6e57-11f0-a562-0200cd936042'; // TODO: Replace

  Future<void> sendOtp2Factor() async {
    final phone = '$_countryCode${_phoneController.text.trim()}';

    final uri = Uri.parse(
        'https://2factor.in/API/V1/$_twoFactorApiKey/SMS/$phone/AUTOGEN');

    try {
      final response = await http.get(uri);
      final jsonResponse = json.decode(response.body);

      if (jsonResponse['Status'] == 'Success') {
        setState(() {
          _isOtpSent = true;
          _verificationId = jsonResponse['Details']; // Session ID
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent via 2Factor!')),
        );
      } else {
        throw jsonResponse['Details'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    }
  }

  Future<void> verifyOtp2Factor() async {
    final otp = _otpController.text.trim();
    final sessionId = _verificationId;

    if (sessionId == null || otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP.')),
      );
      return;
    }


    final uri = Uri.parse(
        'https://2factor.in/API/V1/$_twoFactorApiKey/SMS/VERIFY/$sessionId/$otp');

    try {
      final response = await http.get(uri);
      final jsonResponse = json.decode(response.body);

      if (jsonResponse['Status'] == 'Success') {
        setState(() {
          _isPhoneVerified = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verified successfully!')),
        );
      } else {
        throw jsonResponse['Details'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification failed: $e')),
      );
    }
  }

  void signUpUser() async {
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please verify your phone number first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must agree to the Terms and Conditions."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool? accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool _dialogAgreed = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Terms of Use for Screen Recording"),
              content: SizedBox(
                height: 300,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Text(
                        "This app may capture screen activity including sensitive content such as passwords, payment info, messages, and audio. "
                        "By proceeding, you confirm that you understand and agree to use this feature legally and at your own risk. "
                        "Improper use may result in penalties under applicable laws. You also agree to indemnify the service provider "
                        "from any liabilities arising from misuse.",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _dialogAgreed,
                            onChanged: (val) {
                              setState(() {
                                _dialogAgreed = val!;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "I have read and agree to the Terms of Use for Screen Recording.",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Disagree"),
                ),
                TextButton(
                  onPressed:
                      _dialogAgreed ? () => Navigator.pop(context, true) : null,
                  child: const Text("Agree"),
                ),
              ],
            );
          },
        );
      },
    );

    if (accepted != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("You must agree to the screen recording terms to continue."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }


    bool res = await _authMethods.signUpUser(
      context,
      _emailController.text,
      _usernameController.text,
      _passwordController.text,
      phoneNumber: '$_countryCode${_phoneController.text}',
    );


    if (res) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('hasAgreedToScreenTerms', true);
      Navigator.pushReplacementNamed(context, FingerprintAuthScreen.routeName);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Getting Started ',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign up to continue!',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: _emailController,
                              hintText: "Email",
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _usernameController,
                              hintText: "Username",
                              prefixIcon: const Icon(Icons.person),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _passwordController,
                              hintText: "Password",
                              obscureText: !_showPassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: IntlPhoneField(
                                controller: _phoneController,
                                initialCountryCode: 'IN',
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 15),
                                ),
                                onChanged: (phone) {
                                  setState(() {
                                    _countryCode = phone.countryCode;
                                    _isPhoneVerified = false;
                                    _isOtpSent = false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _isOtpSent
                                      ? null
                                      : () {
                                          if (_phoneController.text.isNotEmpty)
                                            sendOtp2Factor();
                                        },
                                  child: const Text('Send OTP'),
                                ),
                                const SizedBox(width: 8),
                                if (_isOtpSent)
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _otpController,
                                            decoration: const InputDecoration(
                                                labelText: 'Enter OTP'),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (_otpController.text.isNotEmpty)
                                              verifyOtp2Factor();
                                          },
                                          child: const Text('Verify'),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _agreedToTerms = value ?? false;
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    "I agree to the Terms and Conditions of the app.",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            CustomButton(
                              onTap: _isPhoneVerified ? signUpUser : null,
                              text: 'SIGN UP',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
