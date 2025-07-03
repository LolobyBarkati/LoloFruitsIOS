import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true;

  final List<Map<String, String>> buttonData = [
    {'text': 'Fruits', 'route': '/fruits', 'image': 'assets/fruits.png'},
    {
      'text': 'Transport',
      'route': '/transport',
      'image': 'assets/transport.jpg'
    },
    {
      'text': 'Cold Storage',
      'route': '/storage',
      'image': 'assets/coldstorage.jpg'
    },
    {'text': 'Agents', 'route': '/agents', 'image': 'assets/agent.jpg'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (var item in buttonData) {
      precacheImage(AssetImage(item['image']!), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Barkati Fruits',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'ComicNeue',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/subscription');
              },
              child: const Icon(
                Icons.subscriptions,
                color: Colors.black,
                size: 30,
              ),
            ),
          )
        ],
        backgroundColor: Colors.blue,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom + 20, // <-- This raises the nav bar above system buttons
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7F8FA), Color(0xFFE3F0FF)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
              itemCount: buttonData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final item = buttonData[index];
                return _AnimatedExploreCard(
                  image: item['image']!,
                  label: item['text']!,
                  onTap: () {
                    Navigator.pushNamed(context, item['route']!);
                  },
                  delay: 100 * index,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedExploreCard extends StatefulWidget {
  final String image;
  final String label;
  final VoidCallback onTap;
  final int delay;

  const _AnimatedExploreCard({
    required this.image,
    required this.label,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_AnimatedExploreCard> createState() => _AnimatedExploreCardState();
}

class _AnimatedExploreCardState extends State<_AnimatedExploreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => setState(() => _pressed = true);
  void _onTapUp(_) => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            height: 160, // Increased from 120 to 160
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_pressed ? 0.10 : 0.18),
                  blurRadius: _pressed ? 8 : 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    widget.image,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.35),
                        Colors.transparent,
                        Colors.green.withOpacity(0.10),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ComicNeue',
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 8,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
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
