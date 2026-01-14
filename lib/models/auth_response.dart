import 'dart:convert';
import 'customer.dart';

AuthResponse authResponseFromJson(String str) =>
    AuthResponse.fromJson(json.decode(str));

String authResponseToJson(AuthResponse data) =>
    json.encode(data.toJson());

class AuthResponse {
  final String status;
  final String? token;
  final Customer? customer;

  AuthResponse({
    required this.status,
    required this.token,
    required this.customer,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    status: json["status"],
    token: json["token"],
    customer: json["user"] != null
        ? Customer.fromJson(json["user"])
        : null,
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "token": token,
    "user": customer?.toJson(),
  };
}
