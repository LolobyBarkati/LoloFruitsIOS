import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:barkati_frits/widgets/fruits/fruit_emoji.dart';

class FruitPostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const FruitPostCard({super.key, required this.data, required this.onTap});

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp != null) {
      return DateFormat('d MMM, yyyy').format(timestamp.toDate());
    }
    return '';
  }

  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = data['fruit_name'] ?? 'No Name';
    final country = data['country'] ?? 'Unknown';
    final dateTimeString = _formatTimestamp(data['timestamp'] as Timestamp?);
    final emoji = fruitEmoji(name);

    // Media Logic
    String imageUrl = '';
    if (data['image_urls'] != null && data['image_urls'] is List && (data['image_urls'] as List).isNotEmpty) {
      imageUrl = data['image_urls'][0];
    } else if (data['image_url'] != null) {
      imageUrl = data['image_url'];
    }

    String? videoUrl = data['video_url'];
    String? videoThumb = data['video_thumbnail'];
    final mediaUrl = imageUrl.isNotEmpty ? imageUrl : videoThumb ?? videoUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade900.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Media Background
              Positioned.fill(
                child: mediaUrl != null
                    ? CachedNetworkImage(
                        imageUrl: mediaUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[100]),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF1F8E9),
                        child: Center(
                          child: Text(emoji, style: const TextStyle(fontSize: 52)),
                        ),
                      ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.5, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),

              // Video Badge
              if (videoUrl != null)
                Positioned(
                  bottom: 70,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                  ),
                ),

              // Date Badge
              if (dateTimeString.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dateTimeString,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              // Info Label
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _capitalizeFirstLetter(name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF8BC34A), size: 10),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              country,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}