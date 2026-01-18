import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    //Flutter Web
    if (kIsWeb) {
      return "http://localhost:8080";
      //KHÔNG dùng ngrok khi chạy web local
    }

    //Android Emulator
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8080";
    }

    //iOS Simulator (nếu có)
    if (Platform.isIOS) {
      return "http://localhost:8080";
    }

    //Windows / macOS app
    return "http://localhost:8080";
  }

  //Hàm xử lý URL ảnh an toàn
  static String getImageUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }

    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return "${baseUrl}/$cleanPath";
  }
}
