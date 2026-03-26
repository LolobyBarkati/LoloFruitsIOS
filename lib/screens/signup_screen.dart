import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barkati_frits/resources/auth_methods.dart';
import 'package:barkati_frits/widgets/custom_button.dart';
import 'package:barkati_frits/widgets/custom_textfield.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:http/http.dart' as http;
import 'package:barkati_frits/screens/fingerprintauth_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Timer variables
  Timer? _timer;
  int _start = 30;
  bool _canResend = true;

  final String _twoFactorApiKey = '88533d72-2669-11f1-bcb0-0200cd936042';
  void startTimer() {
    setState(() {
      _canResend = false;
      _start = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  // Logic: Untouched
  Future<void> sendOtp2Factor() async {
    if (!_canResend) return;
    
    final phone = '$_countryCode${_phoneController.text.trim()}';
    final uri = Uri.parse('https://2factor.in/API/V1/$_twoFactorApiKey/SMS/$phone/AUTOGEN/OTP1');

    try {
      final response = await http.get(uri);
      final jsonResponse = json.decode(response.body);

      if (jsonResponse['Status'] == 'Success') {
        setState(() {
          _isOtpSent = true;
          _verificationId = jsonResponse['Details'];
        });
        startTimer(); // Start 30s cooldown
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent successfully!'), backgroundColor: Color(0xFF689F38), behavior: SnackBarBehavior.floating),
        );
      } else {
        throw jsonResponse['Details'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  // Logic: Untouched
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
        _timer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verified!'), backgroundColor: Color(0xFF689F38), behavior: SnackBarBehavior.floating),
        );
      } else {
        throw jsonResponse['Details'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  // Logic: Untouched
  void signUpUser() async {
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verify phone first."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Agree to Terms and Conditions."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      return;
    }

    bool? accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Color(0xFF33691E)),
                  SizedBox(width: 10),
                  Text("Terms of Use", style: TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
              content: const Text(
                "By creating an account, you agree to our Terms of Use and Privacy Policy. Lolo Fruits is an information platform that provides business listings for fruit, transport, and cold storage. We do not sell or deliver products. Please use the platform responsibly.",
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Disagree", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF33691E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("I Agree", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
    _timer?.cancel();
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
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accentLime, primaryLightGreen, secondaryDarkGreen],
              ),
            ),
          ),
          
          // Decorative Blurred Circle
          Positioned(
            top: -80, left: -80,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container()),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    const Text('Join Lolo Fruits', 
                      style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -2)),
                    const Text('Fruit & Logistic Connecting Platform', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 30),
                    
                    ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(30.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: secondaryDarkGreen, letterSpacing: -0.5)),
                              const SizedBox(height: 25),
                              
                              _buildInputLabel("Personal Details"),
                              CustomTextField(controller: _usernameController, hintText: "Username", prefixIcon: const Icon(Icons.person_rounded, color: primaryLightGreen, size: 22)),
                              const SizedBox(height: 14),
                              CustomTextField(controller: _emailController, hintText: "Email Address", prefixIcon: const Icon(Icons.alternate_email_rounded, color: primaryLightGreen, size: 22)),
                              const SizedBox(height: 14),
                              CustomTextField(
                                controller: _passwordController,
                                hintText: "Secure Password",
                                obscureText: !_showPassword,
                                prefixIcon: const Icon(Icons.lock_person_rounded, color: primaryLightGreen, size: 22),
                                suffixIcon: IconButton(
                                  icon: Icon(_showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.grey, size: 20),
                                  onPressed: () => setState(() => _showPassword = !_showPassword),
                                ),
                              ),
                              const SizedBox(height: 20),

                              _buildInputLabel("Mobile Verification"),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                ),
                                child: IntlPhoneField(
                                  controller: _phoneController,
                                  initialCountryCode: 'IN',
                                  dropdownIconPosition: IconPosition.trailing,
                                  flagsButtonPadding: const EdgeInsets.only(left: 12),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  decoration: const InputDecoration(
                                    hintText: 'Phone Number',
                                    border: InputBorder.none,
                                    counterText: '',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                  onChanged: (phone) {
                                    setState(() {
                                      _countryCode = phone.countryCode;
                                      _isPhoneVerified = false;
                                      _isOtpSent = false;
                                      _otpController.clear();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (!_isPhoneVerified) ...[
                                if (!_isOtpSent)
                                  _buildWideButton(
                                    onTap: sendOtp2Factor,
                                    text: 'GET VERIFICATION CODE',
                                    color: secondaryDarkGreen,
                                  )
                                else ...[
                                  CustomTextField(
                                    controller: _otpController, 
                                    hintText: "Enter 6-digit Code", 
                                    prefixIcon: const Icon(Icons.security_rounded, color: primaryLightGreen),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildWideButton(
                                    onTap: verifyOtp2Factor,
                                    text: 'VERIFY & CONTINUE',
                                    color: Colors.orange.shade900,
                                  ),
                                  Center(
                                    child: TextButton(
                                      onPressed: _canResend ? sendOtp2Factor : null,
                                      child: Text(
                                        _canResend ? "Resend Code" : "Resend available in ${_start}s",
                                        style: TextStyle(color: _canResend ? secondaryDarkGreen : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ] else 
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: primaryLightGreen, width: 1.5)
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.verified_user_rounded, color: secondaryDarkGreen, size: 24),
                                      SizedBox(width: 10),
                                      Text("Identity Verified", style: TextStyle(color: secondaryDarkGreen, fontWeight: FontWeight.w900, fontSize: 16)),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 10),
                              CheckboxListTile(
                                value: _agreedToTerms,
                                title: const Text("Accept legal terms and conditions", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
                                onChanged: (val) => setState(() => _agreedToTerms = val!),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: secondaryDarkGreen,
                                dense: true,
                              ),
                              
                              const SizedBox(height: 10),
                              _isLoading 
                                ? const Center(child: CircularProgressIndicator(color: secondaryDarkGreen, strokeWidth: 3))
                                : _buildWideButton(
                                    onTap: (_isPhoneVerified && _agreedToTerms) ? signUpUser : null,
                                    text: 'CREATE MY ACCOUNT',
                                    color: (_isPhoneVerified && _agreedToTerms) ? secondaryDarkGreen : Colors.grey.shade400,
                                  ),
                                  
                              const SizedBox(height: 20),
                              Center(
                                child: TextButton(
                                  onPressed: () async {
                                    final Uri url = Uri.parse('https://www.lolofruits.com/terms');
                                    if (!await launchUrl(url)) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
                                    }
                                  },
                                  child: const Text("View Legal Policy", style: TextStyle(color: secondaryDarkGreen, fontSize: 13, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.white, fontSize: 15),
                          children: [
                            TextSpan(text: "Already a member? "),
                            TextSpan(text: "Login Here", style: TextStyle(fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
                          ],
                        ),
                      ),
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

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildWideButton({required VoidCallback? onTap, required String text, required Color color}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: onTap == null ? 0 : 4,
          shadowColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ),
    );
  }
}