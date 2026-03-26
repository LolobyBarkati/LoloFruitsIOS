import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SimilarRoutesList extends StatelessWidget {
  final String currentDocId;
  final String fromLocation;
  final String toLocation;
  final Function(String) onRouteTap;

  const SimilarRoutesList({
    Key? key,
    required this.currentDocId,
    required this.fromLocation,
    required this.toLocation,
    required this.onRouteTap,
  }) : super(key: key);

  // Brand Colors
  final Color primaryGreen = const Color(0xFF80C031);
  final Color accentOrange = const Color(0xFFFFA000);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Similar Routes to $toLocation",
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.grey.shade800
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140, 
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transport')
                .where('to', isEqualTo: toLocation)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              List<QueryDocumentSnapshot> routes = snapshot.data!.docs
                  .where((doc) => doc.id != currentDocId)
                  .toList();

              // Sort Logic: Exact matches first
              routes.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;

                bool aMatchesBoth = (dataA['from'] ?? '').toString().toLowerCase() == fromLocation.toLowerCase();
                bool bMatchesBoth = (dataB['from'] ?? '').toString().toLowerCase() == fromLocation.toLowerCase();

                if (aMatchesBoth && !bMatchesBoth) return -1;
                if (!aMatchesBoth && bMatchesBoth) return 1;
                return 0;
              });

              final displayedRoutes = routes.take(5).toList();

              if (displayedRoutes.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text("No other routes found for this destination.", 
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: displayedRoutes.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final data = displayedRoutes[index].data() as Map<String, dynamic>;
                  bool isExactMatch = (data['from'] ?? '').toString().toLowerCase() == fromLocation.toLowerCase();

                  return GestureDetector(
                    onTap: () => onRouteTap(displayedRoutes[index].id),
                    child: Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 12, top: 4, bottom: 8),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isExactMatch ? accentOrange.withOpacity(0.3) : Colors.grey.shade200,
                          width: isExactMatch ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: isExactMatch ? accentOrange.withOpacity(0.1) : Colors.grey.shade100,
                                child: Icon(
                                  isExactMatch ? Icons.star_rounded : Icons.local_shipping_outlined, 
                                  size: 14, 
                                  color: isExactMatch ? accentOrange : Colors.grey
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['company'] ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            "${data['from']} → ${data['to']}",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data['number'] ?? 'N/A',
                                style: TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.bold),
                              ),
                              if (isExactMatch)
                                Text(
                                  "EXACT MATCH",
                                  style: TextStyle(fontSize: 9, color: accentOrange, fontWeight: FontWeight.w900),
                                ),
                            ],
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