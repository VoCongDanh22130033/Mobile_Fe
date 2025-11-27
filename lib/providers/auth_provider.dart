import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String _userId = "";
  String _token = "";

  AuthProvider() {
    updateUserId();
  }


  String get userId => _userId;
  String get token => _token;

  void updateUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? "";
    _token = prefs.getString('token') ?? "";
    notifyListeners();
  }

  void logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');
    _userId = "";
    notifyListeners();
  }
}
