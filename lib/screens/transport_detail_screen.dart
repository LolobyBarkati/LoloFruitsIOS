import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TransportDetailScreen extends StatelessWidget {
  static const String routeName = '/transportdetails';
  final Map<String, dynamic> entry;

  const TransportDetailScreen({super.key, required this.entry});

  // Brand Colors
  final Color primaryGreen = const Color(0xFF80C031);
  final Color accentOrange = const Color(0xFFFFA000);
  final Color scaffoldBg = const Color(0xFFF4F7F5);

  Future<void> _makeCall(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
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
          "Shipment Summary",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- TOP INFO CARD ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Company Icon & Name
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.local_shipping_rounded, color: primaryGreen, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    entry['company']?.toUpperCase() ?? 'UNKNOWN COMPANY',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Vehicle No: ${entry['number'] ?? 'N/A'}",
                    style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),

                  // --- ROUTE TIMELINE ---
                  Row(
                    children: [
                      Column(
                        children: [
                          Icon(Icons.radio_button_checked, color: primaryGreen, size: 20),
                          Container(width: 2, height: 40, color: Colors.grey.shade200),
                          Icon(Icons.location_on, color: accentOrange, size: 20),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("PICKUP POINT", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text(entry['from'] ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 25),
                            const Text("DELIVERY POINT", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text(entry['to'] ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),

            // --- ACTION BUTTONS ---
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => _makeCall(entry['number'] ?? ''),
                icon: const Icon(Icons.call_rounded, color: Colors.white),
                label: const Text(
                  "CALL TRANSPORTER",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Helpful Tip
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: accentOrange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Please contact the driver for real-time location updates.",
                      style: TextStyle(color: accentOrange.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}