import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barkati_frits/widgets/transport/similar_route.dart';

class TransportBottomSheet extends StatelessWidget {
  final String documentId;

  const TransportBottomSheet({Key? key, required this.documentId})
      : super(key: key);

  void _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('transport')
                .doc(documentId)
                .get(const GetOptions(source: Source.cache)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.orange));
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("Details not found."));
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final String? driverNumber = data['driver_number'];
              final String? officeNumber = data['number'];
              final List modes = data['modes'] is List ? data['modes'] : [];

              return Column(
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      children: [
                        // Company Header
                        Text(
                          data['company'] ?? 'Unknown Company',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Route Timeline Style
                        _buildRouteTimeline(
                            data['from'] ?? 'N/A', data['to'] ?? 'N/A'),

                        const Divider(height: 40),

                        // Details Grid/List
                        _buildInfoTile(Icons.tag, "Transporter Number",
                            data['number'] ?? 'N/A'),
                        _buildInfoTile(Icons.person_outline, "Driver Contact",
                            driverNumber ?? 'N/A'),

                        if (modes.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Modes of Transport',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: modes
                                .map<Widget>((mode) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.blue.shade100),
                                      ),
                                      child: Text(
                                        mode.toString(),
                                        style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],

                        const Divider(height: 40),

                        // Similar Routes
                        SimilarRoutesList(
                          currentDocId: documentId,
                          fromLocation: data['from'] ?? '',
                          toLocation: data['to'] ?? '',
                          onRouteTap: (newId) {
                            Navigator.pop(context);
                            Future.delayed(const Duration(milliseconds: 200),
                                () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(25)),
                                ),
                                backgroundColor: Colors.white,
                                isScrollControlled: true,
                                builder: (_) =>
                                    TransportBottomSheet(documentId: newId),
                              );
                            });
                          },
                        ),

                        const SizedBox(height: 30),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionBtn(
                                label: "Call Transporter",
                                icon: Icons.phone,
                                color: Colors.blue,
                                onPressed: () => _makePhoneCall(officeNumber),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionBtn(
                                label: "Call Driver",
                                icon: Icons.person,
                                color: Colors.green,
                                onPressed: () => _makePhoneCall(driverNumber),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRouteTimeline(String from, String to) {
    return Column(
      children: [
        _buildLocationRow(
            Icons.radio_button_checked, Colors.green, "Origin", from),
        Padding(
          padding: const EdgeInsets.only(left: 11),
          child: Container(
            height: 30,
            width: 2,
            color: Colors.grey[300],
          ),
        ),
        _buildLocationRow(
            Icons.location_on, Colors.redAccent, "Destination", to),
      ],
    );
  }

  Widget _buildLocationRow(
      IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        )
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.blueGrey, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
