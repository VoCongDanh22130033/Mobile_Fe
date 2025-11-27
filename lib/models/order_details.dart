import 'dart:convert';

OrderDetail orderFromJson(String str) => OrderDetail.fromJson(json.decode(str));

String orderToJson(OrderDetail data) => json.encode(data.toJson());

List<OrderDetail> orderDetailListFromJson(String str) =>
    List<OrderDetail>.from(json.decode(str).map((x) => OrderDetail.fromJson(x)));

class OrderDetail {
  int id;
  int orderId;
  int productId;
  int sellerId;
  String storeName;
  String productName;
  double productUnitPrice;
  String productThumbnailUrl;
  String status;
  int quantity;
  double subTotal;
  DateTime deliveryDate;

  OrderDetail({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.sellerId,
    required this.storeName,
    required this.productName,
    required this.productUnitPrice,
    required this.productThumbnailUrl,
    required this.status,
    required this.quantity,
    required this.subTotal,
    required this.deliveryDate,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
    id: json["id"],
    orderId: json["orderId"],
    productId: json["productId"],
    sellerId: json["sellerId"],
    storeName: json["storeName"],
    productName: json["productName"],
    productUnitPrice: json["productUnitPrice"],
    productThumbnailUrl: json["productThumbnailUrl"],
    status: json["status"],
    quantity: json["quantity"],
    subTotal: json["subTotal"],
    deliveryDate: DateTime.parse(json["deliveryDate"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "orderId": orderId,
    "productId": productId,
    "sellerId": sellerId,
    "storeName": storeName,
    "productName": productName,
    "productUnitPrice": productUnitPrice,
    "productThumbnailUrl": productThumbnailUrl,
    "status": status,
    "quantity": quantity,
    "subTotal": subTotal,
    "deliveryDate":
    "${deliveryDate.year.toString().padLeft(4, '0')}-${deliveryDate.month.toString().padLeft(2, '0')}-${deliveryDate.day.toString().padLeft(2, '0')}",
  };
}
