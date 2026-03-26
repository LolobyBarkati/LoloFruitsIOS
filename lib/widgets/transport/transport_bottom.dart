import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barkati_frits/widgets/transport/similar_route.dart';

class TransportBottomSheet extends StatelessWidget {
  final String documentId;

  const TransportBottomSheet({Key? key, required this.documentId})
      : super(key: key);

  // Brand Colors
  final Color primaryGreen = const Color(0xFF80C031);
  final Color accentOrange = const Color(0xFFFFA000);

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
      initialChildSize: 0.7, // Increased for better first look
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('transport')
                .doc(documentId)
                .get(const GetOptions(source: Source.serverAndCache)), // Prefer server but allow cache
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: primaryGreen));
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
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 15),
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
                        // --- COMPANY HEADER ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                data['company'] ?? 'Lolo Transport',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryGreen.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.verified_user_rounded, color: primaryGreen, size: 20),
                            )
                          ],
                        ),
                        const SizedBox(height: 25),

                        // --- ROUTE VISUALIZER ---
                        _buildRouteTimeline(
                            data['from'] ?? 'N/A', data['to'] ?? 'N/A'),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(),
                        ),

                        // --- CONTACT INFO SECTION ---
                        _buildInfoTile(Icons.info_outline_rounded, "Office Contact",
                            data['number'] ?? 'N/A'),
                        _buildInfoTile(Icons.person_pin_circle_outlined, "Driver Assigned",
                            driverNumber ?? 'Not Assigned'),

                        // --- TRANSPORT MODES ---
                        if (modes.isNotEmpty) ...[
                          const SizedBox(height: 25),
                          Text(
                            'Vehicle Capacity/Modes',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: modes.map<Widget>((mode) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: primaryGreen.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: primaryGreen.withOpacity(0.2)),
                              ),
                              child: Text(
                                mode.toString(),
                                style: TextStyle(
                                    color: primaryGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                            )).toList(),
                          ),
                        ],

                        const SizedBox(height: 30),

                        // --- SIMILAR ROUTES SECTION ---
                        SimilarRoutesList(
                          currentDocId: documentId,
                          fromLocation: data['from'] ?? '',
                          toLocation: data['to'] ?? '',
                          onRouteTap: (newId) {
                            Navigator.pop(context);
                            // Brief delay to allow the previous sheet to close
                            Future.delayed(const Duration(milliseconds: 250), () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                                ),
                                backgroundColor: Colors.white,
                                isScrollControlled: true,
                                builder: (_) => TransportBottomSheet(documentId: newId),
                              );
                            });
                          },
                        ),

                        const SizedBox(height: 35),

                        // --- ACTION BUTTONS ---
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionBtn(
                                label: "Office",
                                icon: Icons.phone_in_talk_rounded,
                                color: primaryGreen,
                                onPressed: () => _makePhoneCall(officeNumber),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildActionBtn(
                                label: "Driver",
                                icon: Icons.person_search_rounded,
                                color: accentOrange,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildLocationRow(Icons.radio_button_checked, primaryGreen, "Pickup Location", from),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Container(height: 25, width: 2, color: Colors.grey.shade300),
          ),
          _buildLocationRow(Icons.location_on_rounded, accentOrange, "Drop Location", to),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100)),
            child: Icon(icon, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({required String label, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 15),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}