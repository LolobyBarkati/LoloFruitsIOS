import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isActive = false; 
  List<Map<String, dynamic>> _subscriptionHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }

  Future<void> _loadSubscriptionData() async {
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('timestamp', descending: true)
          .get();

      if (snap.docs.isNotEmpty) {
        setState(() {
          _subscriptionHistory = snap.docs.map((doc) => {
            'expiry': (doc['subscription_expiry'] as Timestamp).toDate(),
            'date': (doc['timestamp'] as Timestamp).toDate()
          }).toList();
          
          final latestExpiry = _subscriptionHistory.first['expiry'] as DateTime;
          _isActive = latestExpiry.isAfter(DateTime.now());
        });
      }
    } catch (e) {
      debugPrint("Error loading subscription history: $e");
    }
  }

  // --- HELP & SUPPORT MODAL ---
  void _onHelpSupportTap(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              const Center(child: Icon(Icons.drag_handle, size: 32, color: Colors.grey)),
              const Text('Help & Support', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
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
                        final Uri phoneUri = Uri(scheme: 'tel', path: '+919876543210');
                        if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.email, color: Colors.orange),
                      title: const Text('Email Support'),
                      subtitle: const Text('support@example.com'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final Uri emailUri = Uri(scheme: 'mailto', path: 'support@example.com');
                        if (await canLaunchUrl(emailUri)) await launchUrl(emailUri);
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

  // --- TRANSACTION HISTORY MODAL ---
  void _showSubscriptionPaymentHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
              const Center(child: Icon(Icons.drag_handle, size: 32, color: Colors.grey)),
              const Text('Subscription Payment History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 16),
              Expanded(
                child: _subscriptionHistory.isEmpty
                    ? const Center(child: Text("No subscription payments found", style: TextStyle(color: Colors.black54)))
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
                              leading: const Icon(Icons.receipt_long, color: Colors.blueAccent),
                              title: Text('Paid on: ${date.day} ${_monthName(date.month)} ${date.year}'),
                              subtitle: Text('Expires: ${expiry.day} ${_monthName(expiry.month)} ${expiry.year}'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
      backgroundColor: const Color(0xFF0F172A), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildSubscriptionStatusCard(),
            const SizedBox(height: 32),
            _buildMenuSection(),
            const SizedBox(height: 40),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  // --- FIXED THIS SECTION TO AVOID RangeError ---
  Widget _buildProfileHeader() {
    String name = user?.displayName ?? "";
    String email = user?.email ?? "No Email";
    
    // Safety check: only use the first letter if the string is NOT empty
    String initial = "U"; 
    if (name.trim().isNotEmpty) {
      initial = name.trim()[0].toUpperCase();
    } else if (email.isNotEmpty && email != "No Email") {
      initial = email[0].toUpperCase();
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.amber.withOpacity(0.1),
          child: Text(initial, style: const TextStyle(fontSize: 32, color: Colors.amber, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Text(name.isNotEmpty ? name : "User", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(email, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
      ],
    );
  }

  Widget _buildSubscriptionStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(_isActive ? Icons.verified_user : Icons.stars_rounded, color: _isActive ? Colors.greenAccent : Colors.amber),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isActive ? "Premium Member" : "Free Plan", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(_isActive ? "Access to all features enabled" : "Upgrade for full access", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _menuItem(Icons.history, "Transaction History", "View your past payments", () => _showSubscriptionPaymentHistory(context)),
        _menuItem(Icons.help_outline, "Support & FAQ", "Get help with the app", () => _onHelpSupportTap(context)),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: () => FirebaseAuth.instance.signOut(),
      child: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
    );
  }
}