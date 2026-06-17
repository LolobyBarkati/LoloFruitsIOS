import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barkati_frits/screens/login_screen.dart';
import 'package:barkati_frits/screens/signup_screen.dart';
import 'package:barkati_frits/screens/home_screen.dart';
import 'package:barkati_frits/widgets/custom_button.dart';

class OnboardingScreen extends StatelessWidget {
  static const routeName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Updated Light Green Multi-tone Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFFDCEDC8), // Very Light Green
                  Color(0xFF8BC34A), // Vibrant Light Green
                  Color(0xFF689F38), // Natural Leaf Green
                ],
              ),
            ),
          ),

          // 2. Decorative Logistic Overlay (Abstract Connectivity)
          Positioned(
            top: -100,
            left: -50,
            child: Opacity(
              opacity: 0.07,
              child: Icon(
                Icons.language_rounded, // Global Logistic Reach
                size: 400,
                color: Colors.white,
              ),
            ),
          ),

          // 3. Foreground content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Badge / Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'LOGISTICS CONNECTING PLATFORM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Brand Name
                  const Text(
                    'Lolo Fruits',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 52,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: -2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Value Proposition
                  Text(
                    'Direct access to the fruit market.\nFast logistics, reliable service.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Primary Action: Login
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onTap: () {
                        Navigator.pushNamed(context, LoginScreen.routeName);
                      },
                      text: 'Login',
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Secondary Action: Create Account
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      onTap: () {
                        Navigator.pushNamed(context, SignupScreen.routeName);
                      },
                      text: 'Join the Marketplace',
                      backgroundColor: Colors.white.withOpacity(0.1),
                      textColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signInAnonymously();
                        if (context.mounted) {
                          Navigator.pushNamed(context, HomeScreen.routeName);
                        }
                      },
                      child: const Text(
                        'Browse without signing in',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse('https://www.lolofruits.com/privacy-policy')),
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white60,
                          ),
                        ),
                      ),
                      const Text('  ·  ', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse('https://www.lolofruits.com/terms')),
                        child: const Text(
                          'Terms of Use',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white60,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}