// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class ExploreScreen extends StatefulWidget {
//   const ExploreScreen({super.key});

//   @override
//   State<ExploreScreen> createState() => _ExploreScreenState();
// }

// class _ExploreScreenState extends State<ExploreScreen>
//     with AutomaticKeepAliveClientMixin {
//   bool get wantKeepAlive => true;

//   final List<Map<String, String>> buttonData = [
//     {'text': 'Fruits', 'route': '/fruits', 'image': 'assets/fruit_banners/exoticfruits.jpg'},
//     {
//       'text': 'Transport',
//       'route': '/transport',
//       'image': 'assets/transport.jpg'
//     },
//     {
//       'text': 'Cold Storage',
//       'route': '/storage',
//       'image': 'assets/coldstorage.jpg'
//     },
//     {'text': 'Agents', 'route': '/agents', 'image': 'assets/agent.jpg'},
//   ];

//   // Pagination helpers
//   final ScrollController _scrollController = ScrollController();
//   final int _pageSize = 4;
//   final List<Map<String, String>> _allButtons = [];
//   final List<Map<String, String>> _displayedButtons = [];
//   bool _isLoadingMore = false;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // initialize pagination lists once
//     if (_allButtons.isEmpty) {
//       _allButtons.addAll(buttonData);
//       _displayedButtons.addAll(_allButtons.take(
//           _pageSize > _allButtons.length ? _allButtons.length : _pageSize));
//     }

//     // precache displayed images (assets or network)
//     for (var item in _displayedButtons) {
//       final img = item['image']!;
//       if (img.startsWith('http')) {
//         // cached_network_image handles caching; still optionally prefetch
//         CachedNetworkImageProvider(img).resolve(const ImageConfiguration());
//       } else {
//         precacheImage(AssetImage(img), context);
//       }
//     }

//     _scrollController.addListener(_onScroll);
//   }

//   @override
//   void dispose() {
//     _scrollController.removeListener(_onScroll);
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _onScroll() {
//     if (_scrollController.position.pixels >=
//             _scrollController.position.maxScrollExtent - 200 &&
//         !_isLoadingMore &&
//         _displayedButtons.length < _allButtons.length) {
//       _loadMore();
//     }
//   }

//   void _loadMore() async {
//     if (_isLoadingMore) return;
//     setState(() => _isLoadingMore = true);
//     await Future.delayed(const Duration(milliseconds: 200));
//     final nextIndex = _displayedButtons.length;
//     final end = (nextIndex + _pageSize) > _allButtons.length
//         ? _allButtons.length
//         : nextIndex + _pageSize;
//     setState(() {
//       _displayedButtons.addAll(_allButtons.sublist(nextIndex, end));
//       // pre-cache newly added images
//       for (var item in _displayedButtons.sublist(nextIndex, end)) {
//         final img = item['image']!;
//         if (img.startsWith('http')) {
//           CachedNetworkImageProvider(img).resolve(const ImageConfiguration());
//         } else {
//           precacheImage(AssetImage(img), context);
//         }
//       }
//       _isLoadingMore = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: const Text(
//           'Barkati Fruits',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontFamily: 'ComicNeue',
//             fontWeight: FontWeight.bold,
//             fontSize: 24,
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 12.0),
//             child: GestureDetector(
//               onTap: () {
//                 Navigator.pushNamed(context, '/subscription');
//               },
//               child: Icon(
//                 FontAwesomeIcons.crown,
//                 color: Colors.yellow[700],
//                 size: 30,
//               ),
//             ),
//           )
//         ],
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.black,
//         elevation: 1,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewPadding.bottom +
//                 20, // <-- This raises the nav bar above system buttons
//           ),
//           child: Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFFF7F8FA), Color(0xFFE3F0FF)],
//                 begin: Alignment.bottomLeft,
//                 end: Alignment.topRight,
//               ),
//             ),
//             child: ListView.separated(
//               controller: _scrollController,
//               padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
//               itemCount: _displayedButtons.length + (_isLoadingMore ? 1 : 0),
//               separatorBuilder: (context, index) => const SizedBox(height: 20),
//               itemBuilder: (context, index) {
//                 if (index >= _displayedButtons.length) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 final item = _displayedButtons[index];
//                 return _AnimatedExploreCard(
//                   image: item['image']!,
//                   label: item['text']!,
//                   onTap: () {
//                     Navigator.pushNamed(context, item['route']!);
//                   },
//                   delay: 100 * index,
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _AnimatedExploreCard extends StatefulWidget {
//   final String image;
//   final String label;
//   final VoidCallback onTap;
//   final int delay;

//   const _AnimatedExploreCard({
//     required this.image,
//     required this.label,
//     required this.onTap,
//     required this.delay,
//   });

//   @override
//   State<_AnimatedExploreCard> createState() => _AnimatedExploreCardState();
// }

// class _AnimatedExploreCardState extends State<_AnimatedExploreCard>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fade;
//   late Animation<double> _scale;
//   bool _pressed = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//     _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
//     _scale = Tween<double>(begin: 0.97, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
//     );
//     Future.delayed(Duration(milliseconds: widget.delay), () {
//       if (mounted) _controller.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void _onTapDown(_) => setState(() => _pressed = true);
//   void _onTapUp(_) => setState(() => _pressed = false);

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _fade,
//       child: ScaleTransition(
//         scale: _scale,
//         child: GestureDetector(
//           onTap: widget.onTap,
//           onTapDown: _onTapDown,
//           onTapUp: _onTapUp,
//           onTapCancel: () => setState(() => _pressed = false),
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 150),
//             curve: Curves.easeOut,
//             height: 160, // Increased from 120 to 160
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(22),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(_pressed ? 0.10 : 0.18),
//                   blurRadius: _pressed ? 8 : 16,
//                   offset: const Offset(0, 6),
//                 ),
//               ],
//             ),
//             child: Stack(
//               fit: StackFit.expand,
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(22),
//                   child: widget.image.startsWith('http')
//                       ? CachedNetworkImage(
//                           imageUrl: widget.image,
//                           fit: BoxFit.cover,
//                           placeholder: (context, url) => Container(
//                             color: Colors.grey[300],
//                             child: const Center(
//                                 child:
//                                     CircularProgressIndicator(strokeWidth: 2)),
//                           ),
//                           errorWidget: (context, url, error) => Image.asset(
//                             'assets/placeholder.jpg',
//                             fit: BoxFit.cover,
//                           ),
//                         )
//                       : Image.asset(
//                           widget.image,
//                           fit: BoxFit.cover,
//                           cacheWidth: 800,
//                         ),
//                 ),
//                 Container(
//                   height: 250,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(22),
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [
//                         Colors.black.withOpacity(0.35),
//                         Colors.transparent,
//                         Colors.green.withOpacity(0.10),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Align(
//                   alignment: Alignment.bottomLeft,
//                   child: Padding(
//                     padding: const EdgeInsets.all(18.0),
//                     child: Text(
//                       widget.label,
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         fontFamily: 'ComicNeue',
//                         color: Colors.white,
//                         shadows: [
//                           Shadow(
//                             offset: Offset(2, 2),
//                             blurRadius: 8,
//                             color: Colors.black54,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
