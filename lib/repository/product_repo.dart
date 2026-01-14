
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shopsense_new/models/product.dart';
import 'package:shopsense_new/util/constants.dart';

List<Product> productsFromJson(String str) =>
    List<Product>.from(json.decode(str).map((x) => Product.fromJson(x)));

Future<List<Product>> fetchProducts() async {
  final url = Uri.parse('${ApiConfig.baseUrl}/products');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    try {
      return productsFromJson(response.body);
    } catch (e) {
      throw Exception('Lỗi parse JSON sản phẩm: $e');
    }
  } else {
    throw Exception('Không thể tải danh sách sản phẩm (mã lỗi: ${response.statusCode})');
  }
}

Future<Product> fetchProduct(String id) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/product/$id');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return Product.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Không thể tải sản phẩm (mã lỗi: ${response.statusCode})');
  }
}

/// Lấy danh sách sản phẩm có phân trang và lọc theo thể loại
Future<List<Product>> fetchProductsByCategory(String category, int page) async {
  try {
    const int pageSize = 10; // số sản phẩm mỗi trang
    late Uri url;

    // Nếu chọn "Tất cả" → lấy toàn bộ sản phẩm
    if (category == "ALL") {
      url = Uri.parse('${ApiConfig.baseUrl}/product/all?page=$page&pageSize=$pageSize');
    } else {
      // Map tên category sang ID
      final Map<String, int> categoryMap = {
        "Watch": 1,
        "Phone": 2,
        "Laptop": 3,
      };

      final int categoryId = categoryMap[category] ?? 1;

      url = Uri.parse(
          '${ApiConfig.baseUrl}/category/products?categoryId=$categoryId&page=$page&pageSize=$pageSize');
    }

    final response = await http.get(url);

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
