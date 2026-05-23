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
  final Color sectionColor = const Color(0xFF689F38); // Standardizing the green theme

  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

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
    const imageHeight = 340.0;
    const overlapHeight = 32.0;

    return Scaffold(
      backgroundColor: Colors.black, // Dark background for better media contrast
      body: isSubscribed == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF689F38)))
          : FutureBuilder<DocumentSnapshot>(
              future: _productFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF689F38)));
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("Product not found.", style: TextStyle(color: Colors.white)));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final name = _capitalizeFirstLetter((data['fruit_name'] ?? 'Unknown').toString());

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
                final String displayRate = data['rate'] != null ? data['rate'].toString() : 'Ask for Price';
                final String coldStorageName = data['cold_storage_name'] ?? 'N/A';

                return Stack(
                  children: [
                    // --- MEDIA CAROUSEL ---
                    if (media.isNotEmpty)
                      Positioned(
                        top: 0, left: 0, right: 0,
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
                                  padding: const EdgeInsets.only(bottom: 50.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      media.length,
                                      (index) => AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                        height: 6.0,
                                        width: _currentPage == index ? 20.0 : 6.0,
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

                    // --- CONTENT PANEL (OFFER SHEET UI) ---
                    Positioned(
                      top: imageHeight - overlapHeight,
                      left: 0, right: 0, bottom: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              // Handle
                              Center(
                                child: Container(
                                  width: 36, height: 4,
                                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 24),

                              if (!isSubscribed!) ...[
                                _buildLockedState(context),
                              ] else ...[
                                // Header Badge
                                Row(
                                  children: [
                                    _buildBadge("VERIFIED STOCK"),
                                    const Spacer(),
                                    Icon(Icons.verified_rounded, color: sectionColor, size: 20),
                                    const SizedBox(width: 4),
                                    Text("TOP QUALITY", style: TextStyle(color: sectionColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Color(0xFF1A1A1A), letterSpacing: -0.8),
                                ),
                                const SizedBox(height: 20),

                                // Location/Origin Section
                                _buildSectionTitle("Origin & Storage"),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FBF9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade100),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildSimpleInfoRow(Icons.location_on_rounded, "Country of Origin", country),
                                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(thickness: 0.5)),
                                      InkWell(
                                        onTap: () async {
                                          if (coldStorageName != 'N/A') {
                                            bool exists = await _doesColdStorageExist(coldStorageName);
                                            if (exists) {
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => StorageScreen(initialStorageName: coldStorageName)));
                                            }
                                          }
                                        },
                                        child: _buildSimpleInfoRow(Icons.ac_unit_rounded, "Cold Storage", coldStorageName, hasArrow: coldStorageName != 'N/A'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Seller Details
                                _buildSectionTitle("Seller Information"),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildDetailRow(Icons.storefront_rounded, "Company", data['company_name'] ?? 'N/A'),
                                      _buildDetailRow(Icons.person_pin_rounded, "Proprietor", data['owner_name'] ?? 'N/A'),
                                      _buildDetailRow(Icons.supervisor_account_rounded, "Manager", data['manager_name'] ?? 'N/A'),
                                      _buildDetailRow(Icons.payments_rounded, "Market Rate", displayRate, isPrice: true),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 32),
                                
                                // Call Action Button
                                _buildPrimaryButton(
                                  label: "Connect with Seller",
                                  color: sectionColor,
                                  icon: Icons.phone_forwarded_rounded,
                                  onPressed: () => _callOwner(phone),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Back Button
                    Positioned(
                      top: 45, left: 16,
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

  // --- REUSABLE UI COMPONENTS (MATCHING THE SHEET UI) ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: sectionColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: sectionColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildSimpleInfoRow(IconData icon, String label, String value, {bool hasArrow = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: sectionColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
        if (hasArrow) ...[const Spacer(), Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey[400])]
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500))),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isPrice ? sectionColor : const Color(0xFF1A1A1A))),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required Color color, IconData? icon, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 10)],
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedState(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          height: 80, width: 80,
          decoration: BoxDecoration(color: sectionColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.lock_outline_rounded, size: 36, color: sectionColor),
        ),
        const SizedBox(height: 24),
        const Text("Subscribers Only", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Text(
          "Get instant access to wholesale rates, verified supplier contacts, and cold storage details.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(
          label: "Unlock Details",
          color: sectionColor,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

// --- HELPER CLASSES (REMAINING UNCHANGED) ---

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