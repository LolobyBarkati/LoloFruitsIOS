import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:barkati_frits/screens/fruit_posts_screen.dart';
import 'package:barkati_frits/widgets/fruits/fruit_emoji.dart' show FruitIcon;
import 'package:barkati_frits/utils/utils.dart';

class FruitsScreen extends StatefulWidget {
  static const String routeName = '/fruits';
  const FruitsScreen({super.key});

  @override
  State<FruitsScreen> createState() => _FruitsScreenState();
}

class _FruitsScreenState extends State<FruitsScreen> {
  String _searchQuery = '';

  String _cap(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  // Returns only fruits that have at least one post in their subcollection.
  Stream<List<QueryDocumentSnapshot>> get _fruitsStream {
    return FirebaseFirestore.instance
        .collection('fruits')
        .orderBy(FieldPath.documentId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return [];
      final checks = await Future.wait(
        snapshot.docs.map((doc) => FirebaseFirestore.instance
            .collection('fruits')
            .doc(doc.id)
            .collection(doc.id)
            .limit(1)
            .get()),
      );
      return [
        for (int i = 0; i < snapshot.docs.length; i++)
          if (checks[i].docs.isNotEmpty) snapshot.docs[i],
      ];
    });
  }

  // Returns only exotic fruits that have at least one post.
  Stream<List<QueryDocumentSnapshot>> get _exoticFruitsStream {
    return FirebaseFirestore.instance
        .collection('exotic_fruits')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return [];
      final names = snapshot.docs.map((doc) {
        return ((doc.data() as Map)['name'] as String?) ?? doc.id;
      }).toList();
      final checks = await Future.wait(
        names.map((name) => FirebaseFirestore.instance
            .collection('fruits')
            .doc(name)
            .collection(name)
            .limit(1)
            .get()),
      );
      return [
        for (int i = 0; i < snapshot.docs.length; i++)
          if (checks[i].docs.isNotEmpty) snapshot.docs[i],
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text(
          'Fruits Market',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8BC34A), Color(0xFF689F38)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search fresh fruits...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF689F38)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // Other Fruits — hidden when all are empty
          StreamBuilder<List<QueryDocumentSnapshot>>(
            stream: _exoticFruitsStream,
            builder: (context, snapshot) {
              final exotics = snapshot.data ?? [];
              if (exotics.isEmpty) return const SizedBox();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 16, 12),
                    child: Row(
                      children: [
                        const Text(
                          'Other Fruits',
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.stars, size: 16, color: Colors.orange.shade700),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: exotics.length,
                      itemBuilder: (context, index) {
                        final d = exotics[index].data() as Map<String, dynamic>;
                        final name = d['name'] as String? ?? exotics[index].id;
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FruitPostsScreen(fruitName: name),
                            ),
                          ),
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange.shade200, Colors.orange.shade300],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: Opacity(
                                    opacity: 0.35,
                                    child: FruitIcon(fruitName: name, size: 56),
                                  ),
                                ),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      _cap(name),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF5D4037),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          // Fruits grid — header and grid together so header hides with it
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: _fruitsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF689F38)),
                  );
                }

                final isGuest = isGuestUser();
                final allFruits = snapshot.data ?? [];
                final filtered = allFruits.where((f) {
                  return _searchQuery.isEmpty ||
                      f.id.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No fruits found.',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final totalCount = filtered.length;

                return CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(18, 24, 16, 8),
                        child: Text(
                          'Fruits',
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final fruit = filtered[index];
                            final fruitName = fruit.id;
                            final fruitData =
                                fruit.data() as Map<String, dynamic>;
                            final bannerUrl =
                                fruitData['banner_url'] as String? ?? '';

                            final isBlurred = isGuest && index >= 4;

                            final card = ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.green.shade50, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade900.withOpacity(0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: -15,
                                      left: -15,
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.green.shade50.withOpacity(0.3),
                                      ),
                                    ),
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          FruitIcon(fruitName: fruitName, size: 52, bannerUrl: bannerUrl),
                                          const SizedBox(height: 10),
                                          Text(
                                            _cap(fruitName),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (isBlurred) {
                              return GestureDetector(
                                onTap: () => showLoginRequired(context),
                                child: Stack(
                                  children: [
                                    ImageFiltered(
                                      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                      child: card,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.lock_outline_rounded, size: 28, color: Colors.grey.shade600),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Sign in\nto see',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FruitPostsScreen(fruitName: fruitName),
                                ),
                              ),
                              child: card,
                            );
                          },
                          childCount: totalCount,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}