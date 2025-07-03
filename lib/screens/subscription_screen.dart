import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class SubscriptionScreen extends StatefulWidget {
  static const String routeName = '/subscription';
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  late Razorpay _razorpay;
  bool _isActive = false;
  bool _isLoading = true;
  bool _wasExpired = false;
  DateTime? _expiryDate;

  // Placeholder for subscription plans if needed for dynamic pricing display
  // Currently, the prices are hardcoded in _openCheckout and _handlePaymentSuccess
  final List<Map<String, dynamic>> _plans = [
    {'name': 'Monthly', 'price': 499, 'description': 'Monthly Subscription'},
    {'name': 'Yearly', 'price': 4999, 'description': 'Yearly Subscription'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _checkPaymentStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _razorpay.clear();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPaymentStatus();
    }
  }

  Future<void> _checkPaymentStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isActive = false;
        _wasExpired = false;
        _isLoading = false;
      });
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
        setState(() {
          _isActive = false;
          _wasExpired = false;
          _isLoading = false;
        });
        return;
      }

      final data = snap.docs.first.data();
      final status = data['status'] as bool? ?? false;
      final expiryTimestamp = data['subscription_expiry'] as Timestamp?;

      final expiry = expiryTimestamp?.toDate();
      final isExpired = expiry == null || expiry.isBefore(DateTime.now());

      setState(() {
        _expiryDate = expiry;
        _isActive = status && !isExpired;
        _wasExpired = status && isExpired;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error checking subscription: $e");
      setState(() {
        _isActive = false;
        _wasExpired = false;
        _isLoading = false;
      });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    Fluttertoast.showToast(msg: "Payment Success: ${response.paymentId}");

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Determine the exact plan purchased based on the amount received from Razorpay
    // Assuming 49900 for monthly and 499900 for yearly based on your original code
    final int amountPaid = response.amount ?? 0; // Amount is in paise
    final bool isYearly = amountPaid == (_plans[1]['price'] * 100); // Check against yearly plan's paise amount

    final now = DateTime.now();
    final expiry = isYearly
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day); // Monthly vs Yearly expiry

    try {
      final snap = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        // 🔁 Update existing document
        final docId = snap.docs.first.id;
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(docId)
            .update({
          'paymentId': response.paymentId,
          'orderId': response.orderId,
          'subscription_date': now,
          'subscription_expiry': expiry,
          'amount': amountPaid, // Use actual amountPaid
          'timestamp': now,
          'status': true,
        });
      } else {
        // ➕ Create new document (first-time subscriber)
        await FirebaseFirestore.instance.collection('payments').add({
          'userId': user.uid,
          'email': user.email,
          'name': user.displayName ?? 'No Name',
          'paymentId': response.paymentId,
          'orderId': response.orderId,
          'subscription_date': now,
          'subscription_expiry': expiry,
          'amount': amountPaid, // Use actual amountPaid
          'timestamp': now,
          'status': true,
        });
      }

      Fluttertoast.showToast(msg: "Payment recorded!");
      setState(() {
        _isActive = true;
        _wasExpired = false;
        _expiryDate = expiry;
      });
      // A small delay to ensure Firestore has propagated changes before navigating
      await _checkPaymentStatus(); // Re-check status to be absolutely sure
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) { // Check if the widget is still mounted before navigating
           Navigator.of(context).pushReplacementNamed('/home');
        }
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to save payment: $e");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Fluttertoast.showToast(
      msg: "Payment Failed: ${response.code} - ${response.message}",
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Fluttertoast.showToast(msg: "External Wallet: ${response.walletName}");
  }

  void _openCheckout(bool isYearly) {
    // Ensure the amounts match the _plans list for consistency
    final int amountInPaise = isYearly ? _plans[1]['price'] * 100 : _plans[0]['price'] * 100;
    final String description = isYearly ? _plans[1]['description'] : _plans[0]['description'];

    var options = {
      'key': 'rzp_test_dUVpUl4p4r1uaG', // Replace with your actual key
      'amount': amountInPaise, // in paise
      'name': 'Barkati Fruits',
      'description': description,
      'prefill': {
        'contact': '9123456789', // Consider getting this from user profile
        'email': FirebaseAuth.instance.currentUser?.email ?? 'user@example.com', // Provide a fallback
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      Fluttertoast.showToast(msg: "Could not open payment gateway.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Subscription Plans',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop(); // Go back to the previous screen
          },
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/background.png', // Ensure this asset exists
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay for better readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          // Loading Indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            )
          else
            // Main Content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 80.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // App Logo/Icon (assuming 'assets/icons/icon2.jpg' is your app logo)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundImage: const AssetImage('assets/icons/icon2.jpg'),
                      radius: 60,
                      backgroundColor: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Current Subscription Status Card
                  _buildStatusCard(),
                  const SizedBox(height: 30),

                  // Features Section
                  _buildFeaturesSection(),
                  const SizedBox(height: 30),

                  // Subscription Options
                  if (!_isActive) ...[
                    _buildSubscriptionCard(
                      planName: _plans[0]['name'],
                      price: _plans[0]['price'],
                      description: 'Access to all premium features monthly.',
                      duration: 'per month',
                      onTap: () => _openCheckout(false),
                      isRecommended: false,
                    ),
                    const SizedBox(height: 20),
                    _buildSubscriptionCard(
                      planName: _plans[1]['name'],
                      price: _plans[1]['price'],
                      description: 'Save big with yearly subscription.',
                      duration: 'per year',
                      onTap: () => _openCheckout(true),
                      isRecommended: true,
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _isActive
                ? 'Your Subscription is Active!'
                : _wasExpired
                    ? 'Your Subscription Has Expired.'
                    : 'Unlock Premium Features',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _isActive ? Colors.greenAccent : Colors.redAccent,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_expiryDate != null)
            Text(
              _isActive
                  ? 'Active until: ${DateFormat('MMM dd, yyyy').format(_expiryDate!)}'
                  : 'Last expired: ${DateFormat('MMM dd, yyyy').format(_expiryDate!)}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            )
          else if (!_isActive)
            Text(
              'Subscribe now to enjoy exclusive benefits!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          const SizedBox(height: 20),
          if (!_isActive && _wasExpired)
            ElevatedButton(
              onPressed: () => _openCheckout(false), // Logic remains same
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 8,
              ),
              child: const Text(
                "Renew Monthly Subscription ₹499",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What you get:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          _buildFeatureItem('Unlock Transport Details', Icons.local_shipping),
          _buildFeatureItem('Unlock Cold Storage Access', Icons.ac_unit),
          _buildFeatureItem('Unlock Agent Services', Icons.support_agent),
          _buildFeatureItem('Exclusive Discounts', Icons.percent),
          _buildFeatureItem('Priority Customer Support', Icons.headset_mic),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard({
    required String planName,
    required int price,
    required String description,
    required String duration,
    required VoidCallback onTap,
    bool isRecommended = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isRecommended ? Colors.orangeAccent.shade400 : Colors.white.withOpacity(0.4),
            width: isRecommended ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isRecommended ? Colors.orangeAccent.withOpacity(0.4) : Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          gradient: isRecommended
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.shade700.withOpacity(0.8),
                    Colors.orange.shade900.withOpacity(0.8),
                  ],
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRecommended)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Recommended',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            Text(
              '$planName Plan',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isRecommended ? Colors.white : Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '₹$price',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isRecommended ? Colors.white : Colors.white,
              ),
            ),
            Text(
              duration,
              style: TextStyle(
                fontSize: 18,
                color: isRecommended ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: isRecommended ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 25),
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: isRecommended ? Colors.white : Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: isRecommended ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  isRecommended ? 'SUBSCRIBE NOW' : 'SELECT PLAN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isRecommended ? Colors.orange.shade800 : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on PaymentSuccessResponse {
  get amount => null;
}