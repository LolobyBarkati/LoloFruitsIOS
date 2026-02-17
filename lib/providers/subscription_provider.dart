import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SubscriptionController {
  // Razorpay integration removed. Will be replaced by Google Subscriptions.
  final Function(bool) onLoadingChanged;
  final VoidCallback onStateUpdate;
  final BuildContext context;

  bool isActive = false;
  bool wasExpired = false;
  DateTime? expiryDate;

  final List<Map<String, dynamic>> plans = [
    {
      'name': 'Monthly',
      'price': 499,
      'description': 'Access to all premium features monthly.'
    },
    {
      'name': 'Yearly',
      'price': 4999,
      'description': 'Save big with yearly subscription.'
    },
  ];

  SubscriptionController({
    required this.context,
    required this.onLoadingChanged,
    required this.onStateUpdate,
  });

  void init() {
    // Payment gateway integration temporarily disabled.
    checkPaymentStatus();
  }

  void dispose() {
    // nothing to dispose for now
  }

  Future<void> checkPaymentStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _updateStatus(active: false, expired: false, loading: false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _updateStatus(active: false, expired: false, loading: false);
        return;
      }

      final data = snap.docs.first.data();
      final status = data['status'] as bool? ?? false;
      final expiryTimestamp = data['subscription_expiry'] as Timestamp?;

      final expiry = expiryTimestamp?.toDate();
      final isExpired = expiry == null || expiry.isBefore(DateTime.now());

      expiryDate = expiry;
      isActive = status && !isExpired;
      wasExpired = status && isExpired;
      onLoadingChanged(false);
      onStateUpdate();
    } catch (e) {
      debugPrint("❌ Error: $e");
      onLoadingChanged(false);
    }
  }

  void openCheckout(bool isYearly) {
    // Razorpay removed. Use Google Subscriptions flow instead.
    Fluttertoast.showToast(msg: "Payment gateway not available. Coming soon.");
  }

  // Payment handlers removed. Will be implemented with Google Subscriptions.

  void _updateStatus(
      {required bool active, required bool expired, required bool loading}) {
    isActive = active;
    wasExpired = expired;
    onLoadingChanged(loading);
    onStateUpdate();
  }
}
