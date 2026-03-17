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
      return const Center(child: Text("Please login"));
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
          return const Center(child: CircularProgressIndicator());
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

        return Center(
          child: ElevatedButton(
            child: const Text("View Subscription Plans"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}