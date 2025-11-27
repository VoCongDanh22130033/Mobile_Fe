import 'dart:convert';

Customer customerFromJson(String str) => Customer.fromJson(json.decode(str));

String customerToJson(Customer data) => json.encode(data.toJson());

class Customer {
  int id;
  String name;
  String email;
  String? password;
  String address;
  String? status;
  bool emailVerified;
  String role;
  String? img; // dùng img thay vì image

  Customer({
    required this.id,
    required this.name,
    required this.email,
    this.password,
    required this.address,
    this.status,
    required this.emailVerified,
    required this.role,
    this.img, // thêm vào constructor
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json["id"] ?? 0,
    name: json["name"] ?? '',
    email: json["email"] ?? '',
    password: json["password"],
    address: json["address"] ?? '',
    status: json["status"],
    emailVerified: json["emailVerified"] ?? false,
    role: json["role"] ?? '',
    img: json['img'], // dùng img ở đây
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "password": password,
    "address": address,
    "status": status,
    "emailVerified": emailVerified,
    "role": role,
    "img": img, // lưu img luôn
  };
}
