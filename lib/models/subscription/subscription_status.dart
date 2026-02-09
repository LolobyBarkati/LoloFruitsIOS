import 'package:barkati_frits/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionWrapper extends StatefulWidget {
  final Widget child;

  const SubscriptionWrapper({super.key, required this.child});

  @override
  State<SubscriptionWrapper> createState() => _SubscriptionWrapperState();
}

class _SubscriptionWrapperState extends State<SubscriptionWrapper> {
  DateTime? _lastCheckTime;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadLastCheckTime();
  }

  Future<void> _loadLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString('subscription_last_check');
    if (lastCheck != null) {
      setState(() {
        _lastCheckTime = DateTime.parse(lastCheck);
      });
    }
  }

  Future<void> _saveCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'subscription_last_check', DateTime.now().toIso8601String());
    setState(() {
      _lastCheckTime = DateTime.now();
    });
  }

  bool _shouldCheckSubscription() {
    if (_lastCheckTime == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_lastCheckTime!);
    return difference.inHours >= 24;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      return _buildPrompt(context, "Please Login",
          "You need to be logged in to access this data.");
    }

    // If it's time to check (24 hours passed), trigger a fresh check
    if (_shouldCheckSubscription() && !_isChecking) {
      _isChecking = true;
      _checkSubscriptionStatus(user.email!).then((_) {
        if (mounted) {
          _saveCheckTime();
          _isChecking = false;
        }
      });
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('email', isEqualTo: user.email)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        bool isSubscribed = false;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final Timestamp? expiry = data['subscription_expiry'];
          final bool status = data['status'] ?? false;

          // Check if status is true AND expiry date is in the future
          if (status &&
              expiry != null &&
              expiry.toDate().isAfter(DateTime.now())) {
            isSubscribed = true;
          }
        }

        if (isSubscribed) {
          return widget.child;
        } else {
          return _buildPrompt(
            context,
            "Access Exclusive Data",
            "Subscription unlocks agents details, direct contact information, and more.",
          );
        }
      },
    );
  }

  Future<void> _checkSubscriptionStatus(String email) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('payments')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return;

      final data = query.docs.first.data();
      final Timestamp? expiry = data['subscription_expiry'];
      final bool status = data['status'] ?? false;

      // If subscription is expired, update status in Firestore
      if (status &&
          (expiry == null || expiry.toDate().isBefore(DateTime.now()))) {
        await query.docs.first.reference.update({'status': false});
      }
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
    }
  }

  Widget _buildPrompt(BuildContext context, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 60, color: Colors.teal.shade400),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('View Subscription Plans',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
