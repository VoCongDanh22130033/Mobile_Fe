import 'dart:convert';

// Helper functions để convert nhanh
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
  String? img;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    this.password,
    required this.address,
    this.status,
    required this.emailVerified,
    required this.role,
    this.img,
  });

  // 1. CopyWith: Cực kỳ quan trọng khi Update Profile
  // Giúp bạn giữ nguyên ID, Email cũ, chỉ thay đổi Name hoặc Address mới
  Customer copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? address,
    String? status,
    bool? emailVerified,
    String? role,
    String? img,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      address: address ?? this.address,
      status: status ?? this.status,
      emailVerified: emailVerified ?? this.emailVerified,
      role: role ?? this.role,
      img: img ?? this.img,
    );
  }

  // 2. FromJson: Xử lý an toàn để tránh crash app nếu Backend trả về null
  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json["id"] is int ? json["id"] : int.tryParse(json["id"].toString()) ?? 0,
    name: json["name"] ?? '',
    email: json["email"] ?? '',
    password: json["password"], // Password thường backend không trả về, để null ok
    address: json["address"] ?? '',
    status: json["status"],
    emailVerified: json["emailVerified"] ?? false,
    role: json["role"] ?? 'CUSTOMER',
    img: json["img"], // Map đúng key 'img' từ Java
  );

  // 3. ToJson: Gửi đúng key mà Backend Java đang đợi
  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "password": password,
    "address": address,
    "status": status,
    "emailVerified": emailVerified,
    "role": role,
    "img": img,
  };

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, email: $email, img: $img)';
  }
}