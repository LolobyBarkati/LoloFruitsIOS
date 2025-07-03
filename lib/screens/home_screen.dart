import 'package:barkati_frits/screens/offer2edit.dart';

// import 'package:barkati_frits/screens/offerscreen.dart';
import 'package:flutter/material.dart';
import 'explore_screen.dart';
// import 'favorites_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _page = 0;

  final List<Widget> _pages = [
    const ExploreScreen(),
    const Offer2edit(),
    const ProfileScreen(),
  ];

  void onPageChange(int index) {
    setState(() {
      _page = index;
    });
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _page == index;
    return GestureDetector(
      onTap: () => onPageChange(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 20 : 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.grey),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _pages[_page],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.explore, "Explore", 0),
                  _buildNavItem(Icons.new_releases, "New Arrivals", 1),
                  _buildNavItem(Icons.person_rounded, "Profile", 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
