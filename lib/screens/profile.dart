import 'package:barkati_frits/screens/faq_screen.dart';
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
                'date': (doc['timestamp'] as Timestamp).toDate(),
                'paymentId': doc['paymentId'] ?? 'N/A',
                'plan': doc['plan'] ?? 'monthly',
              }).toList();

          final latestExpiry = _subscriptionHistory.first['expiry'] as DateTime;
          _isActive = latestExpiry.isAfter(DateTime.now());
        });
      }
    } catch (e) {
      debugPrint("Error loading subscription history: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using LayoutBuilder to ensure we can calculate heights if needed
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Profile", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      // SafeArea prevents content from being cut off by notches or system bars
      body: SafeArea(
        child: SingleChildScrollView(
          // BouncingScrollPhysics makes it feel premium on Pixel/Android
          physics: const BouncingScrollPhysics(),
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
              if (user?.isAnonymous == false) _buildLogoutButton(),
              // Added bottom padding to ensure the logout button isn't touching the edge
              const SizedBox(height: 40), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    String email = user?.email ?? "No Email";
    String initial = email.isNotEmpty ? email[0].toUpperCase() : "U";

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.amber.withOpacity(0.1),
            child: Text(initial, 
              style: const TextStyle(fontSize: 32, color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        Text(email, 
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSubscriptionStatusCard() {
    return InkWell(
      onTap: _isActive ? null : () => Navigator.pushNamed(context, '/subscription'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (_isActive ? Colors.greenAccent : Colors.amber).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_isActive ? Icons.verified_user : Icons.stars_rounded, 
                  color: _isActive ? Colors.greenAccent : Colors.amber),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isActive ? "Premium Member" : "Free Plan", 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(_isActive ? "Access enabled" : "Upgrade for full access", 
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                ],
              ),
            ),
            if (!_isActive) const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _menuItem(Icons.history, "Transaction History", "View past payments",
              () => _showSubscriptionPaymentHistory(context)),
          _menuItem(Icons.help_outline, "Support & FAQ", "Get help",
              () => _onHelpSupportTap(context)),
          _menuItem(Icons.privacy_tip_outlined, "Privacy Policy", "Data handling", () async {
            final Uri url = Uri.parse('https://www.lolofruits.com/privacy-policy');
            if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
          }),
          _menuItem(Icons.gavel_outlined, "Terms", "Service terms", () async {
            final Uri url = Uri.parse('https://www.lolofruits.com/terms');
            if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
          }),
          if (user != null && !user.isAnonymous)
            _menuItemDestructive(Icons.delete_forever_outlined, "Delete Account", "Permanently remove your data",
                () => _confirmDeleteAccount(context)),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 14),
    );
  }

  void _onHelpSupportTap(BuildContext context) {
    _showCustomBottomSheet(
      context,
      'Help & Support',
      [
        _bottomSheetTile(Icons.phone, Colors.blue, 'Contact Support', '+91-85914 56683', () async {
          final Uri phoneUri = Uri(scheme: 'tel', path: '++918591456683');
          if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
        }),
        _bottomSheetTile(Icons.email, Colors.orange, 'Email Support', 'lolobybarkati@gmail.com', () async {
          final Uri emailUri = Uri(scheme: 'mailto', path: 'lolobybarkati@gmail.com');
          if (await canLaunchUrl(emailUri)) await launchUrl(emailUri);
        }),
        _bottomSheetTile(Icons.info_outline, Colors.green, 'FAQs', 'Common questions', () {
          Navigator.pop(context);
          Navigator.pushNamed(context, FAQScreen.routeName);
        }),
      ],
    );
  }

  void _showSubscriptionPaymentHistory(BuildContext context) {
    _showCustomBottomSheet(
      context,
      'Payment History',
      _subscriptionHistory.isEmpty
          ? [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No payments found")))]
          : _subscriptionHistory.map((item) {
              final expiry = item['expiry'] as DateTime;
              final date = item['date'] as DateTime;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Plan Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                        Text('PAID', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Date: ${date.day} ${_monthName(date.month)} ${date.year}', style: const TextStyle(color: Colors.black54)),
                    Text('Expires: ${expiry.day} ${_monthName(expiry.month)} ${expiry.year}', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              );
            }).toList(),
    );
  }

  void _showCustomBottomSheet(BuildContext context, String title, List<Widget> children) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        // Constrain height to 75% of screen to prevent bottom sheet overflow
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: SingleChildScrollView( // Wrap children in scrollview for small Pixels
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),
              ...children,
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomSheetTile(IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  Widget _menuItemDestructive(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.redAccent, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.5), fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.redAccent, size: 14),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "This will permanently delete your account and all associated data including subscription history. This action cannot be undone.",
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
    );

    try {
      final db = FirebaseFirestore.instance;
      final uid = currentUser.uid;

      // Delete all payment records
      final payments = await db.collection('payments').where('userId', isEqualTo: uid).get();
      for (final doc in payments.docs) {
        await doc.reference.delete();
      }

      // Delete user profile document
      await db.collection('users').doc(uid).delete();

      // Delete Firebase Auth account
      await currentUser.delete();

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (_) => false);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading

      if (e.code == 'requires-recent-login') {
        // Session too old — ask user to log in again first
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text("Re-login Required", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text(
              "For security, please log out and log back in before deleting your account.",
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK", style: TextStyle(color: Colors.amber)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Log Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Log out from Lolo Fruits?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: _confirmLogout,
      child: const Text("Log Out Account", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}