
import 'package:shopsense_new/util/constants.dart';

class Product {
  final int id;
  final String title;
  final String thumbnailUrl;
  final String description;
  final String regularPrice;
  final String salePrice;
  final String category;
  final String stockStatus;
  final String stockCount;
  final int sellerId;
  final String storeName;
  final String status;

  const Product({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.description,
    required this.regularPrice,
    required this.salePrice,
    required this.category,
    required this.stockStatus,
    required this.stockCount,
    required this.sellerId,
    required this.storeName,
    required this.status,
  });

  factory Product.fromJson(Map<dynamic, dynamic> json) {
    String thumb = json['thumbnailUrl'] ?? '';

    //Nếu ảnh không bắt đầu bằng http hoặc https, thêm baseUrl
    if (!thumb.startsWith('http')) {
      thumb = '${ApiConfig.baseUrl}/$thumb';
    }

    return Product(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      thumbnailUrl: thumb,
      description: json['description'] ?? '',
      regularPrice: json['regularPrice']?.toString() ?? '',
      salePrice: json['salePrice']?.toString() ?? '',
      category: json['category'] ?? '',
      stockStatus: json['stockStatus'] ?? '',
      stockCount: json['stockCount']?.toString() ?? '',
      sellerId: json['sellerId'] ?? 0,
      storeName: json['storeName'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "thumbnailUrl": thumbnailUrl,
    "description": description,
    "regularPrice": regularPrice,
    "salePrice": salePrice,
    "category": category,
    "stockStatus": stockStatus,
    "stockCount": stockCount,
    "sellerId": sellerId,
    "storeName": storeName,
    "status": status,
  };
}
