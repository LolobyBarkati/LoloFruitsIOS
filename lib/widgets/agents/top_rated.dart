import 'package:barkati_frits/widgets/agents/agents_bottom.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class TopRatedCard extends StatelessWidget {
  final DocumentSnapshot doc;
  const TopRatedCard({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    return GestureDetector(
      onTap: () => AgentDetailsSheet.show(context, doc),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.teal, width: 2)),
                  child: CircleAvatar(radius: 35, backgroundImage: NetworkImage(data['image_url'] ?? '')),
                ),
                const CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.star, size: 12, color: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 5),
            Text(data['name']?.split(' ')[0] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}