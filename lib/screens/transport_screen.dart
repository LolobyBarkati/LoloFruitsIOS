import 'dart:ui';
import 'package:barkati_frits/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class TransportScreen extends StatefulWidget {
  static const String routeName = '/transport';
  const TransportScreen({Key? key}) : super(key: key);

  @override
  _TransportScreenState createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  bool? isSubscribed;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkSubscriptionByEmail();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> checkSubscriptionByEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() => isSubscribed = false);
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection('payments')
        .where('email', isEqualTo: user.email)
        .get();

    if (query.docs.isEmpty) {
      setState(() => isSubscribed = false);
      return;
    }

    final data = query.docs.first.data();
    final Timestamp? expiry = data['subscription_expiry'];
    final bool status = data['status'] ?? false;

    if (expiry == null || expiry.toDate().isBefore(DateTime.now())) {
      await query.docs.first.reference.update({'status': false});
      setState(() => isSubscribed = false);
    } else {
      setState(() => isSubscribed = status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Make body extend behind AppBar
      appBar: AppBar(
        title: const Text('Transport', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Remove shadow
        iconTheme:
            const IconThemeData(color: Colors.white), // Set back arrow color
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background2.jpg', // Replace with your background image
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            // Add a blur effect
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              color: Colors.black
                  .withOpacity(0.3), // Adjust opacity for desired effect
            ),
          ),
          SafeArea(
            // Use SafeArea to avoid overlapping with system UI
            child: isSubscribed == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : isSubscribed == false
                    ? _buildUnsubscribedView(context)
                    : _buildSubscribedView(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsubscribedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: ClipRRect(
          // Use ClipRRect for rounded corners
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade100.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        Colors.white.withOpacity(0.2)), // Add a subtle border
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Unlock Transport Data",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors
                          .orange.shade900, // Darker orange for better contrast
                      shadows: [
                        Shadow(
                          blurRadius: 3.0,
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Subscribe to view detailed transport schedules and information.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5, // Add elevation for a raised effect
                    ),
                    child: const Text('Buy Subscription',
                        style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscribedView(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: _fromController,
                        decoration: InputDecoration(
                          labelText: 'From',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.5),
                        ),
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: _toController,
                        decoration: InputDecoration(
                          labelText: 'To',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.5),
                        ),
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
                    child: CircularProgressIndicator(color: Colors.white));
              }

              if (snapshot.hasError) {
                return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('No transport entries found.',
                        style: TextStyle(color: Colors.white)));
              }

              final fromText = _fromController.text.toLowerCase();
              final toText = _toController.text.toLowerCase();

              final filteredEntries = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final from = (data['from'] ?? '').toString().toLowerCase();
                final to = (data['to'] ?? '').toString().toLowerCase();
                return from.contains(fromText) && to.contains(toText);
              }).toList();

              if (filteredEntries.isEmpty) {
                return const Center(
                    child: Text('No matching transport found.',
                        style: TextStyle(color: Colors.white)));
              }

              return ListView.builder(
                itemCount: filteredEntries.length,
                padding: const EdgeInsets.only(
                    bottom: 16), // Add bottom padding for better spacing
                itemBuilder: (context, index) {
                  final data =
                      filteredEntries[index].data() as Map<String, dynamic>;
                  final timestamp = data['timestamp'] as Timestamp?;
                  final formattedDate = timestamp != null
                      ? DateFormat('dd MMM yyyy, hh:mm a')
                          .format(timestamp.toDate())
                      : 'N/A'; // Format timestamp

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 8, // Increased elevation
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: Colors.white.withOpacity(0.8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(
                          Icons.local_shipping,
                          color: Colors.blue,
                          size: 40,
                          shadows: [
                            Shadow(
                              blurRadius: 5.0,
                              color: Colors.black26,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        title: Text(
                          data['company'] ?? 'Unknown Company',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blueGrey,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data['from'] ?? 'N/A'} → ${data['to'] ?? 'N/A'}',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black87),
                            ),
                            Text(
                              'Date: $formattedDate', // Display formatted date
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(25)),
                            ),
                            backgroundColor: Colors.white,
                            isScrollControlled: true,
                            builder: (_) => TransportBottomSheet(data: data),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class TransportBottomSheet extends StatelessWidget {
  final Map<String, dynamic> data;

  const TransportBottomSheet({Key? key, required this.data}) : super(key: key);

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      debugPrint('Could not launch $phoneNumber');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? driverNumber = data['driver_number'];
    final List modes = data['modes'] is List ? data['modes'] : [];

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text(
                data['company'] ?? 'Unknown Company',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('From', data['from']),
              _buildDetailRow('To', data['to']),
              _buildDetailRow('Number', data['number']),
              _buildDetailRow('Driver Number', driverNumber),
              if (modes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Modes of Transport:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: modes
                      .map<Widget>((mode) => Chip(
                            label: Text(mode.toString()),
                            backgroundColor: Colors.blue.shade50,
                            labelStyle: const TextStyle(
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.w600),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _makePhoneCall(data['number'] ?? ''),
                icon: const Icon(Icons.call),
                label: const Text("Call Now", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
