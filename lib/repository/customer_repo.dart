import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsense_new/models/cart_item.dart';
import 'package:shopsense_new/models/auth_response.dart';
import 'package:shopsense_new/models/customer.dart';
import 'package:shopsense_new/models/order.dart';
import 'package:shopsense_new/models/place_order.dart';
import 'package:shopsense_new/util/constants.dart';
import 'package:shopsense_new/models/wishlist.dart';

// Signup
Future<bool> customerSignup(Customer c) async {
  final response = await http.post(Uri.parse('$baseUrl/customer/signup'),
      headers: {"Content-Type": "application/json"}, body: customerToJson(c));
  return response.statusCode == 200;
}


Future<int> _getCustomerId() async {
  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');
  if (userId != null && userId.isNotEmpty) {
    return int.parse(userId);
  } else {
    throw Exception("Người dùng chưa đăng nhập");
  }
}

// Login
Future<Customer?> customerSignin(Customer c) async {
  final response = await http.post(
    Uri.parse('$baseUrl/customer/login'),
    headers: {"Content-Type": "application/json"},
    body: customerToJson(c),
  );

  if (response.statusCode != 200) return null;

  AuthResponse a = authResponseFromJson(response.body);

  if (a.status != "success") return null;

  // ✅ Lưu token + userId
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', a.token!);
  await prefs.setString('userId', a.user!['id'].toString());

  // ✅ TRẢ VỀ Customer
  return Customer.fromJson(a.user!);
}

// Profile
Future<Customer> customerProfile() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId') ?? "";
  String token = prefs.getString('token') ?? "";
  final response = await http.get(Uri.parse('$baseUrl/customer/$userId'),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"});
  if (response.statusCode == 200) {
    return customerFromJson(response.body);
  } else {
    throw Exception("Không thể lấy được thông tin khách hàng.");
  }
}
// List order
Future<List<Order>> customerOrders() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId') ?? "";
  String token = prefs.getString('token') ?? "";
  final response = await http.get(Uri.parse('$baseUrl/customer/orders?id=$userId'),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"});
  if (response.statusCode == 200) {
    return orderListFromJson(response.body);
  } else {
    throw Exception("Không nhận được đơn đặt hàng ");
  }
}
// List card
Future<List<CartItem>> customerCart() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId') ?? "";
  String token = prefs.getString('token') ?? "";
  final response = await http.get(Uri.parse('$baseUrl/customer/cart?id=$userId'),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"});
  if (response.statusCode == 200) {
    return cartItemListFromJson(response.body);
  } else {
    throw Exception("Failed to get customer cart items");
  }
}
// add to cart
Future<bool> customerAddToCart(CartItem c) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId') ?? "";
  String token = prefs.getString('token') ?? "";
  c.customerId = int.parse(userId);
  final response = await http.post(Uri.parse('$baseUrl/customer/cart'),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode(c.toJson()));
  if (response.statusCode == 200) {
    return response.body != "";
  } else {
    throw Exception("Failed to get customer cart items");
  }
}
// Place Order
Future<String> customerPlaceOrder(PlaceOrder c) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId') ?? "";
  String token = prefs.getString('token') ?? "";
  c.customerId = int.parse(userId);
  final response = await http.post(Uri.parse('$baseUrl/customer/order'),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: jsonEncode(c.toJson()));
  if (response.statusCode == 200 && response.body != "") {
    Order o = orderFromJson(response.body);
    return o.id.toString();
  } else {
    return "";
  }
}
// Get Order
Future<PlaceOrder> customerGetOrder(String orderId) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String token = prefs.getString('token') ?? "";
  final response = await http.get(Uri.parse('$baseUrl/customer/order?id=$orderId'),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"});
  if (response.statusCode == 200 && response.body != "") {
    return placeOrderFromJson(response.body);
  } else {
    throw Exception("Không thể lấy được thông tin khách hàng.");
  }
}
// Update to card
Future<bool> customerUpdateCart(CartItem item) async {
  final url = Uri.parse('$baseUrl/customer/cart');

  final response = await http.put(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(item.toJson()),
  );

  if (response.statusCode == 200) {
    print('Cập nhật giỏ hàng thành công');
    return true;
  } else {
    print(' Cập nhật giỏ hàng không thành công: ${response.body}');
    return false;
  }
}


// remove card
Future<bool> customerRemoveCart(int id) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String token = prefs.getString('token') ?? "";

  final response = await http.delete(
    Uri.parse('$baseUrl/customer/cart?id=$id'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    },
  );
  if (response.statusCode == 200) {
    return true;
  } else {
    print("❌ Remove cart failed: ${response.body}");
    return false;
  }
}
// Update profile
Future<bool> customerUpdateProfile(Customer user) async {
  try {
    final response = await http.put(
      Uri.parse("http://localhost:8080/api/customers/${user.id}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJson()),
    );
    return response.statusCode == 200;
  } catch (e) {
    print("Update profile error: $e");
    return false;
  }
}
// Admin signin
Future<bool> adminSignin(Customer c) async {
  final response = await http.post(
    Uri.parse('$baseUrl/admin/login'),
    headers: {"Content-Type": "application/json"},
    body: customerToJson(c), // dùng cùng hàm serialize Customer
  );
  if (response.statusCode == 200) {
    AuthResponse a = authResponseFromJson(response.body);
    if (a.status == "success") {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', a.token!);
      await prefs.setString('userId', a.user!['id'].toString());
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}
Future<bool> addToWishlist(Wishlist wishlist) async {
  final url = Uri.parse('$baseUrl/wishlist/add'); // <-- thêm baseUrl
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId') ?? "";
  wishlist.customerId = int.parse(userId); // gán customerId từ login

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(wishlist.toJson()),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body); // true/false từ backend
  } else {
    throw Exception('Failed to add to wishlist');
  }
}

Future<bool> removeFromWishlist(Wishlist wishlist) async {
  final url = Uri.parse('$baseUrl/wishlist/remove'); // <-- thêm baseUrl
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId') ?? "";
  wishlist.customerId = int.parse(userId);

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(wishlist.toJson()),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to remove from wishlist');
  }
}
// Lấy danh sách wishlist
Future<List<Wishlist>> fetchWishlist(int customerId) async {
  final url = Uri.parse('$baseUrl/wishlist?customerId=$customerId');
  final response = await http.get(url, headers: {'Content-Type': 'application/json'});
  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((e) => Wishlist.fromJson(e)).toList();
  } else {
    throw Exception('Failed to fetch wishlist');
  }
}



