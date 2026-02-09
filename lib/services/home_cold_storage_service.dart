import 'dart:convert';
import 'package:barkati_frits/models/cold_storage_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';



class HomeColdStorageService {
  static const String _cacheKey = 'HOME_COLD_STORAGE_CACHE';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Stream for real-time updates (limit 3)
  Stream<List<ColdStorageModel>> streamTopColdStorages() {
    return _firestore
        .collection('cold storage')
        .orderBy('timestamp', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) =>
              ColdStorageModel.fromFirestore(doc.id, doc.data()))
          .toList();

      _saveCache(list); // update cache silently
      return list;
    });
  }

  /// 🔹 Load cached data instantly
  Future<List<ColdStorageModel>> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return [];

    final List decoded = jsonDecode(raw);
    return decoded
        .map((e) => ColdStorageModel.fromCache(e))
        .toList();
  }

  Future<void> _saveCache(List<ColdStorageModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final json =
        jsonEncode(list.map((e) => e.toCache()).toList());
    await prefs.setString(_cacheKey, json);
  }
}