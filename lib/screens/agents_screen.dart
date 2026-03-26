import 'package:barkati_frits/models/subscription/subscription_status.dart';
import 'package:barkati_frits/widgets/agents/agent_bottom_sheet.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AgentsScreen extends StatefulWidget {
  static const String routeName = '/agents';
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  final Color primaryGreen = const Color(0xFF80C031);
  final Color scaffoldBg = const Color(0xFFF8FAF8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
        title: Text('Verified Experts',
            style: TextStyle(
                color: Colors.grey.shade900, 
                fontWeight: FontWeight.w900, 
                fontSize: 20, 
                letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SubscriptionWrapper(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('agents')
              .orderBy('rating', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: primaryGreen));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No experts found.'));
            }

            final allAgents = snapshot.data!.docs;
            final topAgents = allAgents.take(3).toList();
            final otherAgents = allAgents.skip(3).toList();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // --- FEATURED SECTION (Background Container Removed) ---
                SliverPadding(
                  padding: const EdgeInsets.only(top: 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text("FEATURED EXPERTS",
                                style: TextStyle(
                                    color: primaryGreen, 
                                    fontWeight: FontWeight.w900, 
                                    fontSize: 10,
                                    letterSpacing: 1.2)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 170, 
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            scrollDirection: Axis.horizontal,
                            itemCount: topAgents.length,
                            itemBuilder: (context, index) {
                              var agent = topAgents[index];
                              return TopRatedAgentCard(
                                agentId: agent.id,
                                name: agent.get('name') ?? 'Unknown',
                                imageUrl: agent.get('image_url') ?? '',
                                avgRating: (agent.get('rating') ?? 0).toDouble(),
                                phone: agent.get('phone') ?? '',
                                primaryColor: primaryGreen,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- LIST HEADER ---
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  sliver: SliverToBoxAdapter(
                    child: Text("Available Professionals",
                        style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w900, 
                            color: Colors.grey.shade900)),
                  ),
                ),

                // --- AGENTS LIST ---
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        var agent = otherAgents[index];
                        return AgentCard(
                          agentId: agent.id,
                          name: agent.get('name') ?? 'Unknown',
                          imageUrl: agent.get('image_url') ?? '',
                          phone: agent.get('phone') ?? 'N/A',
                          avgRating: (agent.get('rating') ?? 0).toDouble(),
                          primaryColor: primaryGreen,
                        );
                      },
                      childCount: otherAgents.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class TopRatedAgentCard extends StatelessWidget {
  final String agentId, name, imageUrl, phone;
  final double avgRating;
  final Color primaryColor;

  const TopRatedAgentCard({
    super.key,
    required this.agentId,
    required this.name,
    required this.imageUrl,
    required this.phone,
    required this.avgRating,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AgentBottomSheet.show(context, agentId, name, imageUrl, phone, avgRating),
      child: Container(
        width: 135,
        margin: const EdgeInsets.only(right: 14, bottom: 10), // Added bottom margin for shadow
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.verified_rounded, color: primaryColor, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(name, 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey.shade900),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                Text(" $avgRating", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.amber)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class AgentCard extends StatelessWidget {
  final String agentId, name, imageUrl, phone;
  final double avgRating;
  final Color primaryColor;

  const AgentCard({
    super.key,
    required this.agentId,
    required this.name,
    required this.imageUrl,
    required this.phone,
    required this.avgRating,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => AgentBottomSheet.show(context, agentId, name, imageUrl, phone, avgRating),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.grey.shade900)),
                    const SizedBox(height: 4),
                    Text("Verified Professional", 
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(avgRating.toStringAsFixed(1), 
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.grey.shade900)),
                      const SizedBox(width: 2),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    ],
                  ),
                  Text("RATING", 
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}