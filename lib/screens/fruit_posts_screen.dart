import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:barkati_frits/screens/product_detail_screen.dart';
import 'package:intl/intl.dart';
import 'dart:async';

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
  int _pageSize = 12;
  QueryDocumentSnapshot? _lastDocument;

  Timer? _searchDebounce;


  @override
  void initState() {
// Load once
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
      setState(() {});
    } catch (e) {
      // ignore errors for now
    } finally {
      setState(() => _isLoading = false);
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
      setState(() {});
    } catch (e) {
      // ignore
    } finally {
      setState(() => _isLoading = false);
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

  String _formatTimestamp(Map<String, dynamic> data) {
    if (data['timestamp'] != null) {
      final postedTime = (data['timestamp'] as Timestamp).toDate();
      return DateFormat('d MMM yyyy, h:mm a').format(postedTime);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.fruitName.toUpperCase()} Listings'),
        backgroundColor: Colors.lightGreen,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return const Center(child: Text('No posts found.'));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _posts.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _posts.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final doc = _posts[index];
        final data = doc.data() as Map<String, dynamic>;

        final name = data['fruit_name'] ?? 'No Name';
        final country = data['country'] ?? 'Unknown';
        final dateTimeString = _formatTimestamp(data);

        // image handling (supports list or single)
        String imageUrl = '';
        if (data['image_urls'] != null &&
            data['image_urls'] is List &&
            data['image_urls'].isNotEmpty) {
          imageUrl = data['image_urls'][0];
        } else if (data['image_url'] != null && data['image_url'] is String) {
          imageUrl = data['image_url'];
        }

        // video handling: prefer thumbnail if available
        String? videoUrl;
        String? videoThumb;
        if (data['video_url'] != null && data['video_url'] is String) {
          videoUrl = data['video_url'];
          if (data['video_thumbnail'] != null &&
              data['video_thumbnail'] is String) {
            videoThumb = data['video_thumbnail'];
          }
        }

        final mediaUrl =
            imageUrl.isNotEmpty ? imageUrl : videoThumb ?? videoUrl;

        return GestureDetector(
          onTap: () {
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: mediaUrl != null
                        ? CachedNetworkImage(
                            imageUrl: mediaUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/placeholder.jpg',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'assets/placeholder.jpg',
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (videoUrl != null)
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: Icon(
                        Icons.videocam,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
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
          ),
        );
      },
    );
  }
}
