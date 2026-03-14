import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OfferDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isSubscribed;
  final Color sectionColor;

  const OfferDetailsSheet({
    super.key,
    required this.data,
    required this.isSubscribed,
    required this.sectionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(child: Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 30),
          if (!isSubscribed) ...[
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: sectionColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.lock_rounded, size: 40, color: sectionColor),
              ),
            ),
            const SizedBox(height: 24),
            const Center(child: Text("Member Exclusive", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5))),
            const SizedBox(height: 12),
            const Text(
              "Detailed pricing, seller contact information, and origin records are only available to subscribed members.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: sectionColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/subscription');
                },
                child: const Text("Unlock Now", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ] else ...[
            Text(data['title'] ?? 'Offer Details', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: Color(0xFF1B3022), letterSpacing: -0.5)),
            const SizedBox(height: 25),
            if (data['description'] != null) ...[
              Text(data['description'], style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
              const SizedBox(height: 25),
            ],
            _buildDetailRow(Icons.business_center_rounded, "Company", data['companyName'] ?? 'Not Provided'),
            _buildDetailRow(Icons.location_on_rounded, "Origin", data['origin'] ?? 'Not Provided'),
            _buildDetailRow(Icons.account_circle_rounded, "Owner", data['ownerName'] ?? 'Not Provided'),
            _buildDetailRow(Icons.monetization_on_rounded, "Current Rate", data['rate'] ?? 'Negotiable', isBold: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone_enabled_rounded, color: Colors.white),
                label: const Text("Call Seller", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: sectionColor, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                  shadowColor: sectionColor.withOpacity(0.4),
                ),
                onPressed: () async {
                  final url = Uri.parse('tel:${data['contact']}');
                  if (await canLaunchUrl(url)) await launchUrl(url);
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF1F4F2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 22, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 17, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}