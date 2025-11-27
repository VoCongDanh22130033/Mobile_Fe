import 'dart:convert';

AuthResponse authResponseFromJson(String str) => AuthResponse.fromJson(json.decode(str));

String authResponseToJson(AuthResponse data) => json.encode(data.toJson());

class AuthResponse {
  String status;
  String? token;
  Map<String, dynamic>? user;

  AuthResponse({
    required this.status,
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    status: json["status"],
    token: json["token"],
    user: json["user"],
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "token": token,
    "user": user,
  };
}