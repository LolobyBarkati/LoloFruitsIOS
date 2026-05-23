import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BannerService {
  static const String _bannerCacheKey = 'HOME_BANNERS_CACHE';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> loadCachedBanners() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_bannerCacheKey);

    if (cachedData != null) {
      return List<String>.from(jsonDecode(cachedData));
    }

    return await _fetchAndCacheFromFirestore();
  }

  Future<List<String>> _fetchAndCacheFromFirestore() async {
    final prefs = await SharedPreferences.getInstance();

    final snapshot = await _firestore
        .collection('home_banners')
        .orderBy('timestamp', descending: false)
        .get();

    final List<String> urls = snapshot.docs
        .map((doc) => doc.data()['url'] as String)
        .toList();

    await prefs.setString(_bannerCacheKey, jsonEncode(urls));
    return urls;
  }

  Stream<List<String>> listenForBannerUpdates() {
    return _firestore
        .collection('home_banners')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<String> urls = snapshot.docs
          .map((doc) => doc.data()['url'] as String)
          .toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_bannerCacheKey, jsonEncode(urls));

      return urls;
    });
  }
}