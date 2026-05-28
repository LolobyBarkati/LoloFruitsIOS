import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageScreen extends StatefulWidget {
  static const String routeName = '/storage';
  final String? initialStorageName;

  const StorageScreen({super.key, this.initialStorageName});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  // Brand Colors
  final Color primaryGreen = const Color(0xFF80C031);
  final Color accentOrange = const Color(0xFFFFA000);

  // Pagination
  static const int _pageSize = 10;
  static const String _storageCache = 'COLD_STORAGE_CACHE';
  final List<QueryDocumentSnapshot> _storages = [];
  QueryDocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitial();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cacheStorages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _storages
          .map((doc) => {
                'id': doc.id,
                'data': doc.data(),
              })
          .toList();
      await prefs.setString(_storageCache, jsonEncode(data));
    } catch (e) {
      debugPrint('Storage cache error: $e');
    }
  }

  Future<void> _loadCachedStorages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_storageCache);
      if (cached != null && _storages.isEmpty) {
        final data = jsonDecode(cached) as List;
        debugPrint('Loaded ${data.length} storages from cache');
      }
    } catch (e) {
      debugPrint('Load cache error: $e');
    }
  }

  List<QueryDocumentSnapshot> _getFilteredStorages() {
    if (_searchQuery.isEmpty) {
      return _storages;
    }
    return _storages.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _loadInitial() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    await _loadCachedStorages();

    final snapshot = await FirebaseFirestore.instance
        .collection('cold storage')
        .orderBy('timestamp', descending: true)
        .limit(_pageSize)
        .get();

    setState(() {
      _storages.clear();
      _storages.addAll(snapshot.docs);
      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMore = snapshot.docs.length == _pageSize;
      _isLoading = false;
    });

    await _cacheStorages();
    _scrollToInitialItem();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore || _lastDoc == null) return;
    setState(() => _isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('cold storage')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(_pageSize)
        .get();

    setState(() {
      _storages.addAll(snapshot.docs);
      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDoc;
      _hasMore = snapshot.docs.length == _pageSize;
      _isLoading = false;
    });

    await _cacheStorages();
  }

  void _scrollToInitialItem() {
    if (widget.initialStorageName == null) return;

    final index = _storages.indexWhere((doc) =>
        (doc.data() as Map<String, dynamic>)['name'] ==
        widget.initialStorageName);

    if (index != -1 && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          index * 160.0, // Adjusted for slightly taller modern cards
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _callOwner(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openPdf(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open PDF externally')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStorages = _getFilteredStorages();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('Cold Storage',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: primaryGreen),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // Storage List
          Expanded(
            child: _storages.isEmpty && _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryGreen))
                : _storages.isEmpty
                    ? Center(child: Text('No storage entries found.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16)))
                    : filteredStorages.isEmpty
                        ? Center(child: Text('No results found.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16)))
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: filteredStorages.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredStorages.length) {
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: Center(child: CircularProgressIndicator(color: primaryGreen)),
                              );
                            }

                            final data = filteredStorages[index].data() as Map<String, dynamic>;
                            final name = data['name'] ?? 'N/A';
                            final phone = data['director_number'] ?? '';
                            final mapUrl = data['google_map_link'] ?? '';
                            final fileUrl = data['file_url'] ?? '';
                            final fileSize = data['file_size'] ?? '';
                            final Timestamp? ts = data['timestamp'];

                            final updatedText = ts != null
                                ? timeago.format(ts.toDate())
                                : 'Recently updated';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: primaryGreen.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(Icons.ac_unit_rounded,
                                                size: 30, color: primaryGreen),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(name,
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 17,
                                                        color: Color(0xFF2D312E))),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(Icons.history, size: 14, color: Colors.grey[400]),
                                                    const SizedBox(width: 4),
                                                    Text('Updated $updatedText',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[500])),
                                                  ],
                                                ),
                                                if (fileSize.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Text('Rate File: $fileSize',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                            color: accentOrange)),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                      child: Row(
                                        children: [
                                          _actionBtn(
                                              'Call',
                                              Icons.call_rounded,
                                              primaryGreen,
                                              () => _callOwner(phone)),
                                          const SizedBox(width: 8),
                                          _actionBtn(
                                              'Map',
                                              Icons.location_on_rounded,
                                              const Color(0xFF4A90E2),
                                              () => _openMap(mapUrl)),
                                          if (fileUrl.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            _actionBtn(
                                                'Rate',
                                                Icons.file_download_outlined,
                                                accentOrange,
                                                () => _openPdf(fileUrl)),
                                          ],
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
        ],
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}