import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform; // Thêm import cho Platform nếu cần thiết

class PaymentService {
  final String backendBaseUrl;
  final String deepLinkScheme = 'myshopsense';

  PaymentService({required this.backendBaseUrl});

  Future<String?> fetchVnPayUrl(int amount) async {
    const apiEndpoint = '/api/payment/create';
    final createPaymentUrl = Uri.parse('$backendBaseUrl$apiEndpoint');

    // --- FE DEBUG LOG ---
    print('FE DEBUG - Sending request to Backend: Amount (VND) = $amount');
    // --------------------

    try {
      final response = await http.post(
        createPaymentUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          // Gửi scheme để Backend có thể tạo URL trả về chính xác nếu cần
          'returnUrlScheme': deepLinkScheme
        }),
      );

      if (response.statusCode != 200) {
        print('FE ERROR - Backend returned status ${response.statusCode}: ${response.body}');
        return null;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final vnPayUrl = data['paymentUrl'] as String?;

      if (vnPayUrl != null && vnPayUrl.isNotEmpty) {
        // --- FE DEBUG LOG ---
        print('FE DEBUG - Received Payment URL: $vnPayUrl');
        // --------------------
        return vnPayUrl; // Trả về URL để mở WebView
      }

      print('FE ERROR - Backend response missing paymentUrl or URL is empty.');
      return null;

    } catch (e) {
      print('FE ERROR - Exception during API call: $e');
      return null;
    }
  }
}