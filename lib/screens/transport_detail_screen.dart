// lib/screens/transport/transport_detail_screen.dart
//
// If you navigate to this screen directly (not via bottom sheet),
// pass fromQuery and toQuery from whatever screen opened this.
// If not passed, both default to empty string which means
// "Multiple Cities" badge is shown — no list dump ever.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TransportDetailScreen extends StatelessWidget {
  static const String routeName = '/transportdetails';

  final Map<String, dynamic> entry;

  // ★ Search context — passed from the list screen.
  //   If empty (default), shows "Multiple Cities" badge instead of list.
  final String fromQuery;
  final String toQuery;

  const TransportDetailScreen({
    super.key,
    required this.entry,
    this.fromQuery = '',
    this.toQuery   = '',
  });

  final Color primaryGreen = const Color(0xFF80C031);
  final Color accentOrange = const Color(0xFFFFA000);
  final Color scaffoldBg   = const Color(0xFFF4F7F5);

  // ── Parse raw comma/semicolon/pipe/newline string into list ──
  List<String> _parse(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split(RegExp(r'[,;|\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // ── Return only cities matching the search query ──────────────
  // Empty query → empty list (caller shows "Multiple Cities" badge)
  List<String> _filtered(String raw, String query) {
    final all = _parse(raw);
    if (all.isEmpty) return [];
    if (all.length == 1) return all;
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    return all.where((l) => l.toLowerCase().contains(q)).toList();
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final String contact    = entry['number'] ?? entry['contact'] ?? entry['phone'] ??
        entry['director_number'] ?? entry['mobile'] ?? entry['contact_number'] ?? '';
    final bool   hasContact = contact.trim().isNotEmpty;
    final List<dynamic> modes = entry['transport_modes'] ?? entry['modes'] ?? [];
    final String fromRaw    = entry['from'] ?? '';
    final String toRaw      = entry['to']   ?? '';

    final List<String> fromCities = _filtered(fromRaw, fromQuery);
    final List<String> toCities   = _filtered(toRaw,   toQuery);

    final bool fromIsMultiNoSearch =
        _parse(fromRaw).length > 1 && fromQuery.trim().isEmpty;
    final bool toIsMultiNoSearch =
        _parse(toRaw).length   > 1 && toQuery.trim().isEmpty;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Carrier Details',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ── Company header ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.09),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.local_shipping_rounded,
                        color: primaryGreen, size: 34),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    (entry['company'] ?? 'Unknown Carrier').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: primaryGreen, size: 13),
                        const SizedBox(width: 4),
                        Text('Verified',
                            style: TextStyle(
                                color: primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Pickup locations card ─────────────────────────
            _locationCard(
              label:          'PICKUP LOCATIONS',
              icon:           Icons.radio_button_checked,
              iconColor:      primaryGreen,
              raw:            fromRaw,
              filteredCities: fromCities,
              isMultiNoSearch: fromIsMultiNoSearch,
            ),

            const SizedBox(height: 12),

            // ── Drop locations card ───────────────────────────
            _locationCard(
              label:          'DROP LOCATIONS',
              icon:           Icons.location_on_rounded,
              iconColor:      accentOrange,
              raw:            toRaw,
              filteredCities: toCities,
              isMultiNoSearch: toIsMultiNoSearch,
            ),

            if (modes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ],
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

            // ── Call button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: hasContact ? () => _call(contact) : null,
                icon: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                label: Text(
                  hasContact ? 'Call Office  •  $contact' : 'No Contact Available',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasContact ? primaryGreen : Colors.grey[300],
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Tip ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accentOrange.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: accentOrange, size: 16),
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

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Location card ─────────────────────────────────────────────
  Widget _locationCard({
    required String       label,
    required IconData     icon,
    required Color        iconColor,
    required String       raw,
    required List<String> filteredCities,
    required bool         isMultiNoSearch,
  }) {
    final allCities  = _parse(raw);
    final totalCount = allCities.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header row ────────────────────────────────────────
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
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
            Text('N/A',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500))

          else if (allCities.length == 1)
            // Single city — plain text
            Text(allCities[0],
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87))

          else if (isMultiNoSearch)
            // Multiple cities, no search → badge only, NO list dump
            _multipleCitiesBadge(iconColor, totalCount)

          else if (filteredCities.isEmpty)
            // Searched but nothing matched → badge fallback
            _multipleCitiesBadge(iconColor, totalCount)

          else
            // Searched → show ONLY the matching cities as chips
            Wrap(
              spacing:    6,
              runSpacing: 6,
              children: filteredCities.map((c) => _chip(c, iconColor)).toList(),
            ),
        ],
      ),
    );
  }

  // ── Multiple Cities badge — no list dump ──────────────────────
  Widget _multipleCitiesBadge(Color color, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_city_rounded, color: color, size: 14),
              const SizedBox(width: 7),
              Text('Serves $count Cities',
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Go back and search a specific city to see if it is covered.',
          style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
              fontStyle: FontStyle.italic,
              height: 1.4),
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