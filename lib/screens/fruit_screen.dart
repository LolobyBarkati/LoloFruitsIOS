import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:barkati_frits/screens/fruit_posts_screen.dart';

class FruitsScreen extends StatefulWidget {
  static const String routeName = '/fruits';
  const FruitsScreen({super.key});

  @override
  State<FruitsScreen> createState() => _FruitsScreenState();
}

class _FruitsScreenState extends State<FruitsScreen> {
  String _searchQuery = '';

  // Utility: Lowercase and remove spaces for asset matching
  String assetName(String name) =>
      name.trim().toLowerCase().replaceAll(' ', '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Fruits'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search fruits...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          // Exotic Fruits Section (assets only)
          FutureBuilder<QuerySnapshot>(
            future:
                FirebaseFirestore.instance.collection('exotic_fruits').get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 0);
              }
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Error loading exotic fruits',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox();
              }
              final exotics = snapshot.data!.docs;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'EXOTIC FRUITS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 2,
                            color: Colors.black26,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: exotics.length,
                      itemBuilder: (context, index) {
                        final doc = exotics[index];
                        final name = doc['name'] ?? doc.id;
                        final fileName = assetName(name);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FruitPostsScreen(fruitName: name),
                              ),
                            );
                          },
                          child: SizedBox(
                            width: 100,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              clipBehavior: Clip.hardEdge,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    'assets/exotic_fruits/$fileName.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/placeholder.jpg',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      color: Colors.black54,
                                      child: Text(
                                        name.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
          // Normal Fruits Grid (assets only)
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('fruits').get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No fruit categories found.'));
                }

                final fruits = snapshot.data!.docs.where((fruit) {
                  final name = fruit.id.toLowerCase();
                  return _searchQuery.isEmpty || name.contains(_searchQuery);
                }).toList();

                if (fruits.isEmpty) {
                  return const Center(
                      child: Text('No fruits match your search.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: fruits.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final fruit = fruits[index];
                    final fruitName = fruit.id;
                    final fileName = assetName(fruitName);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FruitPostsScreen(fruitName: fruitName),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        clipBehavior: Clip.hardEdge,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/fruit_banners/$fileName.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Text(
                                      'Error\nloading\n$fruitName',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color.fromARGB(180, 0, 0, 0),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 14,
                              child: Text(
                                fruitName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'ComicNeue',
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(2, 2),
                                      blurRadius: 6,
                                      color: Colors.black87,
                                    ),
                                  ],
                                ),
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
          ),
        ],
      ),
    );
  }
}
