import 'package:barkati_frits/screens/subscription_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barkati_frits/screens/storage_screen.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ProductDetailScreen extends StatefulWidget {
  final String fruitName;
  final String docId;

  const ProductDetailScreen({
    Key? key,
    required this.fruitName,
    required this.docId,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool? isSubscribed;
  late Future<DocumentSnapshot> _productFuture;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _productFuture = FirebaseFirestore.instance
        .collection('fruits')
        .doc(widget.fruitName)
        .collection(widget.fruitName)
        .doc(widget.docId)
        .get();
    checkSubscriptionStatus();
  }

  Future<void> checkSubscriptionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() => isSubscribed = false);
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection('payments')
        .where('email', isEqualTo: user.email)
        .get();

    if (query.docs.isEmpty) {
      setState(() => isSubscribed = false);
      return;
    }

    final data = query.docs.first.data();
    final Timestamp? expiry = data['subscription_expiry'];
    final bool status = data['status'] ?? false;

    if (expiry == null || expiry.toDate().isBefore(DateTime.now())) {
      await query.docs.first.reference.update({'status': false});
      setState(() => isSubscribed = false);
    } else {
      setState(() => isSubscribed = status);
    }
  }

  void _callOwner(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch $phoneNumber")),
      );
    }
  }

  Future<bool> _doesColdStorageExist(String coldStorageName) async {
    if (coldStorageName == 'N/A' || coldStorageName.isEmpty) {
      return false;
    }
    final querySnapshot = await FirebaseFirestore.instance
        .collection('cold storage')
        .where('name', isEqualTo: coldStorageName)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final imageHeight = 340.0;
    final overlapHeight = 28.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: isSubscribed == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF689F38)))
          : FutureBuilder<DocumentSnapshot>(
              future: _productFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF689F38)));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("Product not found."));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final name = (data['fruit_name'] ?? 'Unknown').toString().toUpperCase();

                // Media Logic
                final List imageUrls = (() {
                  if (data['image_urls'] is List && (data['image_urls'] as List).isNotEmpty) {
                    return (data['image_urls'] as List).map((e) => e.toString()).toList();
                  } else if (data['image_url'] is String && data['image_url'].isNotEmpty) {
                    return [data['image_url']];
                  } else {
                    return [];
                  }
                })();

                final List videoUrls = (() {
                  if (data['video_urls'] is List && (data['video_urls'] as List).isNotEmpty) {
                    return (data['video_urls'] as List).map((e) => e.toString()).toList();
                  } else if (data['video_url'] is String && data['video_url'].isNotEmpty) {
                    return [data['video_url']];
                  } else {
                    return [];
                  }
                })();

                final List<Map<String, String>> media = [
                  ...imageUrls.map((url) => {'type': 'image', 'url': url}),
                  ...videoUrls.map((url) => {'type': 'video', 'url': url}),
                ];

                final country = data['country'] ?? 'Unknown';
                final phone = data['phone'] ?? 'N/A';
                final String displayRate = data['rate'] != null ? data['rate'].toString() : 'N/A';
                final String coldStorageName = data['cold_storage_name'] ?? 'N/A';

                return Stack(
                  children: [
                    // --- MEDIA CAROUSEL ---
                    if (media.isNotEmpty)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          height: imageHeight,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  final current = media[_currentPage];
                                  if (current['type'] == 'image') {
                                    showGalleryViewer(context, imageUrls.cast<String>(), _currentPage < imageUrls.length ? _currentPage : 0);
                                  } else if (current['type'] == 'video') {
                                    showVideoViewer(context, current['url']!);
                                  }
                                },
                                child: PageView.builder(
                                  itemCount: media.length,
                                  onPageChanged: (index) => setState(() => _currentPage = index),
                                  itemBuilder: (context, index) {
                                    final item = media[index];
                                    if (item['type'] == 'image') {
                                      return Image.network(item['url']!, fit: BoxFit.cover, height: imageHeight);
                                    } else {
                                      return VideoThumbnail(url: item['url']!, height: imageHeight);
                                    }
                                  },
                                ),
                              ),
                              if (media.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 45.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      media.length,
                                      (index) => AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                        height: 6.0,
                                        width: _currentPage == index ? 18.0 : 6.0,
                                        decoration: BoxDecoration(
                                          color: _currentPage == index ? Colors.white : Colors.white54,
                                          borderRadius: BorderRadius.circular(3.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                    // --- CONTENT PANEL ---
                    Positioned(
                      top: imageHeight - overlapHeight,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1B3022), letterSpacing: -0.5)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: Color(0xFF8BC34A), size: 18),
                                  const SizedBox(width: 4),
                                  Text(country, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              
                              if (isSubscribed!) ...[
                                _buildDetailCard(icon: Icons.ac_unit_rounded, label: "COLD STORAGE", value: coldStorageName, 
                                  onTap: () async {
                                    if (coldStorageName != 'N/A' && coldStorageName.isNotEmpty) {
                                      bool exists = await _doesColdStorageExist(coldStorageName);
                                      if (exists) {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => StorageScreen(initialStorageName: coldStorageName)));
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Storage not registered.")));
                                      }
                                    }
                                  },
                                  trailingIcon: Icons.arrow_forward_ios,
                                ),
                                _buildDetailCard(icon: Icons.business_rounded, label: "COMPANY NAME", value: data['company_name'] ?? 'N/A'),
                                _buildDetailRow(Icons.person_rounded, "OWNER", data['owner_name'] ?? 'N/A'),
                                _buildDetailRow(Icons.supervisor_account_rounded, "MANAGER", data['manager_name'] ?? 'N/A'),
                                _buildDetailCard(icon: Icons.price_change_rounded, label: "APPROXIMATE PRICE", value: displayRate, iconColor: Colors.orange.shade700),
                                _buildDetailCard(icon: Icons.phone_enabled_rounded, label: "CONTACT OWNER", value: phone, onTap: () => _callOwner(phone), trailingIcon: Icons.call, highlight: true),
                              ] else ...[
                                // Lock UI
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: const BoxDecoration(color: Color(0xFFF1F8E9), shape: BoxShape.circle),
                                        child: const Icon(Icons.lock_person_rounded, size: 32, color: Color(0xFF689F38)),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text("Member Exclusive", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 8),
                                      const Text("Pricing, storage details, and direct contact numbers are only available to subscribed members.",
                                        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.4)),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF689F38),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            elevation: 0,
                                          ),
                                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                                          child: const Text("Unlock Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Back Button
                    Positioned(
                      top: 45,
                      left: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.4),
                        child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18), onPressed: () => Navigator.pop(context)),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required IconData icon, required String label, required String value, VoidCallback? onTap, IconData? trailingIcon, Color? iconColor, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: highlight ? const Color(0xFFF1F8E9) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: highlight ? const Color(0xFF8BC34A).withOpacity(0.3) : Colors.grey.shade100),
            boxShadow: [if(!highlight) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? const Color(0xFF689F38), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey, fontSize: 10, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(value, style: TextStyle(fontSize: 16, fontWeight: highlight ? FontWeight.w900 : FontWeight.w700, color: const Color(0xFF1B3022))),
                  ],
                ),
              ),
              if (trailingIcon != null) Icon(trailingIcon, size: 16, color: highlight ? const Color(0xFF689F38) : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HELPER CLASSES & FUNCTIONS ---

void showGalleryViewer(BuildContext context, List<String> imageUrls, int initialIndex) {
  showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.black, insetPadding: EdgeInsets.zero, child: GalleryPhotoViewWrapper(galleryItems: imageUrls, initialIndex: initialIndex)));
}

class GalleryPhotoViewWrapper extends StatefulWidget {
  final List<String> galleryItems;
  final int initialIndex;
  const GalleryPhotoViewWrapper({Key? key, required this.galleryItems, this.initialIndex = 0}) : super(key: key);
  @override
  _GalleryPhotoViewWrapperState createState() => _GalleryPhotoViewWrapperState();
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  late int currentIndex;
  @override
  void initState() { super.initState(); currentIndex = widget.initialIndex; }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PhotoViewGallery.builder(
          itemCount: widget.galleryItems.length,
          pageController: PageController(initialPage: widget.initialIndex),
          builder: (context, index) => PhotoViewGalleryPageOptions(imageProvider: NetworkImage(widget.galleryItems[index]), minScale: PhotoViewComputedScale.contained, maxScale: PhotoViewComputedScale.covered * 2),
          onPageChanged: (index) => setState(() => currentIndex = index),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
        Positioned(top: 40, right: 20, child: CircleAvatar(backgroundColor: Colors.black45, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()))),
      ],
    );
  }
}

void showVideoViewer(BuildContext context, String videoUrl) {
  showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.black, insetPadding: EdgeInsets.zero, child: _VideoPlayerFullScreen(url: videoUrl)));
}

class _VideoPlayerFullScreen extends StatefulWidget {
  final String url;
  const _VideoPlayerFullScreen({required this.url});
  @override
  State<_VideoPlayerFullScreen> createState() => _VideoPlayerFullScreenState();
}

class _VideoPlayerFullScreenState extends State<_VideoPlayerFullScreen> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  bool _isReady = false;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)..initialize().then((_) {
      setState(() => _isReady = true);
      _chewieController = ChewieController(videoPlayerController: _controller, autoPlay: true, looping: true, allowedScreenSleep: false);
    });
  }
  @override
  void dispose() { _chewieController?.dispose(); _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(child: _isReady && _chewieController != null ? Chewie(controller: _chewieController!) : const CircularProgressIndicator(color: Colors.white)),
        Positioned(top: 40, right: 20, child: CircleAvatar(backgroundColor: Colors.black45, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()))),
      ],
    );
  }
}

class VideoThumbnail extends StatefulWidget {
  final String url;
  final double height;
  const VideoThumbnail({required this.url, required this.height, Key? key}) : super(key: key);
  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)..initialize().then((_) {
      if (mounted) setState(() => _initialized = true);
      _controller?.setVolume(0); _controller?.pause();
    });
  }
  @override
  void dispose() { _controller?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(height: widget.height, width: double.infinity, color: Colors.black12, child: _initialized ? AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!)) : const Center(child: CircularProgressIndicator())),
        const Positioned.fill(child: Center(child: Icon(Icons.play_circle_fill, size: 70, color: Colors.white70))),
      ],
    );
  }
}