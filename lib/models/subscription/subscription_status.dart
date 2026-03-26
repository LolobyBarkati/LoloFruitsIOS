import 'package:barkati_frits/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionWrapper extends StatelessWidget {
  final Widget child;

  const SubscriptionWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAF8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text("Please login to continue", 
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("payments")
          .where("userId", isEqualTo: user.uid)
          .orderBy("timestamp", descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF80C031)));
        }

        bool active = false;

        if (snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final expiry = (data["subscription_expiry"] as Timestamp).toDate();
          final status = data["status"] ?? false;

          if (status && expiry.isAfter(DateTime.now())) {
            active = true;
          }
        }

        if (active) {
          return child;
        }

        // --- IMPROVED UI FOR NON-SUBSCRIBED USERS ---
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          color: const Color(0xFFF8FAF8), // Matching your Agents Screen background
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Badge
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF80C031).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 64,
                  color: Color(0xFF80C031),
                ),
              ),
              const SizedBox(height: 32),
              
              // Text Content
              const Text(
                "Premium Access Required",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Gain full access to our verified global network, detailed rate sheets, and priority agent contacts.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Premium Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF80C031),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "View Subscription Plans",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Secondary Hint
              Text(
                "Safe & Secure Payments via Google Play",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}