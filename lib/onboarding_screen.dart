import 'package:flutter/material.dart';
import 'package:barkati_frits/screens/login_screen.dart';
import 'package:barkati_frits/screens/signup_screen.dart';
import 'package:barkati_frits/widgets/custom_button.dart';

class OnboardingScreen extends StatelessWidget {
  static const routeName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
          ),

          // Foreground content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome ! ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        onTap: () {
                          Navigator.pushNamed(context, LoginScreen.routeName);
                        },
                        text: 'Login',
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        onTap: () {
                          Navigator.pushNamed(context, SignupScreen.routeName);
                        },
                        text: 'Sign Up',
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
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
