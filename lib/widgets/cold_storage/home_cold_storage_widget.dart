import 'package:barkati_frits/models/cold_storage_model.dart';
import 'package:barkati_frits/services/home_cold_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barkati_frits/screens/storage_screen.dart';

class HomeColdStorageWidget extends StatefulWidget {
  const HomeColdStorageWidget({super.key});

  @override
  State<HomeColdStorageWidget> createState() => _HomeColdStorageWidgetState();
}

class _HomeColdStorageWidgetState extends State<HomeColdStorageWidget> {
  final HomeColdStorageService _service = HomeColdStorageService();
  List<ColdStorageModel> cached = [];

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final data = await _service.loadCached();
    if (!mounted) return;
    setState(() => cached = data);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cold Storages',
                style: TextStyle(
                  fontSize: 19, // 🔥 increased
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.pushNamed(context, StorageScreen.routeName);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.lightGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 6.0),
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14, // 🔥 increased
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 🔹 HORIZONTAL LIST
        SizedBox(
          height: 113,
          child: StreamBuilder<List<ColdStorageModel>>(
            stream: _service.streamTopColdStorages(),
            builder: (context, snapshot) {
              final list = snapshot.data ?? cached;

              if (list.isEmpty) {
                return const Center(child: Text('No cold storage'));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16),
                itemCount: list.length,
                itemBuilder: (_, i) => _card(list[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  // 🔹 CARD
  Widget _card(ColdStorageModel s) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔹 NAME
          Text(
            s.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17, // 🔥 increased
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // 🔹 ACTION ROW
          Row(
            children: [
              _actionBox(
                Icons.call,
                'Contact',
                () => launchUrl(Uri.parse('tel:${s.phone}')),
              ),
              const SizedBox(width: 8),
              _actionBox(
                Icons.location_on,
                'Location',
                () => launchUrl(Uri.parse(s.mapLink)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 ACTION BUTTON
  Widget _actionBox(
    IconData icon,
    String text,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16, // 🔥 increased
              color: Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12, // 🔥 increased
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}