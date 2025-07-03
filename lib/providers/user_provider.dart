import 'package:flutter/material.dart';
import 'package:barkati_frits/models/user.dart';

class UserProvider extends ChangeNotifier {
  User _user = User(uid: '', username: '', email: '', phoneNumber: '',);

  User get user => _user;

  setUser(User user) {
    _user = user;
    notifyListeners();
  }
}
