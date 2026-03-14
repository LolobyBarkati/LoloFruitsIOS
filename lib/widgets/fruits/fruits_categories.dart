import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barkati_frits/screens/fruit_screen.dart';
import 'package:barkati_frits/screens/fruit_posts_screen.dart';
import 'package:barkati_frits/widgets/fruits/fruit_emoji.dart' show FruitIcon;

class FruitsCategoriesWidget extends StatefulWidget {
  const FruitsCategoriesWidget({super.key});

  @override
  State<FruitsCategoriesWidget> createState() => _FruitsCategoriesWidgetState();
}

class _FruitsCategoriesWidgetState extends State<FruitsCategoriesWidget> {
  final ScrollController _scrollController = ScrollController();

  String assetName(String name) =>
      name.trim().toLowerCase().replaceAll(' ', '');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fruit Categories',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: 'ComicNeue',
            ),
          ),
          const SizedBox(height: 16),

          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('fruits')
                .orderBy(FieldPath.documentId)
                .limit(10)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator()));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox(height: 50, child: Center(child: Text('No categories')));
              }

              final categories = snapshot.data!.docs;

              return SizedBox(
                height: 100, // Adjusted height to fit icon + text below
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final categoryName = category.id;
                    final data = category.data() as Map<String, dynamic>;
                    final bannerUrl = data['banner_url'] as String? ?? '';
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FruitPostsScreen(fruitName: categoryName),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[100],
                                border: Border.all(color: Colors.grey.shade200, width: 1),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: FruitIcon(fruitName: categoryName, size: 42, bannerUrl: bannerUrl),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 🔥 NAME BELOW ICON
                            SizedBox(
                              width: 65,
                              child: Text(
                                categoryName,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, FruitsScreen.routeName),
              style: TextButton.styleFrom(
                backgroundColor: Colors.lightGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'View All Categories ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}