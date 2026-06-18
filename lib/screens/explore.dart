import 'package:barkati_frits/widgets/agents/agents_list.dart';
import 'package:barkati_frits/widgets/appbar/appbar.dart';
import 'package:barkati_frits/widgets/banners/banners_slider.dart';
import 'package:barkati_frits/widgets/transport/transport.dart';
import 'package:flutter/material.dart';
import 'package:barkati_frits/widgets/cold_storage/home_cold_storage_widget.dart';
import 'package:barkati_frits/widgets/fruits/fruits_categories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExploreScreen2 extends StatefulWidget {
  static const String routeName = '/explore2';
  const ExploreScreen2({super.key});

  @override
  State<ExploreScreen2> createState() => _ExploreScreen2State();
}

class _ExploreScreen2State extends State<ExploreScreen2> {
  bool isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        
        // Check both common field names to be safe
        final rawExpiry = data['subscription_expiry'] ?? data['expiryDate'];

        if (rawExpiry is Timestamp) {
          final expiryDate = rawExpiry.toDate();
          if (mounted) {
            setState(() {
              isSubscribed = expiryDate.isAfter(DateTime.now());
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking subscription: $e");
      if (mounted) setState(() => isSubscribed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(isSubscribed: isSubscribed),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF7F8FA), Color(0xFFE3F0FF)],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const HomeBannerSlider(),
                const SizedBox(height: 12),
                const FruitsCategoriesWidget(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: const [
                      Expanded(child: HomeTransportBox()),
                      SizedBox(width: 14),
                      Expanded(child: HomeAgentBox()),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const HomeColdStorageWidget(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}