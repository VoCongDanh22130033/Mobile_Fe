import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shopsense_new/models/cart_item.dart';
import 'package:shopsense_new/models/customer.dart';
import 'package:shopsense_new/models/order.dart';
import 'package:shopsense_new/models/place_order.dart';
import 'package:shopsense_new/models/wishlist.dart';
import 'package:shopsense_new/util/constants.dart';

/// AUTH

Future<String?> login(String email, String password) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/customer/login');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  //DEBUG
  print('LOGIN URL: $url');
  print('LOGIN STATUS: ${response.statusCode}');
  print('LOGIN BODY: ${response.body}');

  if (response.statusCode != 200) return null;

  final json = jsonDecode(response.body);
  return json['token']; // backend có
}

/// SIGNUP

Future<bool> customerSignup(Customer c) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/customer/signup');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': c.name,
      'email': c.email,
      'password': c.password,
      'address': c.address,
    }),
  );

  //DEBUG
  print('SIGNUP URL: $url');
  print('SIGNUP STATUS: ${response.statusCode}');
  print('SIGNUP BODY: ${response.body}');

  // backend có thể trả 200 hoặc 201
  return response.statusCode == 200 || response.statusCode == 201;
}
Future<String?> loginWithFirebaseIdToken(String idToken) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/customer/login/firebase');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'idToken': idToken,
    }),
  );

  print('FIREBASE LOGIN URL: $url');
  print('FIREBASE LOGIN STATUS: ${response.statusCode}');
  print('FIREBASE LOGIN BODY: ${response.body}');

  if (response.statusCode != 200) return null;

  final json = jsonDecode(response.body);
  return json['token'];
}

/// HELPER: AUTH HEADER

Future<Map<String, String>> _authHeader() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? "";
  return {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };
}

/// PROFILE

Future<Customer> customerProfile() async {
  final headers = await _authHeader();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/customer/profile'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return customerFromJson(response.body);
  } else {
    throw Exception("Không thể lấy thông tin hồ sơ");
  }
}

/// UPDATE PROFILE
Future<bool> customerUpdateProfile(Customer user) async {
  final headers = await _authHeader();

  final response = await http.put(
    Uri.parse('${ApiConfig.baseUrl}/customer/profile'),
    headers: headers,
    body: jsonEncode({
      "name": user.name,
      "email": user.email,
      "address": user.address,
    }),
  );

  return response.statusCode == 200;
}

/// ORDERS

Future<List<Order>> customerOrders() async {
  final headers = await _authHeader();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/customer/orders'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return orderListFromJson(response.body);
  } else {
    throw Exception("Không nhận được đơn hàng");
  }
}

/// CART

Future<List<CartItem>> customerCart() async {
  final headers = await _authHeader();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/customer/cart'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return cartItemListFromJson(response.body);
  } else {
    throw Exception("Không lấy được giỏ hàng");
  }
  return [];
}

Future<bool> customerAddToCart(CartItem c) async {
  final headers = await _authHeader();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/customer/cart'),
    headers: headers,
    body: jsonEncode(c.toJson()),
  );

  return response.statusCode == 200;
}

Future<bool> customerUpdateCart(CartItem item) async {
  final headers = await _authHeader();

Future<bool> customerUpdateCart(CartItem item) async {
  final response = await http.put(
    Uri.parse('${ApiConfig.baseUrl}/customer/cart'),
    headers: headers,
    body: jsonEncode(item.toJson()),
  );

  return response.statusCode == 200;
}

Future<bool> customerRemoveCart(int id) async {
  final headers = await _authHeader();

  final response = await http.delete(
    Uri.parse('${ApiConfig.baseUrl}/customer/cart?id=$id'),
    headers: headers,
  );

  return response.statusCode == 200;
}

/// ORDER

Future<String> customerPlaceOrder(PlaceOrder c) async {
  final headers = await _authHeader();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/customer/order'),
    headers: headers,
    body: jsonEncode(c.toJson()),
  );

  if (response.statusCode == 200 && response.body.isNotEmpty) {
    final o = orderFromJson(response.body);
    return o.id.toString();
  }

  return "";
}

Future<PlaceOrder> customerGetOrder(String orderId) async {
  final headers = await _authHeader();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/customer/order?id=$orderId'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return placeOrderFromJson(response.body);
  } else {
    throw Exception("Không lấy được đơn hàng");
  }
}

/// WISHLIST

Future<bool> addToWishlist(Wishlist wishlist) async {
  final headers = await _authHeader();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/wishlist/add'),
    headers: headers,
    body: jsonEncode(wishlist.toJson()),
  );

  return response.statusCode == 200;
}

Future<bool> removeFromWishlist(Wishlist wishlist) async {
  final headers = await _authHeader();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/wishlist/remove'),
    headers: headers,
    body: jsonEncode(wishlist.toJson()),
  );

  return response.statusCode == 200;
}

Future<List<Wishlist>> fetchWishlist() async {
  final headers = await _authHeader();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/wishlist'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((e) => Wishlist.fromJson(e)).toList();
  } else {
    throw Exception('Không lấy được wishlist');
  }
}
