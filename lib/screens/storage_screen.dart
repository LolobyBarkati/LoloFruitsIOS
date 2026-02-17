import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

class StorageScreen extends StatefulWidget {
  static const String routeName = '/storage';
  final String? initialStorageName;

  const StorageScreen({super.key, this.initialStorageName});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  // Pagination
  static const int _pageSize = 10;
  final List<QueryDocumentSnapshot> _storages = [];
  QueryDocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

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
    super.dispose();
  }

  Future<void> _loadInitial() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

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
  }

  void _scrollToInitialItem() {
    if (widget.initialStorageName == null) return;

    final index = _storages.indexWhere((doc) =>
        (doc.data() as Map<String, dynamic>)['name'] ==
        widget.initialStorageName);

    if (index != -1 && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          index * 140.0,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cold Storage'),
        centerTitle: true,
      ),
      backgroundColor: Colors.blueGrey[50],
      body: _storages.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _storages.isEmpty
              ? const Center(child: Text('No storage entries found.'))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _storages.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _storages.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final data =
                        _storages[index].data() as Map<String, dynamic>;

                    final name = data['name'] ?? 'N/A';
                    final phone = data['director_number'] ?? '';
                    final mapUrl = data['google_map_link'] ?? '';
                    final fileUrl = data['file_url'] ?? '';
                    final fileSize = data['file_size'] ?? '';
                    final Timestamp? ts = data['timestamp'];

                    final updatedText = ts != null
                        ? timeago.format(ts.toDate())
                        : 'Recently updated';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.insert_drive_file_rounded,
                                  size: 40, color: Colors.green[700]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 6),
                                  if (fileSize.isNotEmpty)
                                    Text(fileSize,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700])),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _actionBtn(
                                          'Call',
                                          Icons.call,
                                          Colors.green,
                                          () => _callOwner(phone)),
                                      const SizedBox(width: 8),
                                      _actionBtn('Map', Icons.map, Colors.blue,
                                          () => _openMap(mapUrl)),
                                      const SizedBox(width: 8),
                                      _actionBtn(
                                          'Rate',
                                          Icons.download,
                                          Colors.green[700]!,
                                          () => _openPdf(fileUrl)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Updated $updatedText',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600])),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
