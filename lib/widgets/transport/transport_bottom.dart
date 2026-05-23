// lib/widgets/transport/transport_bottom.dart
//
// HOW THIS FILE WORKS NOW:
// - Receives documentId (to fetch full data from Firestore)
// - Receives fromQuery and toQuery (what the user searched)
//
// LOCATION DISPLAY LOGIC:
// - No search made → shows "Multiple Cities" badge, no list dump
// - Search made    → shows ONLY the cities that match what was searched
//                    (e.g. user searched "mumbai" → only Mumbai shown)
// - Single city    → shown as plain text, no chips needed

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TransportBottomSheet extends StatelessWidget {
  final String documentId;

  // ★ These two are the search queries the user typed on the list screen.
  //   They are passed from TransportScreen → here so we know what to show.
  final String fromQuery;
  final String toQuery;

  const TransportBottomSheet({
    Key? key,
    required this.documentId,
    this.fromQuery = '',  // defaults to empty = no search = show "Multiple Cities"
    this.toQuery   = '',
  }) : super(key: key);

  final Color primaryGreen = const Color(0xFF80C031);
  final Color accentOrange = const Color(0xFFFFA000);

  // ── Parse comma/semicolon/pipe/newline list into clean list ──
  List<String> _parse(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split(RegExp(r'[,;|\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // ── Filter cities based on the search query ───────────────────
  // If query is empty   → return empty list (caller shows "Multiple Cities")
  // If query has text   → return only cities that contain the search text
  // If single city      → return as-is (no filtering needed)
  List<String> _filtered(String raw, String query) {
    final all = _parse(raw);
    if (all.isEmpty) return [];
    if (all.length == 1) return all; // single city, no filtering needed
    if (query.trim().isEmpty) return []; // no search → caller shows badge
    final q = query.toLowerCase().trim();
    return all.where((l) => l.toLowerCase().contains(q)).toList();
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('transport')
          .doc(documentId)
          .get(),
      builder: (context, snap) {
        // ── Loading ───────────────────────────────────────────
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // ── Error / not found ─────────────────────────────────
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Details not found.')),
          );
        }

        final data    = snap.data!.data() as Map<String, dynamic>;
        final contact = data['number'] ?? data['contact'] ?? data['phone'] ??
            data['director_number'] ?? data['mobile'] ?? data['contact_number'] ?? '';
        final bool hasContact = contact.toString().trim().isNotEmpty;
        final List<dynamic> modes = data['transport_modes'] ?? data['modes'] ?? [];

        final String fromRaw = data['from'] ?? '';
        final String toRaw   = data['to']   ?? '';

        // Cities to display — filtered by what was searched
        final List<String> fromCities = _filtered(fromRaw, fromQuery);
        final List<String> toCities   = _filtered(toRaw,   toQuery);

        // Whether we have actual cities to show or just show "Multiple Cities"
        final bool fromIsMultiNoSearch =
            _parse(fromRaw).length > 1 && fromQuery.trim().isEmpty;
        final bool toIsMultiNoSearch =
            _parse(toRaw).length   > 1 && toQuery.trim().isEmpty;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize:     0.4,
          maxChildSize:     0.92,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Drag handle ───────────────────────────────
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // ── Company header ────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.local_shipping_rounded,
                          color: primaryGreen, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (data['company'] ?? 'Unknown Carrier').toUpperCase(),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((data['status'] ?? '').toString().isNotEmpty)
                            Text(data['status'],
                                style: TextStyle(
                                    color: primaryGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Pickup locations ──────────────────────────
                _locationSection(
                  label:          'PICKUP LOCATIONS',
                  icon:           Icons.radio_button_checked,
                  iconColor:      primaryGreen,
                  raw:            fromRaw,
                  filteredCities: fromCities,
                  isMultiNoSearch: fromIsMultiNoSearch,
                  searchQuery:    fromQuery,
                ),

                const SizedBox(height: 12),

                // ── Drop locations ────────────────────────────
                _locationSection(
                  label:          'DROP LOCATIONS',
                  icon:           Icons.location_on_rounded,
                  iconColor:      accentOrange,
                  raw:            toRaw,
                  filteredCities: toCities,
                  isMultiNoSearch: toIsMultiNoSearch,
                  searchQuery:    toQuery,
                ),

                if (modes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.directions_rounded, color: primaryGreen, size: 14),
                            const SizedBox(width: 6),
                            Text('TRANSPORT MODES',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey[500],
                                    letterSpacing: 1.1)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: modes.map<Widget>((m) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: primaryGreen.withOpacity(0.18)),
                            ),
                            child: Text(m.toString(),
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800])),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Call button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: hasContact ? () => _call(contact.toString()) : null,
                    icon: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                    label: Text(
                      hasContact
                          ? 'Call Office  •  $contact'
                          : 'No Contact Available',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasContact ? primaryGreen : Colors.grey[300],
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Tip ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accentOrange.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: accentOrange, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Contact the office to confirm availability for your specific route.',
                          style: TextStyle(
                              color: accentOrange.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Location section widget ───────────────────────────────────
  //
  // CASES handled:
  // 1. No cities in Firestore → shows "N/A"
  // 2. Single city → shows plain bold text
  // 3. Multiple cities, no search done → shows "Multiple Cities" badge
  //    with total count. No list dump.
  // 4. Multiple cities, search done → shows ONLY the matching city chips.
  //    If nothing matched (shouldn't happen because card already filters)
  //    falls back to "Multiple Cities" badge.
  Widget _locationSection({
    required String       label,
    required IconData     icon,
    required Color        iconColor,
    required String       raw,
    required List<String> filteredCities,
    required bool         isMultiNoSearch,
    required String       searchQuery,
  }) {
    final allCities  = _parse(raw);
    final totalCount = allCities.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header row: label + count badge ──────────────────
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[500],
                      letterSpacing: 1.1)),
              const SizedBox(width: 6),
              if (totalCount > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$totalCount cities',
                      style: TextStyle(
                          fontSize: 9,
                          color: iconColor,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Content ───────────────────────────────────────────
          if (allCities.isEmpty)
            // No data at all
            Text('N/A',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500))

          else if (allCities.length == 1)
            // Single city — show plainly
            Text(allCities[0],
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87))

          else if (isMultiNoSearch)
            // Multiple cities but user did NOT search — show badge only
            // This is the key fix: no list dump
            _multipleCitiesBadge(iconColor, totalCount)

          else if (filteredCities.isEmpty)
            // Searched but no matches (fallback — normally shouldn't reach here
            // because the list screen already filters cards)
            _multipleCitiesBadge(iconColor, totalCount)

          else
            // Searched and we have matched cities — show chips for matches only
            Wrap(
              spacing:    6,
              runSpacing: 6,
              children: filteredCities
                  .map((city) => _chip(city, iconColor))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ── "Multiple Cities" badge ───────────────────────────────────
  // Shown when user hasn't searched — clean, no list dump
  Widget _multipleCitiesBadge(Color color, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_city_rounded, color: color, size: 14),
              const SizedBox(width: 6),
              Text('Serves $count Cities',
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'Search a city above to see if it is covered',
            style: TextStyle(
                color: Colors.grey[400], fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  // ── City chip ─────────────────────────────────────────────────
  Widget _chip(String city, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(city,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800])),
    );
  }
}