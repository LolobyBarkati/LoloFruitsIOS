import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barkati_frits/screens/product_detail_screen.dart';
// import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class FruitPostsScreen extends StatelessWidget {
  final String fruitName;
  const FruitPostsScreen({super.key, required this.fruitName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$fruitName Posts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fruits')
            .doc(fruitName)
            .collection(fruitName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No posts found.'));
          }

          final posts = snapshot.data!.docs;

          // Sort posts by timestamp descending (recent first)
          posts.sort((a, b) {
            final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
            final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
            return bTime.compareTo(aTime);
          });

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final doc = posts[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['fruit_name'] ?? 'No Name';
              final country = data['country'] ?? 'Unknown';

              // Get timestamp and format it
              DateTime? postedTime;
              String dateTimeString = '';
              if (data['timestamp'] != null) {
                postedTime = (data['timestamp'] as Timestamp).toDate();
                dateTimeString =
                    DateFormat('d MMM yyyy, h:mm a').format(postedTime);
              }

              // ✅ Handle both single image (string) and list of images
              String imageUrl = '';
              if (data['image_urls'] != null &&
                  data['image_urls'] is List &&
                  data['image_urls'].isNotEmpty) {
                imageUrl = data['image_urls'][0];
              } else if (data['image_url'] != null &&
                  data['image_url'] is String) {
                imageUrl = data['image_url'];
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        fruitName: fruitName,
                        docId: doc.id,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : const AssetImage('assets/placeholder.jpg')
                              as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Add this widget for time at top right
                      if (dateTimeString.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dateTimeString,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              country,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
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
}
