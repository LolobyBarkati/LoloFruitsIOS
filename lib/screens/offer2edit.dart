import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/offer/offer_card.dart';
import '../widgets/offer/offer_details_sheet.dart';

class Offer2edit extends StatefulWidget {
  static const String routeName = '/offers';
  const Offer2edit({super.key});

  @override
  State<Offer2edit> createState() => _Offer2editState();
}

class _Offer2editState extends State<Offer2edit> {
  bool? _isSubscribed;
  bool _subCheckLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isSubscribed = false;
        _subCheckLoading = false;
      });
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      setState(() {
        _isSubscribed = false;
        _subCheckLoading = false;
      });
      return;
    }

    final data = query.docs.first.data();
    final Timestamp? expiry = data['subscription_expiry'];
    final bool status = data['status'] ?? false;

    if (expiry == null || expiry.toDate().isBefore(DateTime.now())) {
      setState(() {
        _isSubscribed = false;
        _subCheckLoading = false;
      });
    } else {
      setState(() {
        _isSubscribed = status;
        _subCheckLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const sectionColor = Color(0xFF2E7D32);

    if (_subCheckLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: sectionColor)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
        ),
        title: const Text(
          'Latest Offers',
          style: TextStyle(color: Color(0xFF1B3022), fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('offerdata')
            .doc('main')
            .collection('fruit')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active offers found.'));
          }
          final offers = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final data = offers[index].data() as Map<String, dynamic>? ?? {};
              return OfferCard(
                data: data,
                sectionColor: sectionColor,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => OfferDetailsSheet(
                    data: data,
                    isSubscribed: _isSubscribed ?? false,
                    sectionColor: sectionColor,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}