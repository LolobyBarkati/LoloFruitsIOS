import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'video_preview.dart';

class OfferCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color sectionColor;
  final VoidCallback onTap;

  const OfferCard({
    super.key,
    required this.data,
    required this.sectionColor,
    required this.onTap,
  });

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final files = (data['files'] as List<dynamic>?) ?? [];
    final postedAt = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now();
    final title = data['title']?.toString() ?? 'Special Offer';
    final filesForCard = files.where((file) => file is Map<String, dynamic> && (file['type'] != 'pdf')).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: GestureDetector(
                  onTap: onTap,
                  child: SizedBox(
                    height: 320,
                    width: double.infinity,
                    child: filesForCard.isNotEmpty
                        ? PageView.builder(
                            itemCount: filesForCard.length,
                            itemBuilder: (context, index) {
                              final file = filesForCard[index];
                              if (file['type'] == 'video') {
                                return VideoPreview(url: file['url']);
                              }
                              return Image.network(file['url'], fit: BoxFit.cover);
                            },
                          )
                        : Container(color: Colors.green[50], child: const Icon(Icons.image_outlined, size: 48, color: Colors.green)),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE64A19),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text("LIMITED OFFER", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(30)),
                  child: Text(_getTimeAgo(postedAt), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: Color(0xFF1B3022))),
                        const SizedBox(height: 4),
                        Text("Tap to view pricing & contact", style: TextStyle(color: sectionColor, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}