import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barkati_frits/screens/fruit_screen.dart';
import 'package:barkati_frits/screens/fruit_posts_screen.dart';
import 'package:barkati_frits/widgets/fruits/fruit_emoji.dart' show FruitIcon;
import 'package:barkati_frits/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FruitsCategoriesWidget extends StatefulWidget {
  const FruitsCategoriesWidget({super.key});

  @override
  State<FruitsCategoriesWidget> createState() => _FruitsCategoriesWidgetState();
}

class _FruitsCategoriesWidgetState extends State<FruitsCategoriesWidget> {
  final ScrollController _scrollController = ScrollController();
  static const String _categoryCache = 'FRUIT_CATEGORIES_CACHE';
  static const String _categoryTimestamp = 'FRUIT_CATEGORIES_TIMESTAMP';

  String assetName(String name) =>
      name.trim().toLowerCase().replaceAll(' ', '');

  Future<List<QueryDocumentSnapshot>> _filterCategoriesWithPosts(
      List<QueryDocumentSnapshot> categories) async {
    final filtered = <QueryDocumentSnapshot>[];
    for (final category in categories) {
      final categoryName = category.id;
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('fruits')
          .doc(categoryName)
          .collection(categoryName)
          .limit(1)
          .get();
      if (postsSnapshot.docs.isNotEmpty) {
        filtered.add(category);
      }
    }
    await _cacheCategories(categories, filtered);
    return filtered;
  }

  Future<void> _cacheCategories(
    List<QueryDocumentSnapshot> allCategories,
    List<QueryDocumentSnapshot> filteredCategories,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allData = allCategories
          .map((doc) => {
                'id': doc.id,
                'banner_url': (doc.data() as Map<String, dynamic>)['banner_url'] ?? '',
              })
          .toList();
      final filteredIds =
          filteredCategories.map((doc) => doc.id).toList();

      await prefs.setString(_categoryCache, jsonEncode({
        'all': allData,
        'filtered': filteredIds,
      }));
      await prefs.setInt(
        _categoryTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Cache error: $e');
    }
  }

  Future<List<String>?> _loadCachedFilteredCategoryIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_categoryCache);
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        return List<String>.from(data['filtered'] ?? []);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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

              return FutureBuilder<List<QueryDocumentSnapshot>>(
                future: _filterCategoriesWithPosts(categories),
                builder: (context, filteredSnapshot) {
                  if (filteredSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator()));
                  }

                  if (!filteredSnapshot.hasData || filteredSnapshot.data!.isEmpty) {
                    return const SizedBox(height: 50, child: Center(child: Text('No fruits available')));
                  }

                  final filteredCategories = filteredSnapshot.data!;

                  return SizedBox(
                    height: 100,
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];
                        final categoryName = category.id;
                        final displayName = categoryName.toLowerCase() == 'exotic fruits'
                            ? 'Other Fruits'
                            : categoryName;
                        final data = category.data() as Map<String, dynamic>;
                        final bannerUrl = data['banner_url'] as String? ?? '';
                        return GestureDetector(
                          onTap: () {
                            if (FirebaseAuth.instance.currentUser == null) {
                              showLoginRequired(context);
                              return;
                            }
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
                                SizedBox(
                                  width: 65,
                                  child: Text(
                                    displayName,
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
              );
            },
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                if (FirebaseAuth.instance.currentUser == null) {
                  showLoginRequired(context);
                  return;
                }
                Navigator.pushNamed(context, FruitsScreen.routeName);
              },
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