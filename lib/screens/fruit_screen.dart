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
  // Search
  String _searchQuery = '';

  // Pagination
  static const int _pageSize = 8;
  final List<QueryDocumentSnapshot> _fruits = [];
  QueryDocumentSnapshot? _lastFruitDoc;
  bool _isLoading = false;
  bool _hasMoreFruits = true;

  // Utility: Lowercase and remove spaces for asset matching
  String assetName(String name) =>
      name.trim().toLowerCase().replaceAll(' ', '');

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Fruits'),
        backgroundColor: Colors.lightGreen,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔍 Search
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
              onChanged: _onSearchChanged,
            ),
          ),

          // 🍍 Exotic Fruits (small dataset – OK without pagination)
          FutureBuilder<QuerySnapshot>(
            future:
                FirebaseFirestore.instance.collection('exotic_fruits').get(),
            builder: (context, snapshot) {
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: exotics.length,
                      itemBuilder: (context, index) {
                        final name =
                            exotics[index]['name'] ?? exotics[index].id;
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
                              clipBehavior: Clip.hardEdge,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    'assets/exotic_fruits/$fileName.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Image.asset('assets/placeholder.jpg'),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      color: Colors.black54,
                                      padding: const EdgeInsets.all(6),
                                      child: Text(
                                        name.toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
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

          // 🍎 Normal Fruits (TRUE Firestore pagination)
          Expanded(
            child: filteredFruits.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredFruits.isEmpty
                    ? const Center(
                        child: Text('No fruits match your search.'),
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
                          padding: const EdgeInsets.all(12),
                          itemCount:
                              filteredFruits.length + (_hasMoreFruits ? 1 : 0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, index) {
                            if (index == filteredFruits.length) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final fruit = filteredFruits[index];
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
                                      cacheHeight: 200,
                                      cacheWidth: 200,
                                      errorBuilder: (_, __, ___) =>
                                          Container(color: Colors.grey[300]),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 14,
                                      child: Text(
                                        fruitName.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
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
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
