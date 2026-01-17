
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shopsense_new/models/product.dart';
import 'package:shopsense_new/util/constants.dart';

// ✅ Đổi tên cho đúng nghĩa
List<Product> productsFromJson(String str) =>
    List<Product>.from(json.decode(str).map((x) => Product.fromJson(x)));

Future<List<Product>> fetchProducts({
  int page = 0,
  int size = 10,
  int categoryId = 0,
}) async {
  final uri = Uri.parse(
    "$baseUrl/products?page=$page&size=$size&categoryId=$categoryId",
  );

  final response = await http.get(uri);

  print("STATUS: ${response.statusCode}");
  print("BODY: ${response.body}");

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
  final url = Uri.parse('$baseUrl/product/$id');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return Product.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Không thể tải sản phẩm (mã lỗi: ${response.statusCode})');
  }
}

/// Lấy danh sách sản phẩm có phân trang và lọc theo thể loại
Future<List<Product>> fetchProductsByCategoryId({
  required int categoryId,
  required int page,
  int size = 10,
}) async {
  final uri = Uri.parse(
    "$baseUrl/products"
        "?page=$page"
        "&size=$size"
        "&categoryId=$categoryId",
  );

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((e) => Product.fromJson(e)).toList();
  } else {
    throw Exception("Lỗi load sản phẩm");
  }
}
