import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> saveTokenToDatabase(String userId) async {
  // Request notification permissions
  await FirebaseMessaging.instance.requestPermission();

  String? token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance
        .collection('customer_tokens')
        .doc(userId)
        .set({'token': token});
  }
}
