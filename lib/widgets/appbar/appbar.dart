import 'package:flutter/material.dart';
import 'package:barkati_frits/screens/profile.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onPremiumTap;
  final bool isSubscribed;

  const HomeAppBar({
    super.key,
    this.onNotificationTap,
    this.onPremiumTap,
    this.isSubscribed = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(130);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.lightGreen,
        // Subtle bottom shadow to separate AppBar from body
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, ProfileScreen.routeName),
                  child: Hero(
                    tag: 'profile-avatar',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Improved border clarity
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withOpacity(0.2), // Frosted glass effect
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Lolo Fruits',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20, // Slightly more legible
                          letterSpacing: -0.5, // Modern tighter kerning
                          fontWeight: FontWeight.w900), // Bolder for brand presence
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
            const SizedBox(height: 12),
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
      duration: const Duration(milliseconds: 2500), // Slightly slower for elegance
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
                  _controller.value - 0.25, // Adjusted stops for smoother gradient
                  _controller.value,
                  _controller.value + 0.25,
                ],
                colors: [
                  Colors.white.withOpacity(0),
                  Colors.white.withOpacity(0.5), // Brighter shine center
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
            gradient: LinearGradient(
              begin: Alignment.topCenter, // Added verticality for depth
              end: Alignment.bottomCenter,
              colors: widget.isSubscribed 
                ? [Colors.green.shade600, Colors.green.shade800] 
                : [Colors.amber.shade400, Colors.amber.shade700],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (widget.isSubscribed ? Colors.green : Colors.amber).withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: -2, // Professional tight shadow
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isSubscribed ? Icons.verified_rounded : Icons.stars_rounded, 
                size: 18, 
                color: Colors.black.withOpacity(0.85), // Slightly softened black
              ),
              const SizedBox(width: 8),
              Text(
                widget.isSubscribed ? 'PREMIUM USER' : 'UPGRADE TO PREMIUM',
                style: TextStyle(
                    color: Colors.black.withOpacity(0.85),
                    fontWeight: FontWeight.w900, // Thicker weight for a "solid" look
                    letterSpacing: 1.1, // Improved uppercase legibility
                    fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}