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
    final imageHeight = 320.0;
    final overlapHeight = 18.0;

    return Scaffold(
      body: isSubscribed == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<DocumentSnapshot>(
              future: _productFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("Product not found."));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final name =
                    (data['fruit_name'] ?? 'Unknown').toString().toUpperCase();

                // Unified handling of image_url[s] and video_url[s]
                final List imageUrls = (() {
                  if (data['image_urls'] is List &&
                      (data['image_urls'] as List).isNotEmpty) {
                    return (data['image_urls'] as List)
                        .map((e) => e.toString())
                        .toList();
                  } else if (data['image_url'] is String &&
                      data['image_url'].isNotEmpty) {
                    return [data['image_url']];
                  } else {
                    return [];
                  }
                })();

                final List videoUrls = (() {
                  if (data['video_urls'] is List &&
                      (data['video_urls'] as List).isNotEmpty) {
                    return (data['video_urls'] as List)
                        .map((e) => e.toString())
                        .toList();
                  } else if (data['video_url'] is String &&
                      data['video_url'].isNotEmpty) {
                    return [data['video_url']];
                  } else {
                    return [];
                  }
                })();

                // Combine media for display order
                final List<Map<String, String>> media = [
                  ...imageUrls.map((url) => {'type': 'image', 'url': url}),
                  ...videoUrls.map((url) => {'type': 'video', 'url': url}),
                ];

                final country = data['country'] ?? 'Unknown';
                final phone = data['phone'] ?? 'N/A';
                final dynamic rate = data['rate'];
                final String displayRate =
                    rate != null ? rate.toString() : 'N/A';
                final String coldStorageName =
                    data['cold_storage_name'] ?? 'N/A';

                return Stack(
                  children: [
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
                                    showGalleryViewer(
                                      context,
                                      imageUrls.cast<String>(),
                                      _currentPage < imageUrls.length
                                          ? _currentPage
                                          : 0,
                                    );
                                  } else if (current['type'] == 'video') {
                                    showVideoViewer(context, current['url']!);
                                  }
                                },
                                child: PageView.builder(
                                  itemCount: media.length,
                                  controller:
                                      PageController(initialPage: _currentPage),
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    final item = media[index];
                                    if (item['type'] == 'image') {
                                      return Image.network(
                                        item['url']!,
                                        fit: BoxFit.cover,
                                        height: imageHeight,
                                        width: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.broken_image,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      );
                                    } else if (item['type'] == 'video') {
                                      return VideoThumbnail(
                                        url: item['url']!,
                                        height: imageHeight,
                                      );
                                    } else {
                                      return const SizedBox();
                                    }
                                  },
                                ),
                              ),
                              if (media.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      media.length,
                                      (index) => AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        height: 8.0,
                                        width:
                                            _currentPage == index ? 24.0 : 8.0,
                                        decoration: BoxDecoration(
                                          color: _currentPage == index
                                              ? Colors.white
                                              : Colors.white54,
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: imageHeight - overlapHeight,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.0),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(36),
                            topRight: Radius.circular(36),
                          ),
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(12.0),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.grey, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        country,
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (isSubscribed!) ...[
                                    const SizedBox(height: 6),
                                    _buildDetailCard(
                                      icon: Icons.ac_unit,
                                      label: "Cold Storage",
                                      value: coldStorageName,
                                      onTap: () async {
                                        if (coldStorageName == 'N/A' ||
                                            coldStorageName.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "Cold Storage information not available.")),
                                          );
                                        } else {
                                          bool exists =
                                              await _doesColdStorageExist(
                                                  coldStorageName);
                                          if (exists) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    StorageScreen(
                                                  initialStorageName:
                                                      coldStorageName,
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Storage not registered in database.")),
                                            );
                                          }
                                        }
                                      },
                                      trailingIcon: Icons.arrow_forward_ios,
                                    ),
                                    const SizedBox(height: 6),
                                    _buildDetailCard(
                                      icon: Icons.business,
                                      label: "Company",
                                      value: data['company_name'] ?? 'N/A',
                                    ),
                                    const SizedBox(height: 6),
                                    _buildDetailCard(
                                      icon: Icons.person,
                                      label: "Owner",
                                      value: data['owner_name'] ?? 'N/A',
                                    ),
                                    const SizedBox(height: 6),
                                    _buildDetailCard(
                                      icon: Icons.supervisor_account,
                                      label: "Manager",
                                      value: data['manager_name'] ?? 'N/A',
                                    ),
                                    const SizedBox(height: 6),
                                    _buildDetailCard(
                                      icon: Icons.price_change_outlined,
                                      label: "Approximate Price",
                                      value: displayRate,
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  if (isSubscribed!)
                                    _buildDetailCard(
                                      icon: Icons.phone_outlined,
                                      label: "Phone",
                                      value: phone,
                                      onTap: () => _callOwner(phone),
                                      trailingIcon: Icons.call,
                                    ),
                                  if (!isSubscribed!) ...[
                                    const SizedBox(height: 18),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Unlock Full Details",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            "Subscribe now to see the price, contact information, and location of this product.",
                                            style:
                                                TextStyle(color: Colors.grey),
                                          ),
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const SubscriptionScreen(),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                  "Buy Subscription"),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    IconData? trailingIcon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

void showGalleryViewer(BuildContext context, List<String> imageUrls, int initialIndex) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: GalleryPhotoViewWrapper(
        galleryItems: imageUrls,
        initialIndex: initialIndex,
      ),
    ),
  );
}

class GalleryPhotoViewWrapper extends StatefulWidget {
  final List<String> galleryItems;
  final int initialIndex;

  const GalleryPhotoViewWrapper({
    Key? key,
    required this.galleryItems,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _GalleryPhotoViewWrapperState createState() =>
      _GalleryPhotoViewWrapperState();
}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PhotoViewGallery.builder(
          itemCount: widget.galleryItems.length,
          pageController: PageController(initialPage: widget.initialIndex),
          builder: (context, index) {
            return PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(widget.galleryItems[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey,
                  ),
                );
              },
            );
          },
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

void showVideoViewer(BuildContext context, String videoUrl) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.all(0),
      child: _VideoPlayerFullScreen(url: videoUrl),
    ),
  );
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
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {
          _isReady = true;
        });
        _chewieController = ChewieController(
          videoPlayerController: _controller,
          autoPlay: true,
          looping: true,
          allowedScreenSleep: false,
        );
      });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: _isReady && _chewieController != null
              ? Chewie(controller: _chewieController!)
              : const CircularProgressIndicator(),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

// Thumbnail widget for video preview (shows play icon)
class VideoThumbnail extends StatefulWidget {
  final String url;
  final double height;
  const VideoThumbnail({required this.url, required this.height});

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
        _controller?.setVolume(0);
        _controller?.pause();
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: widget.height,
          width: double.infinity,
          color: Colors.black12,
          child: _initialized
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(),
                ),
        ),
        Positioned.fill(
          child: Center(
            child: Icon(
              Icons.play_circle_fill,
              size: 70,
              color: Colors.white70,
              shadows: [
                Shadow(
                    color: Colors.black54,
                    blurRadius: 12,
                    offset: Offset(0, 3)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
