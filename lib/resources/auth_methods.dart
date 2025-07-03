// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:barkati_frits/providers/user_provider.dart';
import 'package:barkati_frits/utils/utils.dart';
import 'package:barkati_frits/models/user.dart' as model;
import 'package:provider/provider.dart';

class AuthMethods {
  final _userRef = FirebaseFirestore.instance.collection('users');
  final _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getCurrentUser(String? uid) async {
    if (uid != null) {
      final snap = await _userRef.doc(uid).get();
      return snap.data();
    }
    return null;
  }

  Future<bool> signUpUser(
    BuildContext context,
    String email,
    String username,
    String password, {
    required String phoneNumber,
  }) async {
    bool res = false;
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      if (cred.user != null) {
        model.User user = model.User(
          username: username.trim(),
          email: email.trim(),
          uid: cred.user!.uid,
          phoneNumber: phoneNumber.trim(),
        );
        await _userRef.doc(cred.user!.uid).set(user.toMap());
        await FirebaseFirestore.instance.collection('user').doc(user.uid).set({
          'email': email,
          'username': username,
          'phoneNumber': phoneNumber,
        });
        Provider.of<UserProvider>(context, listen: false).setUser(user);
        res = true;
      }
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!);
    }
    return res;
  }

  Future<bool> loginUser(
    BuildContext context,
    String email,
    String password,
  ) async {
    bool res = false;
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (cred.user != null) {
        final userData = await getCurrentUser(cred.user!.uid);
        if (userData != null) {
          final user = model.User.fromMap(userData);
          Provider.of<UserProvider>(context, listen: false).setUser(user);
          res = true;
        } else {
          showSnackBar(context, "User data not found. Try signing up again.");
        }
      }
    } on FirebaseAuthException catch (e) {
      // print('Login error: ${e.message}');
      showSnackBar(context, e.message!);
    }
    return res;
  }
}
