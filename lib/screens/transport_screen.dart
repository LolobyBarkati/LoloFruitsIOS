import 'package:barkati_frits/models/subscription/subscription_status.dart';
import 'package:barkati_frits/widgets/transport/transport_bottom.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TransportScreen extends StatefulWidget {
  static const String routeName = '/transport';
  const TransportScreen({Key? key}) : super(key: key);

  @override
  _TransportScreenState createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  final TextEditingController _fromController    = TextEditingController();
  final TextEditingController _toController      = TextEditingController();
  final TextEditingController _companyController = TextEditingController();

  final Color primaryGreen = const Color(0xFF80C031);
  final Color accentOrange = const Color(0xFFFFA000);
  final Color scaffoldBg   = const Color(0xFFF4F7F5);

  // ── Helpers ──────────────────────────────────────────────────

  List<String> _parse(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw
        .split(RegExp(r'[,;|\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  bool _matches(String raw, String query) {
    if (query.trim().isEmpty) return true;
    final q = query.toLowerCase().trim();
    return _parse(raw).any((l) => l.toLowerCase().contains(q));
  }

  // Card label logic:
  // - no search typed  →  "Multiple Cities" badge for multi-city carriers
  // - search typed     →  only show cities matching what was searched
  String _label(String raw, String query) {
    final locs = _parse(raw);
    if (locs.isEmpty) return 'N/A';
    if (locs.length == 1) return locs[0];
    if (query.trim().isEmpty) return 'Multiple Cities';
    final q       = query.toLowerCase().trim();
    final matched = locs.where((l) => l.toLowerCase().contains(q)).toList();
    if (matched.isEmpty) return 'Multiple Cities';
    if (matched.length == 1) return matched[0];
    if (matched.length == 2) return '${matched[0]}, ${matched[1]}';
    return '${matched[0]}, ${matched[1]} +${matched.length - 2} more';
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Transport Routes',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: SubscriptionWrapper(
        child: Column(
          children: [
            _buildSearch(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  // ── Search section ────────────────────────────────────────────
  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      child: Column(
        children: [
          _box(child: _field(_companyController, 'Search by company', Icons.business_rounded)),
          const SizedBox(height: 10),
          _box(
            child: Row(
              children: [
                Expanded(child: _field(_fromController, 'From city', Icons.radio_button_checked)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: primaryGreen.withOpacity(0.35), size: 18),
                ),
                Expanded(child: _field(_toController, 'To city', Icons.location_on_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _box({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: child,
      );

  Widget _field(TextEditingController ctrl, String hint, IconData icon) =>
      TextField(
        controller: ctrl,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryGreen, size: 16),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.normal),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: InputBorder.none,
        ),
      );

  // ── List ──────────────────────────────────────────────────────
  Widget _buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transport')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryGreen));
        }
        if (snap.hasError) {
          return const Center(child: Text('Something went wrong.'));
        }

        final fromQ    = _fromController.text;
        final toQ      = _toController.text;
        final companyQ = _companyController.text.toLowerCase().trim();

        final docs = (snap.data?.docs ?? []).where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return (d['company'] ?? '').toString().toLowerCase().contains(companyQ) &&
              _matches((d['from'] ?? '').toString(), fromQ) &&
              _matches((d['to']   ?? '').toString(), toQ);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text('No routes found',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.only(top: 14, bottom: 24),
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, i) {
            final data  = docs[i].data() as Map<String, dynamic>;
            final docId = docs[i].id;
            return _buildCard(context, data, docId, fromQ, toQ);
          },
        );
      },
    );
  }

  // ── Card ──────────────────────────────────────────────────────
  Widget _buildCard(BuildContext context, Map<String, dynamic> data,
      String docId, String fromQ, String toQ) {

    final String company    = data['company'] ?? 'Unknown Carrier';
    final String fromRaw    = data['from']    ?? '';
    final String toRaw      = data['to']      ?? '';
    final String contact    = data['number'] ?? data['contact'] ?? data['phone'] ??
        data['director_number'] ?? data['mobile'] ?? data['contact_number'] ?? '';
    final bool   hasContact = contact.trim().isNotEmpty;

    final bool   multiFrom = _parse(fromRaw).length > 1;
    final bool   multiTo   = _parse(toRaw).length   > 1;
    final String fromLabel = _label(fromRaw, fromQ);
    final String toLabel   = _label(toRaw, toQ);
    final bool   fromBadge = multiFrom && fromQ.trim().isEmpty;
    final bool   toBadge   = multiTo   && toQ.trim().isEmpty;

    final double progress =
        ((data['progress'] ?? 50) / 100).toDouble().clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [

              // ── Company row ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 44, 0),
                child: Row(
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.local_shipping_rounded, color: primaryGreen, size: 19),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(company,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),

          const SizedBox(height: 10),

          // ── Route chips ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(child: _routeChip('From', fromLabel, Icons.radio_button_checked, primaryGreen, fromBadge)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.grey[300], size: 16),
                ),
                Expanded(child: _routeChip('To', toLabel, Icons.location_on_rounded, accentOrange, toBadge)),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Progress bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[100],
                      color: primaryGreen,
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(progress * 100).toInt()}%',
                    style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Action buttons ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: _btn(
                    label:     hasContact ? 'Contact' : 'No Contact',
                    icon:      Icons.phone_rounded,
                    bgColor:   hasContact ? primaryGreen : Colors.grey[200]!,
                    textColor: hasContact ? Colors.white : Colors.grey[400]!,
                    onTap: hasContact
                        ? () async {
                            final uri = Uri(scheme: 'tel', path: contact);
                            if (await canLaunchUrl(uri)) launchUrl(uri);
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                // ★ KEY FIX: fromQ and toQ are passed into TransportBottomSheet
                //   so the sheet knows what the user searched for
                Expanded(
                  child: _btn(
                    label:     'Details',
                    icon:      Icons.info_outline_rounded,
                    bgColor:   accentOrange,
                    textColor: Colors.white,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                      backgroundColor: Colors.white,
                      isScrollControlled: true,
                      builder: (_) => TransportBottomSheet(
                        documentId: docId,
                        fromQuery:  fromQ,
                        toQuery:    toQ,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    Positioned(
      top: 12,
      right: 22,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: primaryGreen,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 11),
      ),
    ),
  ],
);
  }

  // ── Route chip ────────────────────────────────────────────────
  Widget _routeChip(String label, String value, IconData icon,
      Color color, bool isBadge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 9, color: Colors.grey[400],
                        fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 2),
                isBadge
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text('Multiple Cities',
                            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                      )
                    : Text(value,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Button ────────────────────────────────────────────────────
  Widget _btn({
    required String   label,
    required IconData icon,
    required Color    bgColor,
    required Color    textColor,
    VoidCallback?     onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}