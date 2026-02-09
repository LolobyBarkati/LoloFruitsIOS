import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BannerService {
  static const String _bannerCacheKey = 'HOME_BANNERS_CACHE';
  static const String _bannerUpdatedAtKey = 'HOME_BANNERS_UPDATED_AT';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Load banners (CACHE FIRST)
  Future<List<String>> loadCachedBanners() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_bannerCacheKey);

    if (cachedData != null) {
      return List<String>.from(jsonDecode(cachedData));
    }

    return await _fetchAndCacheFromFirestore();
  }

  /// 🔹 Fetch from Firestore & cache
  Future<List<String>> _fetchAndCacheFromFirestore() async {
    final prefs = await SharedPreferences.getInstance();

    final doc =
        await _firestore.collection('banner').doc('home_banners').get();

    if (!doc.exists) return [];

    final List banners = doc.data()?['banners'] ?? [];
    final List<String> urls =
        banners.map<String>((b) => b['url'] as String).toList();

    await prefs.setString(_bannerCacheKey, jsonEncode(urls));

    final updatedAt = doc.data()?['updatedAt'];
    if (updatedAt != null) {
      await prefs.setString(
        _bannerUpdatedAtKey,
        updatedAt.toDate().toIso8601String(),
      );
    }

    return urls;
  }

  /// 🔥 Listen for admin updates (ONLY updates cache when changed)
  Stream<List<String>> listenForBannerUpdates() {
    return _firestore
        .collection('banner')
        .doc('home_banners')
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return [];

      final prefs = await SharedPreferences.getInstance();
      final serverUpdatedAt = doc.data()?['updatedAt'];
      final cachedUpdatedAt = prefs.getString(_bannerUpdatedAtKey);

      final serverTime =
          serverUpdatedAt?.toDate().toIso8601String();

      /// ❌ No change → return cached
      if (serverTime != null && serverTime == cachedUpdatedAt) {
        final cached = prefs.getString(_bannerCacheKey);
        if (cached != null) {
          return List<String>.from(jsonDecode(cached));
        }
      }

      /// ✅ Changed → refresh cache
      final List banners = doc.data()?['banners'] ?? [];
      final List<String> urls =
          banners.map<String>((b) => b['url'] as String).toList();

      await prefs.setString(_bannerCacheKey, jsonEncode(urls));
      await prefs.setString(_bannerUpdatedAtKey, serverTime ?? '');

      return urls;
    });
  }
}