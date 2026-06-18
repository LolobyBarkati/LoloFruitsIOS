import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barkati_frits/screens/product_detail_screen.dart';
import 'package:barkati_frits/utils/utils.dart';
import 'package:barkati_frits/widgets/fruits/fruit_post_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FruitPostsScreen extends StatefulWidget {
  final String fruitName;
  const FruitPostsScreen({super.key, required this.fruitName});

  @override
  State<FruitPostsScreen> createState() => _FruitPostsScreenState();
}

class _FruitPostsScreenState extends State<FruitPostsScreen> {
  final List<QueryDocumentSnapshot> _posts = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 12;
  QueryDocumentSnapshot? _lastDocument;

  String _searchQuery = '';
  String _selectedCountry = 'All Countries';
  String _sortBy = 'newest'; // newest, oldest, price_low, price_high
  Set<String> _availableCountries = {};

  Future<void> _cachePosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _posts
          .map((doc) => {
                'id': doc.id,
                'data': doc.data(),
              })
          .toList();
      await prefs.setString(
        'FRUIT_POSTS_${widget.fruitName}'.toUpperCase(),
        jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Post cache error: $e');
    }
  }

  Future<void> _loadCachedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached =
          prefs.getString('FRUIT_POSTS_${widget.fruitName}'.toUpperCase());
      if (cached != null && _posts.isEmpty) {
        debugPrint('Loaded posts from cache for ${widget.fruitName}');
      }
    } catch (e) {
      debugPrint('Load post cache error: $e');
    }
  }

  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  List<QueryDocumentSnapshot> _getFilteredAndSortedPosts() {
    List<QueryDocumentSnapshot> filtered = _posts.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final fruitName = (data['fruit_name'] ?? '').toString().toLowerCase();
      final country = (data['country'] ?? '').toString().toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          fruitName.contains(_searchQuery.toLowerCase()) ||
          country.contains(_searchQuery.toLowerCase());
      final matchesCountry = _selectedCountry == 'All Countries' ||
          country == _selectedCountry.toLowerCase();
      return matchesSearch && matchesCountry;
    }).toList();

    filtered.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      switch (_sortBy) {
        case 'oldest':
          final tA = (dataA['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final tB = (dataB['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return tA.compareTo(tB);
        case 'price_low':
          final priceA = (dataA['price'] as num?)?.toDouble() ?? 0;
          final priceB = (dataB['price'] as num?)?.toDouble() ?? 0;
          return priceA.compareTo(priceB);
        case 'price_high':
          final priceA = (dataA['price'] as num?)?.toDouble() ?? 0;
          final priceB = (dataB['price'] as num?)?.toDouble() ?? 0;
          return priceB.compareTo(priceA);
        default: // newest
          final tA = (dataA['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final tB = (dataB['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return tB.compareTo(tA);
      }
    });

    return filtered;
  }

  @override
  void initState() {
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPosts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _loadCachedPosts();

      final query = FirebaseFirestore.instance
          .collection('fruits')
          .doc(widget.fruitName)
          .collection(widget.fruitName)
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _posts.clear();
        _posts.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;
        _extractCountries();
        await _cachePosts();
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _extractCountries() {
    _availableCountries = {};
    for (final doc in _posts) {
      final data = doc.data() as Map<String, dynamic>;
      final country = data['country'] as String?;
      if (country != null && country.isNotEmpty) {
        _availableCountries.add(country);
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore || _lastDocument == null) return;
    setState(() => _isLoading = true);
    try {
      final query = FirebaseFirestore.instance
          .collection('fruits')
          .doc(widget.fruitName)
          .collection(widget.fruitName)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _posts.addAll(snapshot.docs);
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == _pageSize;
        _extractCountries();
        await _cachePosts();
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_capitalizeFirstLetter(widget.fruitName)} Market',
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8BC34A), Color(0xFF689F38)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by name or country...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF689F38)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Country Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCountry,
                    items: [
                      const DropdownMenuItem(
                        value: 'All Countries',
                        child: Text('All Countries', style: TextStyle(fontSize: 12)),
                      ),
                      ..._availableCountries.toList().map(
                            (country) => DropdownMenuItem(
                              value: country,
                              child: Text(country, style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCountry = value);
                      }
                    },
                    underline: const SizedBox(),
                    isDense: true,
                    isExpanded: false,
                  ),
                ),
                const SizedBox(width: 8),
                // Sort Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('Newest', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'oldest', child: Text('Oldest', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortBy = value);
                      }
                    },
                    underline: const SizedBox(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_isLoading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF689F38)));
    }

    final filteredPosts = _getFilteredAndSortedPosts();

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No listings for ${_capitalizeFirstLetter(widget.fruitName)}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (filteredPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No results matching your filters', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final isGuest = isGuestUser();
    final visibleCount = isGuest ? filteredPosts.length.clamp(0, 4) : filteredPosts.length;
    final showLock = isGuest && filteredPosts.length > 4;
    final totalCount = visibleCount + (showLock ? 1 : 0) + (_hasMore && !isGuest ? 1 : 0);

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // Loading indicator for logged-in users
        if (!isGuest && index == filteredPosts.length) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF689F38)));
        }

        // Lock tile for guests after 4 posts
        if (isGuest && index >= visibleCount) {
          return GestureDetector(
            onTap: () => showLoginRequired(context),
            child: Stack(
              children: [
                if (index < filteredPosts.length)
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: FruitPostCard(
                      data: filteredPosts[index].data() as Map<String, dynamic>,
                      onTap: () {},
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 32, color: Colors.grey.shade600),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to see more',
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

        final doc = filteredPosts[index];
        final data = doc.data() as Map<String, dynamic>;

        return FruitPostCard(
          data: data,
          onTap: () {
            if (isGuest) {
              showLoginRequired(context);
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(
                  fruitName: widget.fruitName,
                  docId: doc.id,
                ),
              ),
            );
          },
        );
      },
    );
  }
}