import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:barkati_frits/screens/fruit_posts_screen.dart';
import 'package:barkati_frits/widgets/fruits/fruit_emoji.dart' show FruitIcon;

class FruitsScreen extends StatefulWidget {
  static const String routeName = '/fruits';
  const FruitsScreen({super.key});

  @override
  State<FruitsScreen> createState() => _FruitsScreenState();
}

class _FruitsScreenState extends State<FruitsScreen> {
  String _searchQuery = '';

  static const int _pageSize = 8;
  final List<QueryDocumentSnapshot> _fruits = [];
  QueryDocumentSnapshot? _lastFruitDoc;
  bool _isLoading = false;
  bool _hasMoreFruits = true;

  @override
  void initState() {
    super.initState();
    _loadInitialFruits();
  }

  Future<void> _loadInitialFruits() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('fruits')
        .orderBy(FieldPath.documentId)
        .limit(_pageSize)
        .get();

    setState(() {
      _fruits.clear();
      _fruits.addAll(snapshot.docs);
      _lastFruitDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMoreFruits = snapshot.docs.length == _pageSize;
      _isLoading = false;
    });
  }

  Future<void> _loadMoreFruits() async {
    if (_isLoading || !_hasMoreFruits || _lastFruitDoc == null) return;
    setState(() => _isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('fruits')
        .orderBy(FieldPath.documentId)
        .startAfterDocument(_lastFruitDoc!)
        .limit(_pageSize)
        .get();

    setState(() {
      _fruits.addAll(snapshot.docs);
      _lastFruitDoc =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastFruitDoc;
      _hasMoreFruits = snapshot.docs.length == _pageSize;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredFruits = _fruits.where((fruit) {
      final name = fruit.id.toLowerCase();
      return _searchQuery.isEmpty || name.contains(_searchQuery);
    }).toList();

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
          // 🔍 Enhanced Search Bar
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
                onChanged: _onSearchChanged,
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

          // 🍍 Exotic Fruits Section
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('exotic_fruits').get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox();
              }

              final exotics = snapshot.data!.docs;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 16, 12),
                    child: Row(
                      children: [
                        const Text(
                          'EXOTIC SELECTION',
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
                        final name = exotics[index]['name'] ?? exotics[index].id;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FruitPostsScreen(fruitName: name),
                              ),
                            );
                          },
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
                                      name.toUpperCase(),
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

          const Padding(
            padding: EdgeInsets.fromLTRB(18, 24, 16, 8),
            child: Text(
              'REGULAR FRUITS',
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w900,
                color: Color(0xFF424242),
              ),
            ),
          ),

          // 🍎 Normal Fruits Grid
          Expanded(
            child: filteredFruits.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF689F38)))
                : filteredFruits.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No fruits found.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (scrollInfo.metrics.pixels >=
                                  scrollInfo.metrics.maxScrollExtent - 200 &&
                              !_isLoading &&
                              _hasMoreFruits) {
                            _loadMoreFruits();
                          }
                          return false;
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredFruits.length + (_hasMoreFruits ? 1 : 0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemBuilder: (context, index) {
                            if (index == filteredFruits.length) {
                              return const Center(child: CircularProgressIndicator(color: Color(0xFF689F38)));
                            }

                            final fruit = filteredFruits[index];
                            final fruitName = fruit.id;
                            final fruitData = fruit.data() as Map<String, dynamic>;
                            final bannerUrl = fruitData['banner_url'] as String? ?? '';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FruitPostsScreen(fruitName: fruitName),
                                  ),
                                );
                              },
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
                                    Position_BgIcon(Colors.green.shade50),
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          FruitIcon(fruitName: fruitName, size: 52, bannerUrl: bannerUrl),
                                          const SizedBox(height: 10),
                                          Text(
                                            fruitName.toUpperCase(),
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
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Helper widget for card decoration
  Widget Position_BgIcon(Color color) {
    return Positioned(
      top: -15,
      left: -15,
      child: CircleAvatar(
        radius: 30,
        backgroundColor: color.withOpacity(0.3),
      ),
    );
  }
}