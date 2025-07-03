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
  bool? isSubscribed;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionByEmail();
  }

  // Refactored to private with underscore
  Future<void> _checkSubscriptionByEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isSubscribed = false);
      return;
    }

    final email = user.email;
    if (email == null) {
      setState(() => isSubscribed = false);
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('payments')
          .where('email', isEqualTo: email)
          .limit(1) // Assuming one active subscription per user
          .get();

      if (query.docs.isEmpty) {
        setState(() => isSubscribed = false);
        return;
      }

      final data = query.docs.first.data();
      final Timestamp? expiry = data['subscription_expiry'];
      final bool status = data['status'] ?? false;

      if (expiry == null || expiry.toDate().isBefore(DateTime.now())) {
        // Optionally update status in Firestore if expired, though checkSubscriptionByEmail will handle next time
        await query.docs.first.reference.update({'status': false});
        setState(() => isSubscribed = false);
      } else {
        setState(() => isSubscribed = status);
      }
    } catch (e) {
      // Handle potential errors during Firestore access
      debugPrint('Error checking subscription: $e');
      setState(() => isSubscribed = false); // Assume not subscribed on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Agents',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal.shade700, // A more subtle AppBar color
        elevation: 0, // No shadow for a flatter design
      ),
      body: Container(
        // Using a gradient for a subtle background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade50,
              Colors.teal.shade100,
            ],
          ),
        ),
        child: isSubscribed == null
            ? const Center(child: CircularProgressIndicator.adaptive())
            : isSubscribed == false
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildSubscriptionPrompt(context),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
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
                          child: Text(
                            'No cold storage agents found.',
                            style: TextStyle(
                                color: Colors.teal,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var agent = snapshot.data!.docs[index];
                          return AgentCard(
                            agentId: agent.id,
                            name: agent.get('name') ?? 'Unknown Agent',
                            imageUrl: agent.get('image_url') ??
                                'https://via.placeholder.com/150', // Placeholder for missing images
                            phone: agent.get('phone') ?? 'N/A',
                            avgRating: (agent.get('rating') ?? 0).toDouble(),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildSubscriptionPrompt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 60,
            color: Colors.teal.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            "Access Exclusive Data",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            " Subscription unlocks agents details, direct contact information, and more.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal, // A primary action color
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
            ),
            child: const Text(
              'View Subscription Plans',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class AgentCard extends StatelessWidget {
  final String agentId;
  final String name;
  final String imageUrl;
  final String phone;
  final double avgRating;

  const AgentCard({
    Key? key,
    required this.agentId,
    required this.name,
    required this.imageUrl,
    required this.phone,
    required this.avgRating,
  }) : super(key: key);

  void _showAgentBottomSheet(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    int selectedRating = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors
          .transparent, // Make background transparent to show custom shape
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
              ),
              child: StatefulBuilder(
                builder: (context, setState) => SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        24.0, 16.0, 24.0, 24.0), // Adjust padding for handle
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Drag handle
                        Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                          margin: const EdgeInsets.only(
                              bottom: 16), // Spacing below handle
                        ),
                        CircleAvatar(
                          radius: 60, // Slightly larger avatar
                          backgroundImage: NetworkImage(imageUrl),
                          onBackgroundImageError: (_, __) => Icon(
                            Icons.person_outline,
                            size: 60,
                            color: Colors.grey.shade400,
                          ), // Fallback icon
                          backgroundColor: Colors.teal.shade50,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 26, // Larger and more prominent name
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final Uri callUri = Uri(scheme: 'tel', path: phone);
                            if (await canLaunchUrl(callUri)) {
                              await launchUrl(callUri);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Could not launch phone call')),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone,
                                    color: Colors.green.shade600, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  phone,
                                  style: TextStyle(
                                      color: Colors.green.shade600,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.green.shade600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          "Rate $name",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < selectedRating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber.shade600,
                                size: 32, // Larger stars
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedRating = index + 1;
                                });
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: feedbackController,
                          decoration: InputDecoration(
                            labelText: 'Share your feedback (optional)',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.teal.shade400, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (selectedRating == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please select a rating!')),
                              );
                              return;
                            }

                            try {
                              // Save feedback under agent_feedback/{agentName}/feedbacks
                              await FirebaseFirestore.instance
                                  .collection('agent_feedback')
                                  .doc(name) // Use agent name as document ID
                                  .collection('feedbacks')
                                  .add({
                                'feedback': feedbackController.text,
                                'rating': selectedRating,
                                'timestamp': FieldValue.serverTimestamp(),
                                'userId':
                                    FirebaseAuth.instance.currentUser?.uid,
                              });

                              // Recalculate and update average rating for the agent
                              final feedbacksSnapshot = await FirebaseFirestore
                                  .instance
                                  .collection('agent_feedback')
                                  .doc(name)
                                  .collection('feedbacks')
                                  .get();

                              if (feedbacksSnapshot.docs.isNotEmpty) {
                                final ratings = feedbacksSnapshot.docs
                                    .map((doc) => doc['rating'] as int)
                                    .toList();
                                final double newAvgRating =
                                    ratings.reduce((a, b) => a + b) /
                                        ratings.length;

                                await FirebaseFirestore.instance
                                    .collection('agents')
                                    .doc(agentId)
                                    .update({'rating': newAvgRating});
                              }

                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Feedback submitted successfully!')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Error submitting feedback: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                          ),
                          icon: const Icon(Icons.feedback),
                          label: const Text(
                            'Submit Feedback',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6, // Slightly more elevation for a floating effect
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAgentBottomSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32, // Slightly larger avatar in card
                backgroundImage: NetworkImage(imageUrl),
                onBackgroundImageError: (_, __) => Icon(
                  Icons.person_outline,
                  size: 32,
                  color: Colors.grey.shade400,
                ), // Fallback icon
                backgroundColor: Colors.teal.shade50,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade600, size: 24),
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
