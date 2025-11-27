import 'dart:convert';

CartItem cartItemFromJson(String str) => CartItem.fromJson(json.decode(str));

String cartItemToJson(CartItem data) => json.encode(data.toJson());

List<CartItem> cartItemListFromJson(String str) =>
    List<CartItem>.from(json.decode(str).map((x) => CartItem.fromJson(x)));

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
    id: json["id"],
    customerId: json["customerId"],
    productId: json["productId"],
    sellerId: json["sellerId"],
    storeName: json["storeName"],
    productName: json["productName"],
    productThumbnailUrl: json["productThumbnailUrl"],
    productUnitPrice: json["productUnitPrice"]?.toDouble(),
    productQuantity: json["productQuantity"],
    subTotal: json["subTotal"]?.toDouble(),
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
