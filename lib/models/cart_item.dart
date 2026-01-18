import 'dart:convert';

CartItem cartItemFromJson(String str) => CartItem.fromJson(json.decode(str));

String cartItemToJson(CartItem data) => json.encode(data.toJson());

List<CartItem> cartItemListFromJson(String str) {
  final decoded = json.decode(str);
  if (decoded is List) {
    return List<CartItem>.from(decoded.map((x) => CartItem.fromJson(x as Map<String, dynamic>)));
  } else if (decoded is Map) {
    // Nếu là Map, có thể có key chứa list
    if (decoded.containsKey('data') && decoded['data'] is List) {
      return List<CartItem>.from((decoded['data'] as List).map((x) => CartItem.fromJson(x as Map<String, dynamic>)));
    }
    // Nếu là Map đơn, thử convert thành list
    return [CartItem.fromJson(decoded as Map<String, dynamic>)];
  }
  return [];
}

class CartItem {
  int id;
  int customerId;
  int productId;
  int sellerId;
  String storeName;
  String productName;
  String productThumbnailUrl;
  double productUnitPrice;
  int productQuantity;
  double subTotal;

  CartItem({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.sellerId,
    required this.storeName,
    required this.productName,
    required this.productThumbnailUrl,
    required this.productUnitPrice,
    required this.productQuantity,
    required this.subTotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json["id"] ?? 0,
    customerId: json["customerId"] ?? 0,
    productId: json["productId"] ?? 0,
    sellerId: json["sellerId"] ?? 0,
    storeName: json["storeName"]?.toString() ?? '',
    productName: json["productName"]?.toString() ?? '',
    productThumbnailUrl: json["productThumbnailUrl"]?.toString() ?? '',
    productUnitPrice: (json["productUnitPrice"] is num)
        ? (json["productUnitPrice"] as num).toDouble()
        : double.tryParse(json["productUnitPrice"]?.toString() ?? '0') ?? 0.0,
    productQuantity: json["productQuantity"] ?? 1,
    subTotal: (json["subTotal"] is num)
        ? (json["subTotal"] as num).toDouble()
        : double.tryParse(json["subTotal"]?.toString() ?? '0') ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "customerId": customerId,
    "productId": productId,
    "sellerId": sellerId,
    "storeName": storeName,
    "productName": productName,
    "productThumbnailUrl": productThumbnailUrl,
    "productUnitPrice": productUnitPrice,
    "productQuantity": productQuantity,
    "subTotal": subTotal,
  };
}
