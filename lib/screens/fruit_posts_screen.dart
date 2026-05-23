import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barkati_frits/screens/product_detail_screen.dart';
import 'package:barkati_frits/widgets/fruits/fruit_post_card.dart';

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

  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
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
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;
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
      body: _buildGrid(),
    );
  }

  Widget _buildGrid() {
    if (_isLoading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF689F38)));
    }

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

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: _posts.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _posts.length) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF689F38)));
        }

        final doc = _posts[index];
        final data = doc.data() as Map<String, dynamic>;

        // FIXED: Using Class name "FruitPostCard" instead of filename "fruit_posts_screen"
        return FruitPostCard(
          data: data,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                fruitName: widget.fruitName,
                docId: doc.id,
              ),
            ),
          ),
        );
      },
    );
  }
} 