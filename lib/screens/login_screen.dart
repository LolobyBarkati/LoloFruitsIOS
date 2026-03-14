import 'package:barkati_frits/screens/fingerprintauth_screen.dart';
import 'package:flutter/material.dart';
import 'package:barkati_frits/widgets/custom_button.dart';
import 'package:barkati_frits/widgets/custom_textfield.dart';
import 'package:barkati_frits/resources/auth_methods.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthMethods _authMethods = AuthMethods();
  bool _isLoading = false;
  bool _showPassword = false;

  loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Color(0xFF689F38),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool res = await _authMethods.loginUser(
      context,
      _emailController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (res) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      bool hasAgreed = prefs.getBool('hasAgreedToScreenTerms') ?? false;

      if (!hasAgreed) {
        bool agreed = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text("Terms of Use", style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              "Screen Recording can obtain all sensitive information displayed on your screen or played by your device. "
              "You agree to use this feature legally and indemnify the provider.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Disagree", style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Agree", style: TextStyle(color: Color(0xFF689F38), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (!agreed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Agreement required to continue."), backgroundColor: Colors.red),
          );
          return;
        }
        await prefs.setBool('hasAgreedToScreenTerms', true);
      }

      Navigator.pushReplacementNamed(context, FingerprintAuthScreen.routeName);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Light Green Theme Colors
    const primaryLightGreen = Color(0xFF8BC34A);
    const secondaryDarkGreen = Color(0xFF33691E);
    const accentLime = Color(0xFFD4E157);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fresh Light Green Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  accentLime,
                  primaryLightGreen,
                  secondaryDarkGreen,
                ],
              ),
            ),
          ),
          
          // 2. Decorative Background Pattern
          Positioned(
            top: -50,
            left: -50,
            child: Opacity(
              opacity: 0.1,
              child: const Icon(Icons.eco_rounded, size: 300, color: Colors.white),
            ),
          ),

          // 3. Main Body
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Brand Identity
                  const Text(
                    'Lolo Fruits',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.0,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Login Form Glass Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(32.0),
                        width: size.width,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: secondaryDarkGreen,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please enter your credentials to login',
                              style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 35),
                            
                            // Email Input Field
                            CustomTextField(
                              controller: _emailController,
                              hintText: 'Email Address',
                              prefixIcon: const Icon(Icons.email_rounded, color: primaryLightGreen, size: 20),
                            ),
                            const SizedBox(height: 20),
                            
                            // Password Input Field
                            CustomTextField(
                              controller: _passwordController,
                              hintText: 'Password',
                              obscureText: !_showPassword,
                              prefixIcon: const Icon(Icons.vpn_key_rounded, color: primaryLightGreen, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _showPassword = !_showPassword),
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Sign In Button / Loading Indicator
                            _isLoading
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: CircularProgressIndicator(color: secondaryDarkGreen),
                                    ),
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: CustomButton(
                                      onTap: loginUser,
                                      text: 'SIGN IN',
                                      backgroundColor: secondaryDarkGreen,
                                      textColor: Colors.white,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // Navigation Link to Signup
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                    child: RichText(
                      text: TextSpan(
                        text: "New here? ",
                        style: const TextStyle(color: Colors.white70, fontSize: 15),
                        children: [
                          TextSpan(
                            text: "Create an Account",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}