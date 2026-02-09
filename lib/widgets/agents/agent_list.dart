import 'package:barkati_frits/widgets/agents/agents_bottom.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AgentListTile extends StatelessWidget {
  final DocumentSnapshot doc;

  const AgentListTile({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    // Safely extract data
    final data = doc.data() as Map<String, dynamic>?;
    
    final String name = data?['name'] ?? 'Unknown Agent';
    final String phone = data?['phone'] ?? 'No Phone';
    final String imageUrl = data?['image_url'] ?? '';
    final double rating = (data?['rating'] ?? 0.0).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.teal.shade50,
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty 
              ? Icon(Icons.person, color: Colors.teal.shade700) 
              : null,
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(phone, style: TextStyle(color: Colors.grey.shade600)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        onTap: () => AgentDetailsSheet.show(context, doc),
      ),
    );
  }
}