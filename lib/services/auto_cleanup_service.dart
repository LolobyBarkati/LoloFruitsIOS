import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoCleanupService {
  static const _lastRunKey = 'AUTO_CLEANUP_LAST_RUN';
  static const _ttlDays = 21;

  static final _db = FirebaseFirestore.instance;

  /// Call once per app session. Internally rate-limits to once per day.
  static Future<void> runIfDue() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRun = prefs.getString(_lastRunKey);

    if (lastRun != null) {
      final last = DateTime.tryParse(lastRun);
      if (last != null && DateTime.now().difference(last).inHours < 24) return;
    }

    await _deleteOldFruitPosts();
    await _deleteOldOffers();

    await prefs.setString(_lastRunKey, DateTime.now().toIso8601String());
  }

  static Future<void> _deleteOldFruitPosts() async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: _ttlDays)),
    );

    // Get all fruit categories
    final fruits = await _db.collection('fruits').get();

    for (final fruit in fruits.docs) {
      final name = fruit.id;
      bool hasMore = true;

      while (hasMore) {
        final old = await _db
            .collection('fruits')
            .doc(name)
            .collection(name)
            .where('timestamp', isLessThan: cutoff)
            .limit(400)
            .get();

        if (old.docs.isEmpty) {
          hasMore = false;
          break;
        }

        final batch = _db.batch();
        for (final doc in old.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        hasMore = old.docs.length == 400;
      }
    }
  }

  static Future<void> _deleteOldOffers() async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: _ttlDays)),
    );

    bool hasMore = true;

    while (hasMore) {
      final old = await _db
          .collection('offerdata')
          .doc('main')
          .collection('fruit')
          .where('timestamp', isLessThan: cutoff)
          .limit(400)
          .get();

      if (old.docs.isEmpty) {
        hasMore = false;
        break;
      }

      final batch = _db.batch();
      for (final doc in old.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      hasMore = old.docs.length == 400;
    }
  }
}
