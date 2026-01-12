import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsense_new/models/product.dart';
import 'package:shopsense_new/util/constants.dart';

Future<List<Product>> adminFetchProducts() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? "";

  final res = await http.get(
    Uri.parse('$baseUrl/admin/products'),
    headers: {"Authorization": "Bearer $token"},
  );

  if (res.statusCode == 200) {
    final List data = jsonDecode(res.body);
    return data.map((e) => Product.fromJson(e)).toList();
  } else {
    throw Exception("Không lấy được danh sách sản phẩm");
  }
}

Future<bool> adminAddProduct(Product p) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? "";

  final res = await http.post(
    Uri.parse('$baseUrl/admin/product'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    },
    body: jsonEncode(p.toJson()),
  );

  return res.statusCode == 200;
}

Future<bool> adminUpdateProduct(Product p) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? "";

  final res = await http.put(
    Uri.parse('$baseUrl/admin/product/${p.id}'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    },
    body: jsonEncode(p.toJson()),
  );

  return res.statusCode == 200;
}

Future<bool> adminDeleteProduct(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? "";

  final res = await http.delete(
    Uri.parse('$baseUrl/admin/product/$id'),
    headers: {"Authorization": "Bearer $token"},
  );

  return res.statusCode == 200;
}
