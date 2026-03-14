import 'package:barkati_frits/models/subscription/subscription_status.dart';
import 'package:barkati_frits/screens/subscription_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AgentsScreen extends StatefulWidget {
  static const String routeName = '/agents';
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Service Agents',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade700, Colors.teal.shade50],
            stops: const [0.0, 0.2], // Creates a smooth blend from the AppBar
          ),
        ),
        child: SubscriptionWrapper(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('agents')
                .orderBy('rating', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator.adaptive());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No agents found.',
                      style: TextStyle(color: Colors.teal, fontSize: 16)),
                );
              }

              final allAgents = snapshot.data!.docs;
              final topAgents = allAgents.take(3).toList();
              final otherAgents = allAgents.skip(3).toList();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- TOP RATED HORIZONTAL SECTION ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Row(
                        children: const [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text("Top Rated",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 150,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: topAgents.length,
                        itemBuilder: (context, index) {
                          var agent = topAgents[index];
                          return TopRatedAgentCard(
                            agentId: agent.id,
                            name: agent.get('name') ?? 'Unknown',
                            imageUrl: agent.get('image_url') ?? '',
                            phone: agent.get('phone') ?? 'N/A',
                            avgRating: (agent.get('rating') ?? 0).toDouble(),
                          );
                        },
                      ),
                    ),
                  ),

                  // --- ALL AGENTS VERTICAL SECTION ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: Text("All Available Agents",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade900)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        var agent = otherAgents[index];
                        return AgentCard(
                          agentId: agent.id,
                          name: agent.get('name') ?? 'Unknown',
                          imageUrl: agent.get('image_url') ?? '',
                          phone: agent.get('phone') ?? 'N/A',
                          avgRating: (agent.get('rating') ?? 0).toDouble(),
                        );
                      },
                      childCount: otherAgents.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// --- TOP RATED CIRCULAR AVATAR CARDS ---
class TopRatedAgentCard extends StatelessWidget {
  final String agentId, name, imageUrl, phone;
  final double avgRating;

  const TopRatedAgentCard({
    super.key,
    required this.agentId,
    required this.name,
    required this.imageUrl,
    required this.phone,
    required this.avgRating,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AgentCard(
        agentId: agentId,
        name: name,
        imageUrl: imageUrl,
        phone: phone,
        avgRating: avgRating,
      )._showAgentBottomSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.amber.shade400,
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.person, size: 45, color: Colors.teal)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child:
                        const Icon(Icons.star, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 100,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- HORIZONTAL CARD FOR TOP 3 ---
class FeaturedAgentCard extends StatelessWidget {
  final String agentId, name, imageUrl, phone;
  final double avgRating;

  const FeaturedAgentCard({
    super.key,
    required this.agentId,
    required this.name,
    required this.imageUrl,
    required this.phone,
    required this.avgRating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () => AgentCard(
                  agentId: agentId,
                  name: name,
                  imageUrl: imageUrl,
                  phone: phone,
                  avgRating: avgRating)
              ._showAgentBottomSheet(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.teal.shade50,
                  backgroundImage:
                      imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade800, size: 14),
                      const SizedBox(width: 4),
                      Text(avgRating.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- STANDARD VERTICAL CARD ---
class AgentCard extends StatelessWidget {
  final String agentId, name, imageUrl, phone;
  final double avgRating;

  const AgentCard({
    super.key,
    required this.agentId,
    required this.name,
    required this.imageUrl,
    required this.phone,
    required this.avgRating,
  });

  void _showAgentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => _AgentBottomSheetContent(
          agentId: agentId,
          name: name,
          imageUrl: imageUrl,
          phone: phone,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(phone, style: TextStyle(color: Colors.grey.shade600)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            Text(avgRating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        onTap: () => _showAgentBottomSheet(context),
      ),
    );
  }
}

// --- BOTTOM SHEET CONTENT (StatefulWidget for loading existing rating) ---
class _AgentBottomSheetContent extends StatefulWidget {
  final String agentId, name, imageUrl, phone;
  final ScrollController scrollController;

  const _AgentBottomSheetContent({
    required this.agentId,
    required this.name,
    required this.imageUrl,
    required this.phone,
    required this.scrollController,
  });

  @override
  State<_AgentBottomSheetContent> createState() =>
      _AgentBottomSheetContentState();
}

class _AgentBottomSheetContentState extends State<_AgentBottomSheetContent> {
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

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRating() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => isLoading = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('agent_feedback')
        .doc(widget.agentId)
        .collection('feedbacks')
        .doc(uid)
        .get();

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

    // Use uid as document ID → one rating per user per agent (prevents spam)
    await FirebaseFirestore.instance
        .collection('agent_feedback')
        .doc(widget.agentId)
        .collection('feedbacks')
        .doc(uid)
        .set({
      'feedback': feedbackController.text.trim(),
      'rating': selectedRating,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': uid,
    });

    // Recalculate average and update the agents collection
    final feedbacks = await FirebaseFirestore.instance
        .collection('agent_feedback')
        .doc(widget.agentId)
        .collection('feedbacks')
        .get();

    if (feedbacks.docs.isNotEmpty) {
      final total = feedbacks.docs
          .map((d) => (d.data()['rating'] as num).toDouble())
          .reduce((a, b) => a + b);
      final newAvg = total / feedbacks.docs.length;

      await FirebaseFirestore.instance
          .collection('agents')
          .doc(widget.agentId)
          .update({'rating': newAvg});
    }

    if (mounted) Navigator.pop(context);
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
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: widget.imageUrl.isNotEmpty
                        ? NetworkImage(widget.imageUrl)
                        : null,
                    child: widget.imageUrl.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 15),
                  Text(widget.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () =>
                        launchUrl(Uri(scheme: 'tel', path: widget.phone)),
                    icon: const Icon(Icons.call, color: Colors.green),
                    label: Text(widget.phone,
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            decoration: TextDecoration.underline)),
                  ),
                  const Divider(height: 40),
                  Text(
                    hasAlreadyRated ? "Update Your Rating" : "Rate this Agent",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  if (hasAlreadyRated)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "You've already rated this agent — you can update it.",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 35,
                        ),
                        onPressed: () =>
                            setState(() => selectedRating = index + 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: isSubmitting ? null : _submitFeedback,
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              hasAlreadyRated
                                  ? "Update Feedback"
                                  : "Submit Feedback",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                  // --- RECENT FEEDBACKS LIST ---
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Recent Feedback",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('agent_feedback')
                        .doc(widget.agentId)
                        .collection('feedbacks')
                        .orderBy('timestamp', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator.adaptive());
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return Text("No feedback yet.",
                            style: TextStyle(color: Colors.grey.shade500));
                      }
                      return Column(
                        children: snap.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final rating = (data['rating'] as num).toInt();
                          final comment = data['feedback'] as String? ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    comment.isEmpty ? "(no comment)" : comment,
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
    );
  }
}
