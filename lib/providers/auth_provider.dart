import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String _userId = "";
  String _token = "";

  AuthProvider() {
    // Khởi tạo dữ liệu khi app mở
    updateUserId();
  }

  String get userId => _userId;
  String get token => _token;

  // 🔴 Sửa từ 'void' thành 'Future<void>' để có thể sử dụng 'await' từ bên ngoài
  Future<void> updateUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? "";
    _token = prefs.getString('token') ?? "";

    // In log để debug (tùy chọn)
    debugPrint("AuthProvider: Đã cập nhật userId = $_userId");

    notifyListeners();
  }

  // 🔴 Sửa từ 'void' thành 'Future<void>' để đảm bảo đăng xuất xong mới làm việc khác
  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('token');
    _userId = "";
    _token = ""; // Reset cả token

    notifyListeners();
  }
}