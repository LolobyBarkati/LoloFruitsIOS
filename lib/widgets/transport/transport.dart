import 'package:barkati_frits/screens/transport_screen.dart';
import 'package:barkati_frits/utils/utils.dart';
import 'package:flutter/material.dart';

class HomeTransportBox extends StatelessWidget {
  const HomeTransportBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'Transport',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        AspectRatio(
          aspectRatio: 1,
          child: InkWell(
            onTap: () {
              if (isGuestUser()) {
                showLoginRequired(context);
                return;
              }
              Navigator.pushNamed(context, TransportScreen.routeName);
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 70,  // ← move right
                    top: 60,   // ↓ move down
                  ),
                  child: Transform.scale(
                    scale: 1.9, // 🔍 zoom
                    child: Image.asset(
                      'assets/truckui.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}