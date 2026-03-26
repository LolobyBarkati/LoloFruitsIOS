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
      child: SingleChildScrollView( // Added scrollability for smaller screens
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Minimalist Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (!isSubscribed) ...[
              _buildLockedState(context),
            ] else ...[
              // Header: Badge and Main Title
              Row(
                children: [
                  _buildBadge("CURRENT OFFER"),
                  const Spacer(),
                  Icon(Icons.verified_rounded, color: sectionColor, size: 20),
                  const SizedBox(width: 4),
                  Text("VERIFIED", style: TextStyle(color: sectionColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data['title'] ?? 'Fruit Offer',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Color(0xFF1A1A1A), letterSpacing: -0.8),
              ),
              const SizedBox(height: 20),

              // --- ORIGIN & DESCRIPTION SECTION ---
              _buildSectionTitle("Description & Origin"),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBF9), // Extremely subtle green tint
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 18, color: sectionColor),
                        const SizedBox(width: 8),
                        Text(
                          data['origin'] ?? 'Origin not specified',
                          style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                    if (data['description'] != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(thickness: 0.5),
                      ),
                      Text(
                        data['description'],
                        style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[700], fontWeight: FontWeight.w400),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- BUSINESS DETAILS SECTION ---
              _buildSectionTitle("Seller Information"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.storefront_rounded, "Company", data['companyName'] ?? 'Business Hidden'),
                    _buildDetailRow(Icons.person_pin_rounded, "Proprietor", data['ownerName'] ?? 'Manager'),
                    _buildDetailRow(Icons.payments_rounded, "Market Rate", data['rate'] ?? 'Ask for Price', isPrice: true),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // Call Action
              _buildPrimaryButton(
                label: "Connect with Seller",
                color: sectionColor,
                icon: Icons.phone_forwarded_rounded,
                onPressed: () async {
                  final url = Uri.parse('tel:${data['contact']}');
                  if (await canLaunchUrl(url)) await launchUrl(url);
                },
              ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  // --- SUB-WIDGETS FOR CLEANER UI ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: sectionColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: sectionColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildLockedState(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          height: 80, width: 80,
          decoration: BoxDecoration(color: sectionColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.lock_outline_rounded, size: 36, color: sectionColor),
        ),
        const SizedBox(height: 24),
        const Text("Subscribers Only", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Text(
          "Get instant access to wholesale rates, verified supplier contacts, and transportation logs.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(
          label: "Unlock Details",
          color: sectionColor,
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).pushNamed('/subscription');
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPrimaryButton({required String label, required Color color, IconData? icon, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isPrice ? sectionColor : const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}