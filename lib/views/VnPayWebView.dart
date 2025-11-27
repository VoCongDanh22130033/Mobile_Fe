import 'package:flutter/material.dart';
// ✅ ĐÃ THAY THẾ: Import thư viện InAppWebView mới
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class VnPayWebView extends StatefulWidget {
  final String paymentUrl;
  final Function(Uri) onPaymentReturn; // Callback khi giao dịch hoàn tất

  const VnPayWebView({
    super.key,
    required this.paymentUrl,
    required this.onPaymentReturn,
  });

  @override
  State<VnPayWebView> createState() => _VnPayWebViewState();
}

class _VnPayWebViewState extends State<VnPayWebView> {

  // Không cần khai báo 'late final WebViewController controller' nữa
  final String deepLinkScheme = 'myshopsense';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.indigo,
      ),
      body: InAppWebView( // ✅ SỬ DỤNG WIDGET MỚI
        initialUrlRequest: URLRequest(url: Uri.parse(widget.paymentUrl)),

        // Cấu hình WebView (giống như WebViewController Options)
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true, // Đảm bảo JS được bật
            // Tăng cường khả năng tương thích với các trang web cũ/phức tạp
            cacheEnabled: false, // Tắt cache mặc định để tránh xung đột JS
          ),
          // Cài đặt Android để tối ưu hóa hiệu suất (khắc phục lỗi MALI/GPU)
          android: AndroidInAppWebViewOptions(
            mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
            useHybridComposition: true,
          ),
        ),

        // Xử lý Navigation (Kiểm tra Deep Link)
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final uri = navigationAction.request.url;

          if (uri != null && uri.scheme == deepLinkScheme) {
            widget.onPaymentReturn(uri);
            Navigator.pop(context);
            // Ngăn chặn WebView tải tiếp URL Deep Link
            return NavigationActionPolicy.CANCEL;
          }

          return NavigationActionPolicy.ALLOW;
        },

        // Log lỗi JavaScript (Nếu có)
        onConsoleMessage: (controller, consoleMessage) {
          print('WebView Console: ${consoleMessage.message}');
        },

        // Log khi xảy ra lỗi tải trang
        onLoadError: (controller, url, code, message) {
          print('WebView Load Error ($code): $message');
        },
      ),
    );
  }
}