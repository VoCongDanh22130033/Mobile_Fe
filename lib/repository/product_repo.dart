
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsense_new/models/product.dart';
import 'package:shopsense_new/util/constants.dart';

List<Product> productsFromJson(String str) =>
    List<Product>.from(json.decode(str).map((x) => Product.fromJson(x)));

/// Lấy tất cả sản phẩm (không phân trang, dùng cho search)
Future<List<Product>> fetchProducts() async {
  // Sử dụng endpoint /products với categoryId=0 để lấy tất cả
  // page=1, size=1000 để lấy nhiều sản phẩm (có thể cần điều chỉnh)
  final url = Uri.parse('${ApiConfig.baseUrl}/products?page=1&size=1000&categoryId=0');
  final headers = await _getHeaders();
  final response = await http.get(url, headers: headers);

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded.map((e) => Product.fromJson(e)).toList();
    }

    throw Exception("API không trả List");
  } else {
    throw Exception("HTTP ${response.statusCode}");
  }
}



Future<Product> fetchProduct(String id) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/product/$id');
  final headers = await _getHeaders();
  final response = await http.get(url, headers: headers);

  if (response.statusCode == 200) {
    return Product.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Không thể tải sản phẩm (mã lỗi: ${response.statusCode})');
  }
}

/// Helper: Lấy auth header (có thể null nếu chưa đăng nhập)
Future<Map<String, String>> _getHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  
  final headers = <String, String>{
    'Content-Type': 'application/json',
  };
  
  // Thêm token nếu có (cho trường hợp user đã đăng nhập)
  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }
  
  return headers;
}

/// Lấy danh sách sản phẩm có phân trang và lọc theo category ID
Future<List<Product>> fetchProductsByCategoryId({
  required int categoryId,
  required int page,
  required int size,
}) async {
  try {
    // Sử dụng endpoint /products với query params: page, size, categoryId
    // categoryId = 0 nghĩa là lấy tất cả sản phẩm
    final url = Uri.parse(
        '${ApiConfig.baseUrl}/products?page=$page&size=$size&categoryId=$categoryId');

    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);

      //Parse list JSON thành danh sách Product
      return jsonData.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi khi tải sản phẩm: ${response.statusCode}');
    }
  } catch (e) {
    print("fetchProductsByCategoryId error: $e");
    rethrow;
  }
}

/// Lấy danh sách sản phẩm có phân trang và lọc theo thể loại
Future<List<Product>> fetchProductsByCategory(String category, int page) async {
  try {
    const int pageSize = 10; // số sản phẩm mỗi trang
    
    // Map tên category sang ID
    final Map<String, int> categoryMap = {
      "ALL": 0,
      "Watch": 1,
      "Phone": 2,
      "Laptop": 3,
    };

    final categoryId = categoryMap[category] ?? 0;
    
    // Sử dụng endpoint /products với query params: page, size, categoryId
    final url = Uri.parse(
        '${ApiConfig.baseUrl}/products?page=$page&size=$pageSize&categoryId=$categoryId');

    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);

      //Parse list JSON thành danh sách Product
      return jsonData.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi khi tải sản phẩm: ${response.statusCode}');
    }
  } catch (e) {
    print("fetchProductsByCategory error: $e");
    rethrow;
  }
}
