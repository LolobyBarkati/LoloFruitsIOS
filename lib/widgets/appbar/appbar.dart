import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onPremiumTap;
  final bool isSubscribed; // This controls the text

  const HomeAppBar({
    super.key,
    this.onProfileTap,
    this.onNotificationTap,
    this.onPremiumTap,
    this.isSubscribed = false, // Default is false
  });

  @override
  Size get preferredSize => const Size.fromHeight(130);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                  child: Hero(
                    tag: 'profile-avatar',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white10, width: 1),
                      ),
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white10,
                        child: Icon(Icons.person_outline, color: Colors.white70),
                      ),
                    ),
                  ),
                ),
                const Text(
                  'Lolo Fruits',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: onNotificationTap,
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.notifications_none, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 🔥 Shining Button - text changes based on isSubscribed
            _ShiningButton(onTap: onPremiumTap, isSubscribed: isSubscribed),
          ],
        ),
      ),
    );
  }
}

class _ShiningButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isSubscribed;
  const _ShiningButton({this.onTap, this.isSubscribed = false});

  @override
  State<_ShiningButton> createState() => _ShiningButtonState();
}

class _ShiningButtonState extends State<_ShiningButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Only allow tap if NOT subscribed, or keep tap for 'Manage Subscription'
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          Navigator.pushNamed(context, '/subscription');
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [
                  _controller.value - 0.2,
                  _controller.value,
                  _controller.value + 0.2,
                ],
                colors: [
                  Colors.white.withOpacity(0),
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0),
                ],
              ).createShader(rect);
            },
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            // Change color to Greenish-Gold if subscribed for a "Verified" feel
            gradient: LinearGradient(
              colors: widget.isSubscribed 
                ? [Colors.green.shade700, Colors.green.shade400] 
                : [Colors.amber.shade700, Colors.amber.shade400],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (widget.isSubscribed ? Colors.green : Colors.amber).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isSubscribed ? Icons.verified_user : Icons.stars_rounded, 
                size: 18, 
                color: Colors.black, // Changed to white for better contrast
              ),
              const SizedBox(width: 8),
              Text(
                widget.isSubscribed ? 'PREMIUM USER' : 'UPGRADE TO PREMIUM',
                style: const TextStyle(
                    color: Colors.black, // Changed to white for better contrast
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}