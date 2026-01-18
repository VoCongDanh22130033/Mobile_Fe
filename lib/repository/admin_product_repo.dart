import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsense_new/models/product.dart';
import 'package:shopsense_new/util/constants.dart';

Future<List<Product>> adminFetchProducts() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? "";

  final res = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/admin/products'),
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
    Uri.parse('${ApiConfig.baseUrl}/admin/product'),
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
    Uri.parse('${ApiConfig.baseUrl}/admin/product/${p.id}'),
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
    Uri.parse('${ApiConfig.baseUrl}/admin/product/$id'),
    headers: {"Authorization": "Bearer $token"},
  );

  return res.statusCode == 200;
}

Future<String?> uploadImage(File imageFile) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['ngrok-skip-browser-warning'] = 'true';
    
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['fileUrl'] != null) {
        // Trả về đường dẫn file (không bao gồm baseUrl, backend sẽ xử lý)
        return data['fileUrl'];
      }
    }
    return null;
  } catch (e) {
    return null;
  }
}

/// Upload image from bytes (for web)
Future<String?> uploadImageBytes(Uint8List bytes, String fileName) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['ngrok-skip-browser-warning'] = 'true';
    
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['fileUrl'] != null) {
        // Trả về đường dẫn file (không bao gồm baseUrl, backend sẽ xử lý)
        return data['fileUrl'];
      }
    }
    return null;
  } catch (e) {
    return null;
  }
}
