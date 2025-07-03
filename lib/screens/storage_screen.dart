import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// Removed: import 'package:barkati_frits/screens/subscription_screen.dart';

class StorageScreen extends StatefulWidget {
  static const String routeName = '/storage';
  final String? initialStorageName; // New parameter

  const StorageScreen(
      {super.key, this.initialStorageName}); // Updated constructor

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  // Removed: bool? isSubscribed;
  final ScrollController _scrollController =
      ScrollController(); // New ScrollController

  @override
  void initState() {
    super.initState();
    // Removed: checkSubscriptionByEmail();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the controller
    super.dispose();
  }

  // Removed: checkSubscriptionByEmail function

  Future<void> _callOwner(String phone) async {
    final Uri callUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch phone dialer for $phone")),
      );
    }
  }

  Future<void> _openMap(String url) async {
    final Uri mapUri = Uri.parse(url);
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open map for $url")),
      );
    }
  }

  // Function to scroll to the specific item
  void _scrollToStorageItem(List<QueryDocumentSnapshot> docs) {
    if (widget.initialStorageName != null && _scrollController.hasClients) {
      final int index = docs.indexWhere((doc) =>
          (doc.data() as Map<String, dynamic>)['name'] ==
          widget.initialStorageName);

      if (index != -1) {
        // Ensure the list is built before attempting to scroll
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            index *
                (MediaQuery.of(context).size.width * 0.25 +
                    20), // Approximate item height + margin (adjust as needed)
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cold Storage'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.blueGrey[50],
      body: StreamBuilder<QuerySnapshot>(
        // Now always shows the StreamBuilder
        stream: FirebaseFirestore.instance
            .collection('cold storage')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No storage entries found.'));
          }

          final docs = snapshot.data!.docs;

          // Call _scrollToStorageItem after the first frame is rendered
          _scrollToStorageItem(docs);

          return ListView.builder(
            controller: _scrollController, // Assign the controller
            itemCount: docs.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'N/A';
              final price = data['price_per_week'] ?? 'N/A';
              final phone = data['director_number'] ?? '';
              final mapUrl = data['google_map_link'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Rates: ₹$price/week",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.call,
                              label: 'Call',
                              color: Colors.green[700]!,
                              onPressed: () => _callOwner(phone),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.picture_as_pdf,
                              label: 'Rate Sheet',
                              color: Colors.deepPurple[700]!,
                              onPressed: () async {
                                final fileUrl = data['file_url'] ?? '';
                                if (fileUrl.isNotEmpty) {
                                  final uri = Uri.parse(fileUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text("Could not open the PDF.")),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "No Rate Sheet PDF available.")),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.map,
                              label: 'Map',
                              color: Colors.blue[700]!,
                              onPressed: () => _openMap(mapUrl),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Removed: _buildSubscriptionPrompt method

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 3,
        textStyle: const TextStyle(fontSize: 14),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
