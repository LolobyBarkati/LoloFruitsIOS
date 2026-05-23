import 'package:barkati_frits/screens/offer2edit.dart';
import 'package:barkati_frits/services/auto_cleanup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'explore.dart';


class HomeScreen extends StatefulWidget {
  static String routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _page = 0;

  @override
  void initState() {
    super.initState();
    AutoCleanupService.runIfDue();
  }

  final List<Widget> _pages = [
    const ExploreScreen2(),
    const Offer2edit(),
  
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
          color: isSelected ? Colors.blue.withValues(alpha: 0.5) : Colors.transparent,
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: _pages[_page],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_filled, "Explore", 0),
              _buildNavItem(Icons.new_releases, "New Arrivals", 1),
            ],
          ),
        ),
      ),
    );
  }
}
