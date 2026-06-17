import 'package:barkati_frits/screens/agents_screen.dart';
import 'package:barkati_frits/utils/utils.dart';
import 'package:flutter/material.dart';

class HomeAgentBox extends StatelessWidget {
  const HomeAgentBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'Agents',
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
              Navigator.pushNamed(context, AgentsScreen.routeName);
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
                    left: 20,  // ← move right
                    top: 9,   // ↓ move down
                  ),
                  child: Transform.scale(
                    scale: 1.6, // 🔍 zoom
                    child: Image.asset(
                      'assets/agents2.png',
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