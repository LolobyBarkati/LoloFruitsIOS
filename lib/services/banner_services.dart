import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BannerService {
  static const String _bannerCacheKey = 'HOME_BANNERS_CACHE';
  static const String _bannerUpdatedAtKey = 'HOME_BANNERS_UPDATED_AT';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Load banners (FETCH FRESH FROM FIRESTORE)
  Future<List<String>> loadCachedBanners() async {
    // Always fetch fresh from Firestore to get latest banners
    return await _fetchAndCacheFromFirestore();
  }

  /// 🔹 Fetch from Firestore & cache
  Future<List<String>> _fetchAndCacheFromFirestore() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final snapshot = await _firestore
          .collection('home_banners')
          .get();

      print('📦 Banner docs fetched: ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) {
        print('⚠️ No banners found in collection');
        return [];
      }

      final List<String> urls = snapshot.docs
          .map<String>((doc) {
            final data = doc.data();
            print('📄 Banner doc: $data');
            return data['url'] as String? ?? '';
          })
          .where((url) => url.isNotEmpty)
          .toList();

      print('✅ Loaded ${urls.length} banner URLs');

      await prefs.setString(_bannerCacheKey, jsonEncode(urls));

      final latestDoc = snapshot.docs.first;
      final updatedAt = latestDoc.data()['updatedAt'];
      if (updatedAt != null) {
        await prefs.setString(
          _bannerUpdatedAtKey,
          updatedAt.toDate().toIso8601String(),
        );
      }

      return urls;
    } catch (e) {
      print('❌ Error loading banners: $e');
      return [];
    }
  }

  /// 🔥 Listen for admin updates (ONLY updates cache when changed)
  Stream<List<String>> listenForBannerUpdates() {
    return _firestore
        .collection('home_banners')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return [];

      final prefs = await SharedPreferences.getInstance();
      final latestDoc = snapshot.docs.first;
      final serverUpdatedAt = latestDoc.data()['updatedAt'];
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
      final List<String> urls = snapshot.docs
          .map<String>((doc) => doc.data()['url'] as String? ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      await prefs.setString(_bannerCacheKey, jsonEncode(urls));
      await prefs.setString(_bannerUpdatedAtKey, serverTime ?? '');

      return urls;
    });
  }
}