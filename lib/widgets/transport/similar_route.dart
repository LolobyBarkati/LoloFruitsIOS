import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SimilarRoutesList extends StatelessWidget {
  final String currentDocId;
  final String fromLocation; // Added this
  final String toLocation;   // Added this
  final Function(String) onRouteTap;

  const SimilarRoutesList({
    Key? key,
    required this.currentDocId,
    required this.fromLocation,
    required this.toLocation,
    required this.onRouteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            "Similar Routes",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
        ),
        SizedBox(
          height: 130, // Slightly increased height for better spacing
          child: StreamBuilder<QuerySnapshot>(
            // We fetch by destination as the base criteria
            stream: FirebaseFirestore.instance
                .collection('transport')
                .where('to', isEqualTo: toLocation)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              // 1. Convert docs to a list and exclude current
              List<QueryDocumentSnapshot> routes = snapshot.data!.docs
                  .where((doc) => doc.id != currentDocId)
                  .toList();

              // 2. Sort Logic: Priority to exact matches (From AND To)
              routes.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;

                bool aMatchesBoth = (dataA['from'] ?? '').toString().toLowerCase() == fromLocation.toLowerCase();
                bool bMatchesBoth = (dataB['from'] ?? '').toString().toLowerCase() == fromLocation.toLowerCase();

                if (aMatchesBoth && !bMatchesBoth) return -1; // A comes first
                if (!aMatchesBoth && bMatchesBoth) return 1;  // B comes first
                return 0; // Keep original order (timestamp)
              });

              // 3. Take the top 3
              final displayedRoutes = routes.take(3).toList();

              if (displayedRoutes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text("No other routes available.", 
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayedRoutes.length,
                itemBuilder: (context, index) {
                  final data = displayedRoutes[index].data() as Map<String, dynamic>;
                  bool isExactMatch = (data['from'] ?? '').toString().toLowerCase() == fromLocation.toLowerCase();

                  return GestureDetector(
                    onTap: () => onRouteTap(displayedRoutes[index].id),
                    child: Container(
                      width: 210,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isExactMatch ? Colors.orange.withOpacity(0.5) : Colors.grey.shade100,
                          width: isExactMatch ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  data['company'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isExactMatch)
                                const Icon(Icons.star, color: Colors.orange, size: 16),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(Icons.swap_horiz, size: 14, color: Colors.blueGrey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${data['from']} → ${data['to']}",
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Vehicle: ${data['number'] ?? 'N/A'}",
                            style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}