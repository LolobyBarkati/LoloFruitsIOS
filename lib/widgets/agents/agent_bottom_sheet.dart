import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AgentBottomSheet extends StatefulWidget {
  final String agentId, name, imageUrl, phone;
  final double avgRating;
  final ScrollController scrollController;

  const AgentBottomSheet({
    super.key,
    required this.agentId,
    required this.name,
    required this.imageUrl,
    required this.phone,
    required this.avgRating,
    required this.scrollController,
  });

  // Static method to trigger the sheet easily
  static void show(BuildContext context, String id, String name, String img, String phone, double rating) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AgentBottomSheet(
          agentId: id,
          name: name,
          imageUrl: img,
          phone: phone,
          avgRating: rating,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  State<AgentBottomSheet> createState() => _AgentBottomSheetState();
}

class _AgentBottomSheetState extends State<AgentBottomSheet> {
  final TextEditingController feedbackController = TextEditingController();
  int selectedRating = 0;
  bool isSubmitting = false;
  bool hasAlreadyRated = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingRating();
  }

  Future<void> _loadExistingRating() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => isLoading = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('agent_feedback').doc(widget.agentId)
        .collection('feedbacks').doc(uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        selectedRating = (data['rating'] as num).toInt();
        feedbackController.text = data['feedback'] ?? '';
        hasAlreadyRated = true;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _submitFeedback() async {
    if (selectedRating == 0) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => isSubmitting = true);
    
    await FirebaseFirestore.instance.collection('agent_feedback').doc(widget.agentId).collection('feedbacks').doc(uid).set({
      'feedback': feedbackController.text.trim(),
      'rating': selectedRating,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': uid,
    });
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 25),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(radius: 50, backgroundImage: widget.imageUrl.isNotEmpty ? NetworkImage(widget.imageUrl) : null),
                      const Positioned(bottom: 0, right: 0, child: Icon(Icons.verified_rounded, color: Color(0xFF2196F3), size: 30)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(widget.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text("Verified Service Professional", style: TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri(scheme: 'tel', path: widget.phone)),
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: const Text("Contact Verified Agent", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF80C031), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const Divider(height: 40),
                  const Text("Customer Feedback", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) => IconButton(
                      icon: Icon(index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 35),
                      onPressed: () => setState(() => selectedRating = index + 1),
                    )),
                  ),
                  TextField(
                    controller: feedbackController,
                    maxLines: 2,
                    decoration: InputDecoration(hintText: "Review your experience", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text(hasAlreadyRated ? "Update Review" : "Submit Review", style: const TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}