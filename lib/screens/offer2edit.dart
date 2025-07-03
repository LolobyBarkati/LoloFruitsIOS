import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Offer2edit extends StatefulWidget {
  const Offer2edit({super.key});
  @override
  State<Offer2edit> createState() => _Offer2editState();
}

class _Offer2editState extends State<Offer2edit> {
  bool? _isSubscribed;
  bool _subCheckLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() {
        _isSubscribed = false;
        _subCheckLoading = false;
      });
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection('payments')
        .where('email', isEqualTo: user.email)
        .get();

    if (query.docs.isEmpty) {
      setState(() {
        _isSubscribed = false;
        _subCheckLoading = false;
      });
      return;
    }

    final data = query.docs.first.data();
    final Timestamp? expiry = data['subscription_expiry'];
    final bool status = data['status'] ?? false;

    if (expiry == null || expiry.toDate().isBefore(DateTime.now())) {
      await query.docs.first.reference.update({'status': false});
      setState(() {
        _isSubscribed = false;
        _subCheckLoading = false;
      });
    } else {
      setState(() {
        _isSubscribed = status;
        _subCheckLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectionColor = Colors.green[700]!;

    if (_subCheckLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child:
                Icon(Icons.local_grocery_store, color: sectionColor, size: 28),
          ),
          title: const Text(
            'Fruit Offers',
            style: TextStyle(
              color: Color(0xFF184D32),
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.1,
            ),
          ),
          centerTitle: true,
        ),
        backgroundColor: const Color(0xFFF5FAF7),
        body: Padding(
          padding: const EdgeInsets.only(top: 13),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('offerdata')
                .doc('main')
                .collection('fruit')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: sectionColor.withOpacity(0.23), size: 54),
                        const SizedBox(height: 10),
                        Text(
                          'No offers found.',
                          style: TextStyle(fontSize: 18, color: sectionColor),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final offers = snapshot.data!.docs;
              return ListView.builder(
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final doc = offers[index];
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final files = (data['files'] as List<dynamic>?) ?? [];
                  final contact = data['contact'] ?? '';
                  final country = data['country'] ?? '';
                  final postedAt = data['timestamp'] != null
                      ? (data['timestamp'] as Timestamp).toDate()
                      : DateTime.now();
                  final title = data['title']?.toString() ?? 'Fruit Offer';
                  final filesForCard = files
                      .where((file) =>
                          file is Map<String, dynamic> &&
                          (file['type'] != 'pdf'))
                      .toList();

                  // Media carousel for the main card
                  Widget mainCardMediaCarousel;
                  if (filesForCard.isNotEmpty) {
                    mainCardMediaCarousel = SizedBox(
                      height: 400,
                      child: PageView.builder(
                        itemCount: filesForCard.length,
                        itemBuilder: (context, mediaIndex) {
                          final file = filesForCard[mediaIndex];
                          if (file['type'] == 'image') {
                            return Image.network(
                              file['url'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (ctx, err, stack) => Container(
                                color: Colors.grey[200],
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image,
                                    size: 60, color: Colors.red),
                              ),
                            );
                          } else if (file['type'] == 'video') {
                            return _VideoPreview(url: file['url']);
                          } else {
                            return Container(
                              color: Colors.green[50],
                              alignment: Alignment.center,
                              child: const Icon(Icons.photo_library_outlined,
                                  size: 60, color: Colors.green),
                            );
                          }
                        },
                      ),
                    );
                  } else {
                    mainCardMediaCarousel = SizedBox(
                      height: 400,
                      child: Container(
                        color: Colors.green[50],
                        alignment: Alignment.center,
                        child: const Icon(Icons.photo_library_outlined,
                            size: 60, color: Colors.green),
                      ),
                    );
                  }

                  return Center(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) {
                            if (_isSubscribed != true) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: 24,
                                  right: 24,
                                  top: 48,
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom +
                                          32,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock,
                                        size: 48, color: sectionColor),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Subscription Required",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 25,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "You need an active subscription to view offer details.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.arrow_forward),
                                      label: const Text("Buy Subscription"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: sectionColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        textStyle: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context)
                                            .pushNamed('/subscription');
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              );
                            }
                            return Padding(
                              padding: EdgeInsets.only(
                                left: 24,
                                right: 24,
                                top: 24,
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom +
                                        32,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 40,
                                        height: 5,
                                        margin:
                                            const EdgeInsets.only(bottom: 18),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    if (data['companyName'] != null &&
                                        data['companyName']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          data['companyName'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 30,
                                          ),
                                        ),
                                      ),
                                    if (data['description'] != null &&
                                        data['description']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          data['description'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    if (data['origin'] != null &&
                                        data['origin'].toString().isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          "Origin: ${data['origin']}",
                                          style: const TextStyle(
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    if (data['ownerName'] != null &&
                                        data['ownerName'].toString().isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          "Owner: ${data['ownerName']}",
                                          style: const TextStyle(
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    if (data['rate'] != null &&
                                        data['rate'].toString().isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          "Rate: ${data['rate']}",
                                          style: const TextStyle(
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      'Posted ${_getTimeAgo(postedAt)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    if (filesForCard.isNotEmpty)
                                      SizedBox(
                                        height: 220,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: filesForCard.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 12),
                                          itemBuilder: (context, i) {
                                            final file = filesForCard[i];
                                            if (file['type'] == 'image') {
                                              return GestureDetector(
                                                onTap: () {
                                                  showFullScreenGallery(
                                                      context, filesForCard, i);
                                                },
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Image.network(
                                                    file['url'],
                                                    width: 200,
                                                    height: 200,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (ctx, err, stack) =>
                                                            Container(
                                                      color: Colors.grey[200],
                                                      alignment:
                                                          Alignment.center,
                                                      child: const Icon(
                                                          Icons.broken_image,
                                                          size: 40,
                                                          color: Colors.red),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            } else if (file['type'] ==
                                                'video') {
                                              return GestureDetector(
                                                onTap: () {
                                                  showFullScreenGallery(
                                                      context, filesForCard, i);
                                                },
                                                child: SizedBox(
                                                  width: 200,
                                                  height: 200,
                                                  child: _VideoPreview(
                                                      url: file['url']),
                                                ),
                                              );
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                      ),
                                    const SizedBox(height: 18),
                                    if (contact.toString().isNotEmpty)
                                      Center(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.phone,
                                              color: Colors.white),
                                          label: const Text('Contact'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: sectionColor,
                                            foregroundColor: Colors.white,
                                            elevation: 3,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 28, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                            textStyle: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () async {
                                            final phone = contact.toString();
                                            final url = Uri.parse('tel:$phone');
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Could not launch phone dialer')),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    const SizedBox(height: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black12,
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        child: SizedBox(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(28),
                                      topRight: Radius.circular(28),
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 400,
                                      child: mainCardMediaCarousel,
                                    ),
                                  ),
                                  Positioned(
                                    top: 18,
                                    right: 18,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'posted ${_getTimeAgo(postedAt)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (filesForCard.length > 1)
                                    Positioned(
                                      bottom: 16,
                                      left: 0,
                                      right: 0,
                                      child: StatefulBuilder(
                                        builder: (context, setState) {
                                          int currentPage = 0;
                                          final pageController =
                                              PageController();

                                          return Column(
                                            children: [
                                              SizedBox(
                                                height: 0,
                                                child: PageView.builder(
                                                  controller: pageController,
                                                  itemCount:
                                                      filesForCard.length,
                                                  onPageChanged: (page) {
                                                    setState(() {
                                                      currentPage = page;
                                                    });
                                                  },
                                                  itemBuilder:
                                                      (context, mediaIndex) {
                                                    return const SizedBox
                                                        .shrink();
                                                  },
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: List.generate(
                                                  filesForCard.length,
                                                  (dotIndex) => Container(
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 4),
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: currentPage ==
                                                              dotIndex
                                                          ? Colors.green[700]
                                                          : Colors.green[200],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(22, 22, 22, 0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 23,
                                              color: Colors.black,
                                            ),
                                          ),
                                          if (country.toString().isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 2),
                                              child: Text(
                                                country,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (_isSubscribed == true &&
                                        contact.toString().isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(
                                            left: 10, top: 2),
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.phone,
                                              color: Colors.white),
                                          label: const Text('Contact'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: sectionColor,
                                            foregroundColor: Colors.white,
                                            elevation: 3,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 18, vertical: 13),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                            textStyle: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () async {
                                            final phone = contact.toString();
                                            final url = Uri.parse('tel:$phone');
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Could not launch phone dialer')),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (_isSubscribed != true)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 22, right: 22, bottom: 16),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(
                                          color: sectionColor.withOpacity(.18)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.lock,
                                            color: sectionColor, size: 22),
                                        const SizedBox(width: 7),
                                        const Expanded(
                                          child: Text(
                                            "Subscribe to unlock contact details.",
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: sectionColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 15, vertical: 7),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pushNamed('/subscription');
                                          },
                                          child: const Text(
                                            "Subscribe",
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final String url;
  const _VideoPreview({required this.url});
  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    try {
      _controller = VideoPlayerController.network(widget.url)
        ..setLooping(true)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {
            _initialized = true;
          });
        }).catchError((e) {
          if (mounted) setState(() => _loadFailed = true);
        });
    } catch (e) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return Container(
        color: Colors.red[200],
        alignment: Alignment.center,
        child: const Text(
          "Video failed to load.",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }
    if (!_initialized ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return Container(
        alignment: Alignment.center,
        color: Colors.black12,
        child: const CircularProgressIndicator(),
      );
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
          } else {
            _controller!.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          if (!_controller!.value.isPlaying)
            const Icon(Icons.play_circle_filled_rounded,
                color: Colors.white70, size: 48),
        ],
      ),
    );
  }
}

// Utility for time-ago
String _getTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
  return '${(diff.inDays / 365).floor()} years ago';
}

// 2. Add this helper for fullscreen gallery:
void showFullScreenGallery(
    BuildContext context, List filesForCard, int initialIndex) {
  showDialog(
    context: context,
    builder: (context) {
      PageController controller = PageController(initialPage: initialIndex);
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: controller,
              itemCount: filesForCard.length,
              itemBuilder: (context, i) {
                final file = filesForCard[i];
                if (file['type'] == 'image') {
                  return PhotoView(
                    imageProvider: NetworkImage(file['url']),
                    backgroundDecoration:
                        const BoxDecoration(color: Colors.black),
                  );
                } else if (file['type'] == 'video') {
                  return Center(
                    child: _VideoPreview(url: file['url']),
                  );
                }
                return const SizedBox();
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      );
    },
  );
}
