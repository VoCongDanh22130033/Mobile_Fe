import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsense_new/util/constants.dart';
import 'dart:convert';

Future<String?> uploadFile(File file) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload'),
    );

    // Add file
    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    // Add headers
    request.headers.addAll({
      if (token.isNotEmpty) "Authorization": "Bearer $token",
      "ngrok-skip-browser-warning": "true",
    });

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(responseBody);
      if (data['status'] == 'success' && data['fileUrl'] != null) {
        return data['fileUrl'] as String;
      }
    }
    return null;
  } catch (e) {
    print("Error uploading file: $e");
    return null;
  }
}
