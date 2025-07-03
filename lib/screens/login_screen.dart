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
  // ignore: unused_field
  bool _isLoading = false;
  bool _showPassword = false;

  loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Color(0xFF91B508),
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
        // Show terms dialog
        bool agreed = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Terms of Use for Screen Recording"),
            content: const SingleChildScrollView(
              child: Text(
                "Screen Recording can obtain all sensitive information displayed on your screen or played by your device, such as audio, passwords, payment info, and messages. "
                "You agree to use this feature legally and agree to indemnify the provider. This is for your personal use only.",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text("Disagree"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text("Agree"),
              ),
            ],
          ),
        );

        if (!agreed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You must agree to the terms to continue."),
              backgroundColor: Colors.red,
            ),
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  width: size.width * 0.85,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to continue!',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        hintText: 'Password',
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
                      const SizedBox(height: 24),
                      CustomButton(
                        onTap: loginUser,
                        text: 'LOGIN',
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
