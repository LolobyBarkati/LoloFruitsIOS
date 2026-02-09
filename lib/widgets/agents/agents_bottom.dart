import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgentDetailsSheet {
  static DateTime? _lastSubmitTime;

  static void show(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    int selectedRating = 0;
    final feedbackCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setST) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 40, backgroundImage: NetworkImage(data['image_url'] ?? '')),
              const SizedBox(height: 10),
              Text(data['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(i < selectedRating ? Icons.star : Icons.star_border, color: Colors.amber),
                  onPressed: () => setST(() => selectedRating = i + 1),
                )),
              ),
              TextField(controller: feedbackCtrl, decoration: const InputDecoration(hintText: "Leave a comment...")),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 50)),
                onPressed: () async {
                  // Rate Limiting: 10 second gap
                  final now = DateTime.now();
                  if (_lastSubmitTime != null && now.difference(_lastSubmitTime!).inSeconds < 10) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wait a moment before rating again")));
                    return;
                  }
                  
                  if (selectedRating == 0) return;
                  _lastSubmitTime = now;

                  await FirebaseFirestore.instance.collection('agent_feedback').add({
                    'agentId': doc.id,
                    'rating': selectedRating,
                    'comment': feedbackCtrl.text,
                    'userId': FirebaseAuth.instance.currentUser?.uid,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                },
                child: const Text("Submit", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}