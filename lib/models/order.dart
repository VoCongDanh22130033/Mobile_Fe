import 'dart:convert';

Order orderFromJson(String str) => Order.fromJson(json.decode(str));

String orderToJson(Order data) => json.encode(data.toJson());

List<Order> orderListFromJson(String str) =>
    List<Order>.from(json.decode(str).map((x) => Order.fromJson(x)));

class Order {
  int id;
  DateTime orderDate;
  double orderTotal;
  int customerId;
  double discount;
  double shippingCharge;
  double tax;
  String shippingStreet;
  String shippingCity;
  String shippingPostCode;
  String shippingState;
  String shippingCountry;
  String status;
  double subTotal;
  String paymentStatus;
  String paymentMethod;
  String cardNumber;
  String cardCvv;
  String cardHolderName;
  String cardExpiryDate;
  double gatewayFee;

  Order({
    required this.id,
    required this.orderDate,
    required this.orderTotal,
    required this.customerId,
    required this.discount,
    required this.shippingCharge,
    required this.tax,
    required this.shippingStreet,
    required this.shippingCity,
    required this.shippingPostCode,
    required this.shippingState,
    required this.shippingCountry,
    required this.status,
    required this.subTotal,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.cardNumber,
    required this.cardCvv,
    required this.cardHolderName,
    required this.cardExpiryDate,
    required this.gatewayFee,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json["id"],
        orderDate: DateTime.parse(json["orderDate"]),
        orderTotal: json["orderTotal"]?.toDouble(),
        customerId: json["customerId"],
        discount: json["discount"],
        shippingCharge: json["shippingCharge"],
        tax: json["tax"]?.toDouble(),
        shippingStreet: json["shippingStreet"],
        shippingCity: json["shippingCity"],
        shippingPostCode: json["shippingPostCode"],
        shippingState: json["shippingState"],
        shippingCountry: json["shippingCountry"],
        status: json["status"],
        subTotal: json["subTotal"],
        paymentStatus: json["paymentStatus"],
        paymentMethod: json["paymentMethod"],
        cardNumber: json["cardNumber"],
        cardCvv: json["cardCvv"],
        cardHolderName: json["cardHolderName"],
        cardExpiryDate: json["cardExpiryDate"],
        gatewayFee: json["gatewayFee"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "orderDate":
            "${orderDate.year.toString().padLeft(4, '0')}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}",
        "orderTotal": orderTotal,
        "customerId": customerId,
        "discount": discount,
        "shippingCharge": shippingCharge,
        "tax": tax,
        "shippingStreet": shippingStreet,
        "shippingCity": shippingCity,
        "shippingPostCode": shippingPostCode,
        "shippingState": shippingState,
        "shippingCountry": shippingCountry,
        "status": status,
        "subTotal": subTotal,
        "paymentStatus": paymentStatus,
        "paymentMethod": paymentMethod,
        "cardNumber": cardNumber,
        "cardCvv": cardCvv,
        "cardHolderName": cardHolderName,
        "cardExpiryDate": cardExpiryDate,
        "gatewayFee": gatewayFee,
      };
}
