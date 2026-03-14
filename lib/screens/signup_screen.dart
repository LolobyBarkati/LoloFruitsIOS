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
  bool _isLoading = false;
  String? _verificationId;

  final String _twoFactorApiKey = '7e388030-6e57-11f0-a562-0200cd936042';

  Future<void> sendOtp2Factor() async {
    final phone = '$_countryCode${_phoneController.text.trim()}';
    final uri = Uri.parse('https://2factor.in/API/V1/$_twoFactorApiKey/SMS/$phone/AUTOGEN');

    try {
      final response = await http.get(uri);
      final jsonResponse = json.decode(response.body);

      if (jsonResponse['Status'] == 'Success') {
        setState(() {
          _isOtpSent = true;
          _verificationId = jsonResponse['Details'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully!'), backgroundColor: Color(0xFF689F38)),
        );
      } else {
        throw jsonResponse['Details'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> verifyOtp2Factor() async {
    final otp = _otpController.text.trim();
    final sessionId = _verificationId;

    if (sessionId == null || otp.isEmpty) return;

    final uri = Uri.parse('https://2factor.in/API/V1/$_twoFactorApiKey/SMS/VERIFY/$sessionId/$otp');

    try {
      final response = await http.get(uri);
      final jsonResponse = json.decode(response.body);

      if (jsonResponse['Status'] == 'Success') {
        setState(() => _isPhoneVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verified!'), backgroundColor: Color(0xFF689F38)),
        );
      } else {
        throw jsonResponse['Details'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void signUpUser() async {
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verify phone first."), backgroundColor: Colors.red));
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agree to Terms and Conditions."), backgroundColor: Colors.red));
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text("Terms of Use", style: TextStyle(fontWeight: FontWeight.bold)),
              content: const SingleChildScrollView(
                child: Text(
                  "This app may capture screen activity including sensitive content such as passwords, payment info, messages, and audio. By proceeding, you agree to use this feature legally.",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Disagree", style: TextStyle(color: Colors.red))),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Agree", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF33691E))),
                ),
              ],
            );
          },
        );
      },
    );

    if (accepted != true) return;

    setState(() => _isLoading = true);
    bool res = await _authMethods.signUpUser(
      context,
      _emailController.text,
      _usernameController.text,
      _passwordController.text,
      phoneNumber: '$_countryCode${_phoneController.text}',
    );
    setState(() => _isLoading = false);

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
    const primaryLightGreen = Color(0xFF8BC34A);
    const secondaryDarkGreen = Color(0xFF33691E);
    const accentLime = Color(0xFFD4E157);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Light Green Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [accentLime, primaryLightGreen, secondaryDarkGreen],
              ),
            ),
          ),
          
          // 2. Decorative Icon
          Positioned(
            top: -50,
            right: -50,
            child: Opacity(opacity: 0.1, child: const Icon(Icons.eco_rounded, size: 300, color: Colors.white)),
          ),

          // 3. Form Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    const Text('Join Lolo Fruits', 
                      style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                    const SizedBox(height: 25),
                    
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(28.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Create Account', 
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: secondaryDarkGreen)),
                              const SizedBox(height: 25),
                              
                              CustomTextField(controller: _usernameController, hintText: "Username", prefixIcon: const Icon(Icons.person_outline, color: primaryLightGreen)),
                              const SizedBox(height: 16),
                              
                              CustomTextField(controller: _emailController, hintText: "Email", prefixIcon: const Icon(Icons.email_outlined, color: primaryLightGreen)),
                              const SizedBox(height: 16),
                              
                              CustomTextField(
                                controller: _passwordController,
                                hintText: "Password",
                                obscureText: !_showPassword,
                                prefixIcon: const Icon(Icons.lock_outline, color: primaryLightGreen),
                                suffixIcon: IconButton(
                                  icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 20),
                                  onPressed: () => setState(() => _showPassword = !_showPassword),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F4F2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IntlPhoneField(
                                  controller: _phoneController,
                                  initialCountryCode: 'IN',
                                  style: const TextStyle(fontSize: 15),
                                  dropdownIconPosition: IconPosition.trailing,
                                  decoration: const InputDecoration(
                                    hintText: 'Phone Number',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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

                              if (!_isPhoneVerified) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: CustomButton(
                                    onTap: _isOtpSent ? null : sendOtp2Factor,
                                    text: _isOtpSent ? 'OTP SENT' : 'SEND OTP',
                                    backgroundColor: _isOtpSent ? Colors.grey : secondaryDarkGreen,
                                  ),
                                ),
                                if (_isOtpSent) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomTextField(controller: _otpController, hintText: "Enter OTP", prefixIcon: const Icon(Icons.pin, color: primaryLightGreen)),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.filled(
                                        onPressed: verifyOtp2Factor,
                                        icon: const Icon(Icons.check_circle_rounded),
                                        style: IconButton.styleFrom(backgroundColor: Colors.orange),
                                      )
                                    ],
                                  ),
                                ],
                              ] else 
                                Center(
                                  child: Chip(
                                    label: const Text("Phone Verified"),
                                    avatar: const Icon(Icons.verified, color: Colors.white, size: 16),
                                    backgroundColor: primaryLightGreen,
                                    labelStyle: const TextStyle(color: Colors.white),
                                  ),
                                ),

                              const SizedBox(height: 12),
                              CheckboxListTile(
                                value: _agreedToTerms,
                                title: const Text("Agree to App Terms", style: TextStyle(fontSize: 12)),
                                onChanged: (val) => setState(() => _agreedToTerms = val!),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: primaryLightGreen,
                              ),
                              const SizedBox(height: 12),
                              
                              _isLoading 
                                ? const Center(child: CircularProgressIndicator(color: secondaryDarkGreen))
                                : SizedBox(
                                    width: double.infinity,
                                    child: CustomButton(
                                      onTap: (_isPhoneVerified && _agreedToTerms) ? signUpUser : null,
                                      text: 'CREATE ACCOUNT',
                                      backgroundColor: (_isPhoneVerified && _agreedToTerms) ? secondaryDarkGreen : Colors.grey,
                                      textColor: Colors.white,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text("Already have an account? Login", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}