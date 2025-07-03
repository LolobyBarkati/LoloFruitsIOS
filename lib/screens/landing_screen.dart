import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  static const routeName = '/landingscreen';
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0FFF4), Colors.white],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green,
              child: Icon(Icons.local_grocery_store, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              "Get your groceries\ndelivered to your home",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'ComicNeue',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "The best delivery app in town for\n"
              "delivering your daily fresh groceries",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(
                    context, '/explore'); // or home screen
              },
              child: const Text(
                "Explore Now",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Image.asset(
                'assets/landing_fruits.png', // Use a custom asset matching your layout
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
