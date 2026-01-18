import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../models/customer.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;          // JWT backend
  Customer? _customer;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? get token => _token;
  Customer? get customer => _customer;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  String get userId => _customer?.id.toString() ?? '';

  /// Load token khi app start
  Future<void> loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    notifyListeners();
  }

  /// Set auth sau khi backend trả JWT + customer
  Future<void> setAuth(String token, Customer customer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    _token = token;
    _customer = customer;
    notifyListeners();
  }

  ///GOOGLE LOGIN
  Future<String> loginWithGoogleFirebase() async {
    final GoogleSignInAccount? googleUser =
    await GoogleSignIn().signIn();

    if (googleUser == null) {
      throw Exception('GOOGLE_LOGIN_CANCELLED');
    }

    final GoogleSignInAuthentication googleAuth =
    await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _firebaseAuth.signInWithCredential(credential);

    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('GOOGLE_LOGIN_FAILED');

    final idToken = await user.getIdToken(true);
    if (idToken == null) throw Exception('ID_TOKEN_NULL');

    return idToken;
  }

  ///FACEBOOK LOGIN
  Future<String> loginWithFacebookFirebase() async {
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status != LoginStatus.success) {
      throw Exception('FACEBOOK_LOGIN_FAILED');
    }

    final OAuthCredential credential =
    FacebookAuthProvider.credential(
      result.accessToken!.tokenString,
    );

    await _firebaseAuth.signInWithCredential(credential);

    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('FACEBOOK_LOGIN_FAILED');

    final idToken = await user.getIdToken(true);
    if (idToken == null) throw Exception('ID_TOKEN_NULL');

    return idToken;
  }

  ///LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    _token = null;
    _customer = null;

    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
    await _firebaseAuth.signOut();

    notifyListeners();
  }
}