// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// import 'package:photo_view/photo_view.dart';
// import 'package:photo_view/photo_view_gallery.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:barkati_frits/screens/subscription_screen.dart';
// import 'package:barkati_frits/screens/storage_screen.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
// import 'dart:typed_data';

// class FavoritesScreen extends StatefulWidget {
//   static const String routeName = '/discover';
//   const FavoritesScreen({super.key});

//   @override
//   State<FavoritesScreen> createState() => _DiscoverScreenState();
// }

// class _DiscoverScreenState extends State<FavoritesScreen> {
//   bool? isSubscribed;

//   @override
//   void initState() {
//     super.initState();
//     _checkSubscriptionByEmail();
//   }

//   Future<void> _checkSubscriptionByEmail() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       setState(() => isSubscribed = false);
//       return;
//     }
//     final email = user.email;
//     if (email == null) {
//       setState(() => isSubscribed = false);
//       return;
//     }
//     try {
//       final querySnapshot = await FirebaseFirestore.instance
//           .collection('payments')
//           .where('email', isEqualTo: email)
//           .limit(1)
//           .get();
//       if (querySnapshot.docs.isEmpty) {
//         setState(() => isSubscribed = false);
//         return;
//       }
//       final data = querySnapshot.docs.first.data();
//       final Timestamp? expiry = data['subscription_expiry'];
//       final bool status = data['status'] ?? false;
//       if (expiry == null || expiry.toDate().isBefore(DateTime.now())) {
//         await querySnapshot.docs.first.reference.update({'status': false});
//         setState(() => isSubscribed = false);
//       } else {
//         setState(() => isSubscribed = status);
//       }
//     } catch (e) {
//       debugPrint('Error checking subscription: $e');
//       setState(() => isSubscribed = false);
//     }
//   }

//   Widget _buildSubscriptionPrompt(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.95),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 2,
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.lock_outline,
//             size: 60,
//             color: Colors.teal.shade400,
//           ),
//           const SizedBox(height: 20),
//           Text(
//             "Access Exclusive Data",
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: Colors.teal.shade700,
//             ),
//           ),
//           const SizedBox(height: 12),
//           const Text(
//             "A subscription unlocks detailed cold storage listings, direct contact information, and more.",
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.grey, fontSize: 15),
//           ),
//           const SizedBox(height: 30),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const SubscriptionScreen(),
//                 ),
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.teal,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               elevation: 3,
//             ),
//             child: const Text(
//               'View Subscription Plans',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Discover'),
//           backgroundColor: Colors.blue,
//           foregroundColor: Colors.black87,
//           elevation: 0.5,
//           bottom: TabBar(
//             labelColor: Colors.white,
//             unselectedLabelColor: Colors.black54,
//             indicatorColor: Colors.blue,
//             tabs: const [
//               Tab(text: 'Fruits'),
//               Tab(text: 'Cold Storage'),
//               Tab(text: 'Agents'),
//             ],
//           ),
//         ),
//         body: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Colors.teal.shade50,
//                 Colors.teal.shade100,
//               ],
//             ),
//           ),
//           child: isSubscribed == null
//               ? const Center(child: CircularProgressIndicator.adaptive())
//               : isSubscribed == false
//                   ? Center(
//                       child: Padding(
//                         padding: const EdgeInsets.all(24.0),
//                         child: _buildSubscriptionPrompt(context),
//                       ),
//                     )
//                   : const TabBarView(
//                       children: [
//                         FruitsGridTab(),
//                         // ColdStorageListTab(),
//                         // AgentsListTab(),
//                       ],
//                     ),
//         ),
//         backgroundColor: const Color(0xFFF7F8FA),
//       ),
//     );
//   }
// }

// // ... (RotatingBanner and other classes remain as is) ...

// /// A tab that displays a grid of fruits fetched from Firestore.
// /// Each fruit item navigates to a details sheet on tap.
// class FruitsGridTab extends StatelessWidget {
//   const FruitsGridTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<QuerySnapshot>(
//       future: FirebaseFirestore.instance
//           .collection('offer')
//           .doc('fruit')
//           .collection('fruit')
//           .get(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const Center(child: Text('No fruits found.'));
//         }
//         final docs = snapshot.data!.docs;
//         return ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: docs.length,
//           itemBuilder: (context, index) {
//             final data = docs[index].data() as Map<String, dynamic>;
//             final List media = data['media'] ?? [];
//             final String imageUrl = media.isNotEmpty ? media.first : '';
//             final String name = data['fruit_name'] ?? 'No Name';
//             final String description = data['description'] ?? '';
//             final String price =
//                 data['price'] != null ? '₹${data['price']}' : '';
//             final String location = data['origin'] ?? '';
//             final String seller = data['contact'] ?? '';

//             return _FruitCard(
//               name: name,
//               description: description,
//               price: price,
//               location: location,
//               seller: seller,
//               images: media.cast<String>(),
//             );
//           },
//         );
//       },
//     );
//   }
// }

// /// A card widget for displaying fruit information in a grid.
// /// Includes an image/video carousel, title, description, price, location, seller info, and a buy button.
// class _FruitCard extends StatefulWidget {
//   final String name;
//   final String description;
//   final String price;
//   final String location;
//   final String seller;
//   final List<String> images;

//   const _FruitCard({
//     required this.name,
//     required this.description,
//     required this.price,
//     required this.location,
//     required this.seller,
//     required this.images,
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<_FruitCard> createState() => _FruitCardState();
// }

// class _FruitCardState extends State<_FruitCard> {
//   late final PageController _pageController;
//   int _currentPage = 0;
//   Timer? _timer;

//   late final List<String> images;
//   late final List<String> videos;
//   late final List<String> allMedia; // images first, then videos

//   VideoPlayerController? _videoController;
//   ChewieController? _chewieController;
//   int? _playingVideoIndex;

//   @override
//   void initState() {
//     super.initState();
//     images = widget.images
//         .where((url) => !(url.toLowerCase().endsWith('.mp4') ||
//             url.toLowerCase().endsWith('.mov') ||
//             url.toLowerCase().endsWith('.avi') ||
//             url.toLowerCase().endsWith('.mkv')))
//         .toList();
//     videos = widget.images
//         .where((url) =>
//             url.toLowerCase().endsWith('.mp4') ||
//             url.toLowerCase().endsWith('.mov') ||
//             url.toLowerCase().endsWith('.avi') ||
//             url.toLowerCase().endsWith('.mkv'))
//         .toList();
//     allMedia = [...images, ...videos];

//     _pageController = PageController();
//     if (allMedia.length > 1) {
//       _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
//         if (!mounted) return;
//         int nextPage = (_currentPage + 1) % allMedia.length;
//         _pageController.animateToPage(
//           nextPage,
//           duration: const Duration(milliseconds: 500),
//           curve: Curves.easeInOut,
//         );
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _pageController.dispose();
//     _chewieController?.dispose();
//     _videoController?.dispose();
//     super.dispose();
//   }

//   Future<void> _playInlineVideo(String url, int index) async {
//     if (_playingVideoIndex == index &&
//         _chewieController != null &&
//         _videoController != null) {
//       // Already playing this one
//       return;
//     }
//     _chewieController?.dispose();
//     _videoController?.dispose();
//     _videoController = VideoPlayerController.network(url);
//     await _videoController!.initialize();
//     _chewieController = ChewieController(
//       videoPlayerController: _videoController!,
//       autoPlay: true,
//       looping: false,
//       allowMuting: true,
//       allowFullScreen: true,
//     );
//     setState(() {
//       _playingVideoIndex = index;
//     });
//   }

//   void _stopInlineVideo() {
//     _chewieController?.pause();
//     setState(() {
//       _playingVideoIndex = null;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(18),
//       ),
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 24),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // --- Image/Video Carousel ---
//             SizedBox(
//               height: 180,
//               child: allMedia.isNotEmpty
//                   ? Stack(
//                       children: [
//                         PageView.builder(
//                           controller: _pageController,
//                           itemCount: allMedia.length,
//                           onPageChanged: (index) {
//                             setState(() {
//                               _currentPage = index;
//                               if (_playingVideoIndex != null) {
//                                 _stopInlineVideo();
//                               }
//                             });
//                           },
//                           itemBuilder: (context, idx) {
//                             final url = allMedia[idx];
//                             final isVideo =
//                                 url.toLowerCase().endsWith('.mp4') ||
//                                     url.toLowerCase().endsWith('.mov') ||
//                                     url.toLowerCase().endsWith('.avi') ||
//                                     url.toLowerCase().endsWith('.mkv');
//                             if (!isVideo) {
//                               // Image: tap to zoom full screen
//                               return GestureDetector(
//                                 onTap: () {
//                                   final imageIndex = images.indexOf(url);
//                                   if (imageIndex != -1) {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) => FullScreenGallery(
//                                           images: images,
//                                           initialIndex: imageIndex,
//                                         ),
//                                       ),
//                                     );
//                                   }
//                                 },
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(14),
//                                   child: Image.network(
//                                     url,
//                                     width: double.infinity,
//                                     height: 180,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (c, e, s) => Container(
//                                       color: Colors.grey[300],
//                                       child: const Icon(Icons.image,
//                                           size: 60, color: Colors.grey),
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             } else {
//                               // Video: play inline if selected, else show a play icon thumbnail
//                               if (_playingVideoIndex == idx &&
//                                   _chewieController != null) {
//                                 return GestureDetector(
//                                   onTap: _stopInlineVideo,
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(14),
//                                     child: Chewie(controller: _chewieController!),
//                                   ),
//                                 );
//                               } else {
//                                 return GestureDetector(
//                                   onTap: () => _playInlineVideo(url, idx),
//                                   child: FutureBuilder<Uint8List?>(
//                                     future: VideoThumbnail.thumbnailData(
//                                       video: url,
//                                       imageFormat: ImageFormat.JPEG,
//                                       maxWidth: 80,
//                                       quality: 10,
//                                     ),
//                                     builder: (context, snapshot) {
//                                       if (snapshot.connectionState ==
//                                               ConnectionState.done &&
//                                           snapshot.data != null) {
//                                         return Stack(
//                                           alignment: Alignment.center,
//                                           children: [
//                                             ClipRRect(
//                                               borderRadius:
//                                                   BorderRadius.circular(14),
//                                               child: Image.memory(
//                                                 snapshot.data!,
//                                                 width: double.infinity,
//                                                 height: 180,
//                                                 fit: BoxFit.cover,
//                                               ),
//                                             ),
//                                             const Icon(Icons.play_circle_fill,
//                                                 size: 64, color: Colors.white70),
//                                           ],
//                                         );
//                                       } else {
//                                         return Container(
//                                           width: double.infinity,
//                                           height: 180,
//                                           decoration: BoxDecoration(
//                                             color: Colors.black12,
//                                             borderRadius:
//                                                 BorderRadius.circular(14),
//                                           ),
//                                           child: const Center(
//                                             child: Icon(Icons.play_circle_fill,
//                                                 size: 64, color: Colors.white70),
//                                           ),
//                                         );
//                                       }
//                                     },
//                                   ),
//                                 );
//                               }
//                             }
//                           },
//                         ),
//                         // --- Page Indicator Dots ---
//                         if (allMedia.length > 1)
//                           Positioned(
//                             bottom: 8,
//                             left: 0,
//                             right: 0,
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: List.generate(
//                                 allMedia.length,
//                                 (idx) => AnimatedContainer(
//                                   duration: const Duration(milliseconds: 300),
//                                   margin:
//                                       const EdgeInsets.symmetric(horizontal: 3),
//                                   width: _currentPage == idx ? 16 : 8,
//                                   height: 8,
//                                   decoration: BoxDecoration(
//                                     color: _currentPage == idx
//                                         ? Colors.blue
//                                         : Colors.white70,
//                                     borderRadius: BorderRadius.circular(4),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                       ],
//                     )
//                   : Container(
//                       width: double.infinity,
//                       height: 180,
//                       color: Colors.grey[300],
//                       child:
//                           const Icon(Icons.image, size: 60, color: Colors.grey),
//                     ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               widget.name,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             if (widget.description.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 4.0),
//                 child: Text(
//                   widget.description,
//                   style: const TextStyle(fontSize: 14, color: Colors.black87),
//                 ),
//               ),
//             const SizedBox(height: 8),
//             Text.rich(
//               TextSpan(
//                 children: [
//                   const TextSpan(
//                     text: 'Price: ',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                   TextSpan(
//                     text: widget.price,
//                     style: const TextStyle(
//                         fontWeight: FontWeight.bold, fontSize: 16),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 4),
//             if (widget.location.isNotEmpty)
//               Text(
//                 'Location: ${widget.location}',
//                 style: const TextStyle(color: Colors.grey, fontSize: 14),
//               ),
//             if (widget.seller.isNotEmpty)
//               Text(
//                 'Seller: ${widget.seller}',
//                 style: const TextStyle(color: Colors.grey, fontSize: 14),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ... (Rest of your code: FruitDetailsSheet, VideoDialog, ColdStorageListTab, ColdStorageDetailsSheet, AgentsListTab remains unchanged.)

// /// A simple full screen gallery for images.
// class FullScreenGallery extends StatelessWidget {
//   final List<String> images;
//   final int initialIndex;

//   const FullScreenGallery({
//     Key? key,
//     required this.images,
//     this.initialIndex = 0,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           PhotoViewGallery.builder(
//             itemCount: images.length,
//             pageController: PageController(initialPage: initialIndex),
//             builder: (context, index) {
//               return PhotoViewGalleryPageOptions(
//                 imageProvider: NetworkImage(images[index]),
//                 minScale: PhotoViewComputedScale.contained,
//                 maxScale: PhotoViewComputedScale.covered * 2,
//               );
//             },
//             backgroundDecoration: const BoxDecoration(
//               color: Colors.black,
//             ),
//           ),
//           Positioned(
//             top: 40,
//             left: 16,
//             child: IconButton(
//               icon: const Icon(Icons.close, color: Colors.white, size: 32),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }