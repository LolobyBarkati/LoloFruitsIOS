import 'dart:ui';
// import 'package:barkati_frits/screens/phoneotp_screen.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barkati_frits/screens/faq_screen.dart';
// Import the PhoneotpScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;
  bool _isActive = false;
  DateTime? _expiryDate;
  String userName = "";
  String phoneNumber = "";
  List<Map<String, dynamic>> _subscriptionHistory = [];

  // Dummy transactions list (kept as it was, but will not be used by agent history button)
  // ignore: unused_field
  final List<Map<String, dynamic>> _transactions = [
    {
      'type': 'credit',
      'amount': 100,
      'date': DateTime.now().subtract(const Duration(days: 5))
    },
    {
      'type': 'debit',
      'amount': 50,
      'date': DateTime.now().subtract(const Duration(days: 10))
    },
    {
      'type': 'credit',
      'amount': 200,
      'date': DateTime.now().subtract(const Duration(days: 15))
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (snap.exists) {
        setState(() {
          userName = snap.data()?['email'] ?? "Unknown";
          phoneNumber = snap.data()?['contact']?.toString() ?? "Not Provided";
        });
      } else {
        setState(() {
          userName = 'Unknown';
          phoneNumber = 'Not Provided';
        });
      }
    } catch (e) {
      setState(() {
        userName = "Unknown";
        phoneNumber = "Error fetching contact";
      });
    }
  }

  Future<void> _loadSubscriptionData() async {
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('timestamp', descending: true)
          .get();

      if (snap.docs.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final activePayment = snap.docs.first;
      final expiry =
          (activePayment['subscription_expiry'] as Timestamp).toDate();
      final now = DateTime.now();

      setState(() {
        _isActive = expiry.isAfter(now);
        _expiryDate = expiry;

        _subscriptionHistory = snap.docs
            .map((doc) => {
                  'expiry': (doc['subscription_expiry'] as Timestamp).toDate(),
                  'date': (doc['timestamp'] as Timestamp).toDate()
                })
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }

  void _onLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/onboarding');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to submit feedback')),
      );
      return;
    }

    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback cannot be empty')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('App_feedbacks').add({
      'email': user!.email,
      'feedback': feedback,
      'timestamp': Timestamp.now(),
    });

    _feedbackController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback submitted successfully')),
    );
  }

  void _showSubscriptionHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.drag_handle, size: 32, color: Colors.grey),
              ),
              const Text(
                'Subscription History',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _subscriptionHistory.isEmpty
                    ? const Center(child: Text("No subscriptions found"))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _subscriptionHistory.length,
                        itemBuilder: (_, index) {
                          final item = _subscriptionHistory[index];
                          final expiry = item['expiry'] as DateTime;
                          final date = item['date'] as DateTime;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: const Icon(Icons.check_circle,
                                  color: Colors.green),
                              title: Text(
                                  'Subscribed on: ${date.day} ${_monthName(date.month)} ${date.year}'),
                              subtitle: Text(
                                  'Valid until: ${expiry.day} ${_monthName(expiry.month)} ${expiry.year}'),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onHelpSupportTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.drag_handle, size: 32, color: Colors.grey),
              ),
              const Text(
                'Help & Support',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone, color: Colors.blue),
                      title: const Text('Contact Support'),
                      subtitle: const Text('Call us at +91-9876543210'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final Uri phoneUri =
                            Uri(scheme: 'tel', path: '+919876543210');
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Unable to make call')),
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.orange),
                      title: const Text('Email Support'),
                      subtitle: const Text('support@example.com'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'support@example.com',
                          query: 'subject=App Support&body=Hi Support Team,',
                        );
                        if (await canLaunchUrl(emailUri)) {
                          await launchUrl(emailUri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Unable to open email app')),
                          );
                        }
                      },
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.info_outline, color: Colors.green),
                      title: const Text('FAQs'),
                      subtitle: const Text('Find answers to common questions'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(context, FAQScreen.routeName);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Renamed from _onAgentTap to _showSubscriptionPaymentHistory
  // This function will now display the subscription history
  void _showSubscriptionPaymentHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.drag_handle, size: 32, color: Colors.grey),
              ),
              const Text(
                'Subscription Payment History', // Changed title here
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _subscriptionHistory.isEmpty
                    ? const Center(
                        child: Text(
                            "No subscription payments found")) // Updated message
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _subscriptionHistory.length,
                        itemBuilder: (_, index) {
                          final item = _subscriptionHistory[index];
                          final expiry = item['expiry'] as DateTime;
                          final date = item['date'] as DateTime;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: const Icon(
                                  Icons
                                      .receipt_long, // Changed icon for payment history
                                  color: Colors.blueAccent),
                              title: Text(
                                  'Paid on: ${date.day} ${_monthName(date.month)} ${date.year}'), // Changed text
                              subtitle: Text(
                                  'Expires: ${expiry.day} ${_monthName(expiry.month)} ${expiry.year}'), // Changed text
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _onLogout(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                    child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        GestureDetector(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundImage: const AssetImage(
                                      'assets/icons/icon2.jpg'),
                                  radius: 30,
                                  backgroundColor: Colors.blue[700],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.email ?? 'No Email',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        phoneNumber.isNotEmpty
                                            ? phoneNumber
                                            : 'No Contact',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _isActive
                                                  ? 'Subscribed'
                                                  : 'Free Demo',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Valid till ',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: _expiryDate != null
                                              ? '${_expiryDate!.day} ${_monthName(_expiryDate!.month)}'
                                              : 'N/A',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: _menuButton(
                                    icon: Icons.shopping_bag_outlined,
                                    title: 'Your\nOrders',
                                    onTap: () =>
                                        _showSubscriptionHistory(context),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: _menuButton(
                                    icon: Icons.chat_bubble_outline,
                                    title: 'Help &\nSupport',
                                    onTap: () => _onHelpSupportTap(context),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: _menuButton(
                                    icon:
                                        Icons.receipt_long, // Changed icon here
                                    title:
                                        'Payment\nHistory', // Changed title here
                                    onTap: () =>
                                        _showSubscriptionPaymentHistory(
                                            context), // Call the new function
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                      ],
                    ),
                  ),
                ));
              },
            ),
    );
  }
}

Widget _menuButton(
    {required IconData icon,
    required String title,
    required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 5)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );
}
