import 'dart:ui';
import 'package:barkati_frits/models/subscription/subscription_status.dart';
import 'package:barkati_frits/widgets/transport/transport_bottom.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransportScreen extends StatefulWidget {
  static const String routeName = '/transport';
  const TransportScreen({Key? key}) : super(key: key);

  @override
  _TransportScreenState createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  // Brand Colors
  final Color primaryGreen = const Color(0xFF80C031);
  final Color accentOrange = const Color(0xFFFFA000);
  final Color scaffoldBg = const Color(0xFFF4F7F5); // Very light grey-green tint

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Transport Routes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SubscriptionWrapper(
        child: _buildSubscribedView(context),
      ),
    );
  }

  Widget _buildSubscribedView(BuildContext context) {
    return Column(
      children: [
        // --- CLEAN SEARCH SECTION ---
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Where are you shipping?",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildSearchField(_fromController, 'From', Icons.location_on_rounded)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.swap_horiz_rounded, color: primaryGreen.withOpacity(0.5)),
                    ),
                    Expanded(child: _buildSearchField(_toController, 'To', Icons.flag_rounded)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // --- LIST VIEW ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transport')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: primaryGreen));
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong.'));
              }

              final docs = snapshot.data?.docs ?? [];
              final fromText = _fromController.text.toLowerCase();
              final toText = _toController.text.toLowerCase();

              final filteredEntries = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final from = (data['from'] ?? '').toString().toLowerCase();
                final to = (data['to'] ?? '').toString().toLowerCase();
                return from.contains(fromText) && to.contains(toText);
              }).toList();

              if (filteredEntries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 50, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text('No routes found', style: TextStyle(color: Colors.grey[400])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredEntries.length,
                padding: const EdgeInsets.only(top: 15, bottom: 20),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final data = filteredEntries[index].data() as Map<String, dynamic>;
                  return _buildTransportCard(context, data, filteredEntries[index].id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryGreen, size: 18),
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildTransportCard(BuildContext context, Map<String, dynamic> data, String docId) {
    final double progress = ((data['progress'] ?? 50) / 100).toDouble().clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white), // Subtle touch
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Visual Indicator for Route
                Column(
                  children: [
                    Icon(Icons.radio_button_checked, size: 16, color: primaryGreen),
                    Container(width: 2, height: 30, color: Colors.grey[200]),
                    Icon(Icons.location_on, size: 16, color: accentOrange),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['company'] ?? 'Lolo Transport',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text("From: ${data['from'] ?? 'N/A'}", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      Text("To: ${data['to'] ?? 'N/A'}", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data['status'] ?? 'Active',
                    style: TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[100],
                      color: primaryGreen,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                      ),
                      backgroundColor: Colors.white,
                      isScrollControlled: true,
                      builder: (_) => TransportBottomSheet(documentId: docId),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: accentOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Details',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}