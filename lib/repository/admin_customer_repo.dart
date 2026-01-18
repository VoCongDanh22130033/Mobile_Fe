import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsense_new/models/customer.dart';
import 'package:shopsense_new/util/constants.dart';

Future<List<Customer>> adminFetchUsers() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? "";

  final res = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/admin/customers'),
    headers: {"Authorization": "Bearer $token"},
  );

  if (res.statusCode == 200) {
    final List data = jsonDecode(res.body);
    return data.map((e) => Customer.fromJson(e)).toList();
  } else {
    throw Exception("Không thể tải danh sách người dùng");
  }
}

Future<bool> adminAddUser(Customer c) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? "";

  final res = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/admin/customer'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    },
    body: jsonEncode(c.toJson()),
  );

  return res.statusCode == 200;
}

Future<bool> adminUpdateUser(Customer c) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? "";

  final res = await http.put(
    Uri.parse('${ApiConfig.baseUrl}/admin/customer/${c.id}'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    },
    body: jsonEncode(c.toJson()),
  );

  return res.statusCode == 200;
}

Future<bool> adminDeleteUser(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? "";

  final res = await http.delete(
    Uri.parse('${ApiConfig.baseUrl}/admin/customer/$id'),
    headers: {"Authorization": "Bearer $token"},
  );

  return res.statusCode == 200;
}
