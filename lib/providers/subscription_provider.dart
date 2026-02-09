import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class SubscriptionController {
  final Razorpay _razorpay = Razorpay();
  final Function(bool) onLoadingChanged;
  final VoidCallback onStateUpdate;
  final BuildContext context;

  bool isActive = false;
  bool wasExpired = false;
  DateTime? expiryDate;

  final List<Map<String, dynamic>> plans = [
    {'name': 'Monthly', 'price': 499, 'description': 'Access to all premium features monthly.'},
    {'name': 'Yearly', 'price': 4999, 'description': 'Save big with yearly subscription.'},
  ];

  SubscriptionController({
    required this.context,
    required this.onLoadingChanged,
    required this.onStateUpdate,
  });

  void init() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    checkPaymentStatus();
  }

  void dispose() {
    _razorpay.clear();
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
    final int amount = isYearly ? plans[1]['price'] * 100 : plans[0]['price'] * 100;

    var options = {
      'key': 'rzp_test_dUVpUl4p4r1uaG', // Replace with your live key in production
      'amount': amount,
      'name': 'Barkati Fruits',
      'description': isYearly ? 'Yearly Subscription' : 'Monthly Subscription',
      'prefill': {
        'contact': '9123456789',
        'email': FirebaseAuth.instance.currentUser?.email ?? 'user@example.com',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      Fluttertoast.showToast(msg: "Gateway Error");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    // Simplified logic: calculating expiry based on common plan amounts
    // In production, verify this server-side via Razorpay API
    bool isYearly = plans[1]['price'] * 100 == (response as dynamic).amount; 
    final expiry = isYearly 
        ? DateTime(now.year + 1, now.month, now.day) 
        : DateTime(now.year, now.month + 1, now.day);

    try {
      await FirebaseFirestore.instance.collection('payments').add({
        'userId': user.uid,
        'email': user.email,
        'paymentId': response.paymentId,
        'subscription_date': now,
        'subscription_expiry': expiry,
        'status': true,
        'timestamp': now,
      });

      Fluttertoast.showToast(msg: "Success!");
      checkPaymentStatus();
      if (context.mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      Fluttertoast.showToast(msg: "Database Error");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(msg: "Payment Failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "External Wallet: ${response.walletName}");
  }

  void _updateStatus({required bool active, required bool expired, required bool loading}) {
    isActive = active;
    wasExpired = expired;
    onLoadingChanged(loading);
    onStateUpdate();
  }
}