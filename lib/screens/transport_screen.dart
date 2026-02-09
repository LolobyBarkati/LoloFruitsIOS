import 'dart:ui';
import 'package:barkati_frits/screens/subscription_screen.dart';
import 'package:barkati_frits/models/subscription/subscription_status.dart';
import 'package:barkati_frits/widgets/transport/transport_bottom.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransportScreen extends StatefulWidget {
  static const String routeName = '/transport';
  const TransportScreen({Key? key}) : super(key: key);

  @override
  _TransportScreenState createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Transport',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightGreen,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F8FA), Color(0xFFE3F0FF)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: SubscriptionWrapper(
          child: _buildSubscribedView(context),
        ),
      ),
    );
  }

  Widget _buildSubscribedView(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Routes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSearchField(_fromController, 'From'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSearchField(_toController, 'To'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transport')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.blue));
              }

              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)));
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
                return const Center(
                    child: Text('No matching transport found.',
                        style: TextStyle(color: Colors.black54)));
              }

              return ListView.builder(
                itemCount: filteredEntries.length,
                padding: const EdgeInsets.only(bottom: 16),
                itemBuilder: (context, index) {
                  final data =
                      filteredEntries[index].data() as Map<String, dynamic>;
                  final timestamp = data['timestamp'] as Timestamp?;

                  return _buildTransportCard(
                      context, data, filteredEntries[index].id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(TextEditingController controller, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.white.withOpacity(0.5),
            ),
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildTransportCard(
      BuildContext context, Map<String, dynamic> data, String docId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.directions_bus,
                      color: Colors.blue, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['company'] ?? 'Unknown Company',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 8),
                        Text('From: ${data['from'] ?? 'N/A'}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text('To: ${data['to'] ?? 'N/A'}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['status'] ?? 'Active',
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.grey[300],
                        ),
                        child: FractionallySizedBox(
                          widthFactor:
                              ((data['progress'] ?? 50) / 100).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(25)),
                        ),
                        backgroundColor: Colors.white,
                        isScrollControlled: true,
                        builder: (_) => TransportBottomSheet(documentId: docId),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('View Details',
                        style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
