import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsense_new/models/cart_item.dart';
import 'package:shopsense_new/models/auth_response.dart';
import 'package:shopsense_new/models/customer.dart';
import 'package:shopsense_new/models/order.dart';
import 'package:shopsense_new/models/place_order.dart';
import 'package:shopsense_new/util/constants.dart';
import 'package:shopsense_new/models/wishlist.dart';

/// --- HELPER FUNCTIONS ---

// Kiểm tra JSON hợp lệ và tránh lỗi trang HTML (403/404/500) từ Ngrok/Server
bool _isJson(String? body) {
  if (body == null || body.trim().isEmpty) return false;
  final content = body.trim();
  if (content.startsWith('<!DOCTYPE') || content.startsWith('<html')) return false;
  try {
    jsonDecode(content);
    return true;
  } catch (_) {
    return false;
  }
}

// Lấy Headers chung bao gồm Token và Bypass Ngrok
Future<Map<String, String>> _getAuthHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  // Log Token để kiểm tra khi gặp lỗi 403 (Chỉ hiện trong debug)
  debugPrint("🔑 Auth Token: ${token ?? 'NULL'}");

  return {
    "Content-Type": "application/json; charset=utf-8",
    "Accept": "application/json",
    "ngrok-skip-browser-warning": "true", // Bypass trang cảnh báo của Ngrok
    if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
  };
}

// Lấy UserId từ SharedPreferences
Future<String> _getStoredUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId') ?? "";
}

/// --- CUSTOMER AUTHENTICATION ---

Future<bool> customerSignup(Customer c) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/customer/signup'),
      headers: {"Content-Type": "application/json"},
      body: customerToJson(c),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    debugPrint("❌ Signup Error: $e");
    return false;
  }
}

Future<Customer?> customerSignin(Customer c) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/customer/login'),
      headers: {"Content-Type": "application/json"},
      body: customerToJson(c),
    );

    if (response.statusCode != 200 || !_isJson(response.body)) {
      debugPrint("❌ Login Error Code: ${response.statusCode}");
      return null;
    }

    AuthResponse a = authResponseFromJson(response.body);
    if (a.status != "success") return null;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', a.token!);
    await prefs.setString('userId', a.user!['id'].toString());

    return Customer.fromJson(a.user!);
  } catch (e) {
    debugPrint("❌ Login Exception: $e");
    return null;
  }
}

Future<bool> adminSignin(Customer c) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/login'),
      headers: {"Content-Type": "application/json"},
      body: customerToJson(c),
    );

    if (response.statusCode == 200 && _isJson(response.body)) {
      AuthResponse a = authResponseFromJson(response.body);
      if (a.status == "success") {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', a.token!);
        await prefs.setString('userId', a.user!['id'].toString());
        return true;
      }
    }
    return false;
  } catch (e) {
    return false;
  }
}

/// --- CUSTOMER PROFILE ---

Future<Customer> customerProfile() async {
  String userId = await _getStoredUserId();
  if (userId.isEmpty) throw Exception("Chưa đăng nhập");

  final response = await http.get(
    Uri.parse('$baseUrl/customer/$userId'),
    headers: await _getAuthHeaders(),
  );

  if (response.statusCode == 200 && _isJson(response.body)) {
    return customerFromJson(response.body);
  } else {
    debugPrint("❌ Fetch Profile Error: ${response.statusCode}");
    throw Exception("Không thể lấy thông tin người dùng.");
  }
}

Future<bool> customerUpdateProfile(Customer user) async {
  try {
    final url = Uri.parse('$baseUrl/customer/${user.id}');
    final headers = await _getAuthHeaders();

    // Loại bỏ các trường password hoặc trường nhạy cảm nếu không thay đổi để tránh lỗi 403
    final Map<String, dynamic> updateData = user.toJson();
    updateData.remove('password');

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(updateData),
      encoding: Encoding.getByName('utf-8'),
    );

    debugPrint("🔄 Update Status Code: ${response.statusCode}");

    if (response.statusCode == 403) {
      // Nếu vẫn 403, hãy kiểm tra tab "Response" trên http://127.0.0.1:4040
      debugPrint("⛔ Server Response (403): ${response.body}");
    }

    return response.statusCode >= 200 && response.statusCode < 300;
  } catch (e) {
    debugPrint("❌ Lỗi Update: $e");
    return false;
  }
}

/// --- CART MANAGEMENT ---

Future<List<CartItem>> customerCart() async {
  String userId = await _getStoredUserId();
  if (userId.isEmpty) return [];

  final response = await http.get(
    Uri.parse('$baseUrl/customer/cart?id=$userId'),
    headers: await _getAuthHeaders(),
  );

  if (response.statusCode == 200 && _isJson(response.body)) {
    return cartItemListFromJson(response.body);
  }
  return [];
}

Future<bool> customerAddToCart(CartItem c) async {
  String userId = await _getStoredUserId();
  if (userId.isEmpty) return false;
  c.customerId = int.parse(userId);

  final response = await http.post(
    Uri.parse('$baseUrl/customer/cart'),
    headers: await _getAuthHeaders(),
    body: jsonEncode(c.toJson()),
  );

  return response.statusCode == 200 || response.statusCode == 201;
}

Future<bool> customerUpdateCart(CartItem item) async {
  final response = await http.put(
    Uri.parse('$baseUrl/customer/cart'),
    headers: await _getAuthHeaders(),
    body: jsonEncode(item.toJson()),
  );
  return response.statusCode == 200;
}

Future<bool> customerRemoveCart(int id) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/customer/cart?id=$id'),
    headers: await _getAuthHeaders(),
  );
  return response.statusCode == 200;
}

/// --- ORDER MANAGEMENT ---

Future<List<Order>> customerOrders() async {
  String userId = await _getStoredUserId();
  final response = await http.get(
    Uri.parse('$baseUrl/customer/orders?id=$userId'),
    headers: await _getAuthHeaders(),
  );

  if (response.statusCode == 200 && _isJson(response.body)) {
    return orderListFromJson(response.body);
  } else {
    return [];
  }
}

Future<String> customerPlaceOrder(PlaceOrder c) async {
  String userId = await _getStoredUserId();
  if (userId.isEmpty) return "";
  c.customerId = int.parse(userId);

  final response = await http.post(
    Uri.parse('$baseUrl/customer/order'),
    headers: await _getAuthHeaders(),
    body: jsonEncode(c.toJson()),
  );

  if (response.statusCode == 200 && _isJson(response.body)) {
    Order o = orderFromJson(response.body);
    return o.id.toString();
  }
  return "";
}

Future<PlaceOrder> customerGetOrder(String orderId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/customer/order?id=$orderId'),
    headers: await _getAuthHeaders(),
  );

  if (response.statusCode == 200 && _isJson(response.body)) {
    return placeOrderFromJson(response.body);
  } else {
    throw Exception("Không thể lấy thông tin đơn hàng.");
  }
}

/// --- WISHLIST MANAGEMENT ---

Future<bool> addToWishlist(Wishlist wishlist) async {
  String userId = await _getStoredUserId();
  if (userId.isEmpty) return false;
  wishlist.customerId = int.parse(userId);

  final response = await http.post(
    Uri.parse('$baseUrl/wishlist/add'),
    headers: await _getAuthHeaders(),
    body: jsonEncode(wishlist.toJson()),
  );

  if (response.statusCode == 200 && _isJson(response.body)) {
    final result = jsonDecode(response.body);
    return result == true || result == 1;
  }
  return false;
}

Future<bool> removeFromWishlist(Wishlist wishlist) async {
  String userId = await _getStoredUserId();
  if (userId.isEmpty) return false;
  wishlist.customerId = int.parse(userId);

  final response = await http.post(
    Uri.parse('$baseUrl/wishlist/remove'),
    headers: await _getAuthHeaders(),
    body: jsonEncode(wishlist.toJson()),
  );

  if (response.statusCode == 200 && _isJson(response.body)) {
    final result = jsonDecode(response.body);
    return result == true || result == 1;
  }
  return false;
}

Future<List<Wishlist>> fetchWishlist(int customerId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/wishlist?customerId=$customerId'),
    headers: await _getAuthHeaders(),
  );

  if (response.statusCode == 200 && _isJson(response.body)) {
    final List data = jsonDecode(response.body);
    return data.map((e) => Wishlist.fromJson(e)).toList();
  } else {
    return [];
  }
}