import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashDeciderScreen extends StatelessWidget {
  const SplashDeciderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 500), () {
        return FirebaseAuth.instance.currentUser;
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user != null) {
          // User is logged in → go to fingerprint auth
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/fingerprint-auth');
          });
        } else {
          // User is not logged in → go to login screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
        }

        return const SizedBox.shrink(); // Empty widget while waiting
      },
    );
  }
}
