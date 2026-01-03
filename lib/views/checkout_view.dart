import 'package:flutter/material.dart';
import 'package:shopsense_new/models/cart_item.dart';
import 'package:shopsense_new/models/order_details.dart';
import 'package:shopsense_new/models/place_order.dart';
import 'package:shopsense_new/repository/customer_repo.dart';
import 'package:shopsense_new/views/order_placed_view.dart';
import 'package:shopsense_new/util/constants.dart'; // baseUrl
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shopsense_new/models/payment_result_model.dart';
import 'package:shopsense_new/views/payment_success_screen.dart';

class PaymentService {
  final String backendBaseUrl;
  PaymentService({required this.backendBaseUrl});

  Future<String?> fetchVnPayUrl(int amount) async {
    const apiEndpoint = '/api/payment/create';
    final createPaymentUrl = Uri.parse('$backendBaseUrl$apiEndpoint');

    try {
      final response = await http.post(
        createPaymentUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );

      if (response.statusCode != 200) {
        print('Backend Error: ${response.body}');
        return null;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['paymentUrl'] as String?;
    } catch (e) {
      print('Lỗi gọi API: $e');
      return null;
    }
  }
}

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final TextEditingController _division = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _postCode = TextEditingController();
  final TextEditingController _street = TextEditingController();

  List<CartItem> items = [];
  double orderTotal = 0;
  double discount = 0;
  double shippingCharge = 0;
  double subTotal = 0;
  double gatewayFee = 0;

  final PaymentService paymentService = PaymentService(backendBaseUrl: baseUrl);
  String _selectedPaymentMethod = 'COD';

  @override
  void initState() {
    super.initState();
    getCartItems();
  }

  String _formatVnPayAmount(String amount) {
    try {
      final double vndAmount = int.parse(amount) / 100.0;
      return '${vndAmount.round().toString()} VNĐ';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatVnPayDate(String date) {
    if (date.length == 14) {
      try {
        final year = date.substring(0, 4);
        final month = date.substring(4, 6);
        final day = date.substring(6, 8);
        final hour = date.substring(8, 10);
        final minute = date.substring(10, 12);
        final second = date.substring(12, 14);
        return '$day/$month/$year $hour:$minute:$second';
      } catch (e) {
        return 'N/A';
      }
    }
    return 'N/A';
  }

  String _formatIntPrice(double value) {
    return value.round().toString();
  }

  @override
  void dispose() {
    _division.dispose();
    _district.dispose();
    _postCode.dispose();
    _street.dispose();
    super.dispose();
  }

  void getCartItems() async {
    items = await customerCart();
    subTotal = 0;
    for (CartItem i in items) {
      subTotal += i.subTotal;
    }

    orderTotal = subTotal + gatewayFee - discount;
    if(mounted) setState(() {});
  }

  Future<String> _processOrder(String paymentMethod, String paymentStatus) async {
    List<OrderDetail> orderDetails = [];
    for (CartItem item in items) {
      orderDetails.add(OrderDetail(
        id: 0, orderId: 0, productId: item.productId, sellerId: item.sellerId,
        storeName: item.storeName, productName: item.productName,
        productUnitPrice: item.productUnitPrice.round().toDouble(),
        productThumbnailUrl: item.productThumbnailUrl, status: "Pending",
        quantity: item.productQuantity, subTotal: item.subTotal.round().toDouble(),
        deliveryDate: DateTime.now(),
      ));
    }

    final order = PlaceOrder(
      id: 0, orderDate: DateTime.now(), orderTotal: orderTotal.round().toDouble(),
      customerId: 0, discount: discount.round().toDouble(), shippingCharge: 0.0,
      tax: 0.0, shippingStreet: _street.text, shippingCity: _district.text,
      shippingPostCode: _postCode.text, shippingState: _division.text,
      shippingCountry: "Bangladesh", status: "Processing",
      subTotal: subTotal.round().toDouble(), paymentStatus: paymentStatus,
      paymentMethod: paymentMethod, cardNumber: "", cardCvv: "",
      cardHolderName: "", cardExpiryDate: "",
      gatewayFee: gatewayFee.round().toDouble(), orderDetails: orderDetails,
    );

    String orderId = await customerPlaceOrder(order);
    return orderId;
  }

  void placeOrder(String method) async {
    if (method == 'COD') {
      String orderId = await _processOrder("COD", "Pending");
      if (orderId.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OrderPlacedView(orderId: orderId)),
        );
      } else {
        showMessage("Something went wrong");
      }
      return;
    }

    if (method == 'VNPay') {
      showMessage("Đang chuẩn bị cổng VNPay...");
      int amountInVND = orderTotal.round();
      String? vnPayUrl = await paymentService.fetchVnPayUrl(amountInVND);

      if (vnPayUrl != null && mounted) {
        final resultUrl = await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (context) => VnPayWebView(vnPayUrl: vnPayUrl)),
        );

        if (resultUrl != null && mounted) {
          final uri = Uri.parse(resultUrl);
          _processVnPayResult(uri);
        } else if (mounted) {
          showMessage("Giao dịch đã bị hủy.");
        }
      } else {
        showMessage("Không thể tạo URL thanh toán. Vui lòng thử lại.");
      }
    }
  }

  void _processVnPayResult(Uri uri) async {
    final resultData = PaymentResultModel(
      transactionRef: uri.queryParameters['vnp_TxnRef'] ?? '',
      amount: _formatVnPayAmount(uri.queryParameters['vnp_Amount'] ?? '0'),
      bankCode: uri.queryParameters['vnp_BankCode'] ?? 'N/A',
      payDate: _formatVnPayDate(uri.queryParameters['vnp_PayDate'] ?? 'N/A'),
      responseCode: uri.queryParameters['vnp_ResponseCode'] ?? '',
      transactionStatus: uri.queryParameters['vnp_TransactionStatus'] ?? '',
    );

    String paymentStatus = resultData.isSuccess ? "Paid" : "Failed";
    String orderId = await _processOrder("VNPay", paymentStatus);

    if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => PaymentResultScreen(
                    result: resultData,
                    orderId: orderId.isNotEmpty ? orderId : null,
                ),
            ),
            (Route<dynamic> route) => false,
        );
    }
  }

  showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text("Order Confirmation"),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Shipping Info", style: TextStyle(fontSize: 20, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
                  ),
                  buildTextField(_street, "Street Address"),
                  buildTextField(_postCode, "Post Code"),
                  buildTextField(_district, "District"),
                  buildTextField(_division, "Division"),
                  const SizedBox(height: 25),

                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Order Summary", style: TextStyle(fontSize: 20, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
                  ),
                  FutureBuilder<List<CartItem>>(
                    future: customerCart(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString()));
                      } else if (snapshot.hasData) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final item = snapshot.data![index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  item.productThumbnailUrl != null ? (item.productThumbnailUrl!.startsWith('http') ? item.productThumbnailUrl! : '$baseUrl/${item.productThumbnailUrl}') : 'https://via.placeholder.com/80',
                                  width: 55, height: 55, fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                ),
                              ),
                              title: Text("${item.productName} x${item.productQuantity}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(item.storeName ?? "", style: const TextStyle(fontSize: 13)),
                              trailing: Text("\$${_formatIntPrice(item.subTotal)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                            );
                          },
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),

                  const SizedBox(height: 15),

                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Payment Method", style: TextStyle(fontSize: 20, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
                  ),
                  RadioListTile<String>(
                    title: const Text('Thanh toán khi nhận hàng (COD)'),
                    value: 'COD',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Thanh toán VNPay (Online)'),
                    value: 'VNPay',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                  ),
                  const SizedBox(height: 15),

                  buildSummaryRow("Subtotal (Discounted) :", subTotal),
                  if (discount > 0) buildSummaryRow("Discount :", -discount, color: Colors.red),
                  if (gatewayFee > 0) buildSummaryRow("Gateway Fee :", gatewayFee),
                  const SizedBox(height: 15),
                  buildSummaryRow("Order Total :", orderTotal, isBold: true, color: Colors.indigo),
                ],
              ),
            ),
          ),
          Container(
            height: 80,
            width: double.infinity,
            color: Colors.indigo,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
                    onPressed: () => placeOrder(_selectedPaymentMethod),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_selectedPaymentMethod == 'COD' ? Icons.local_shipping : Icons.payment, color: Colors.white),
                        const SizedBox(width: 8.0),
                        Text(_selectedPaymentMethod == 'COD' ? 'Place Order (COD)' : 'Thanh toán VNPay', style: const TextStyle(fontSize: 15, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: TextField(controller: controller, decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
    );
  }

  Widget buildSummaryRow(String label, double value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("\$${_formatIntPrice(value)}", style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}

// ✅ PHIÊN BẢN HOÀN THIỆN NHẤT: Hỗ trợ xử lý pop-up
class VnPayWebView extends StatefulWidget {
  final String vnPayUrl;

  const VnPayWebView({super.key, required this.vnPayUrl});

  @override
  State<VnPayWebView> createState() => _VnPayWebViewState();
}

class _VnPayWebViewState extends State<VnPayWebView> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewController? popupWebViewController; // Controller cho popup
  double progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán VNPay")),
      body: Column(
        children: <Widget>[
          if (progress < 1.0) LinearProgressIndicator(value: progress),
          Expanded(
            child: InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(url: Uri.parse(widget.vnPayUrl)),
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  useShouldOverrideUrlLoading: true, // Bắt buộc để shouldOverrideUrlLoading hoạt động
                  javaScriptCanOpenWindowsAutomatically: true, // Cho phép JS mở cửa sổ mới
                ),
                android: AndroidInAppWebViewOptions(
                  useHybridComposition: true, // Bắt buộc đối với một số phiên bản Android
                ),
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  this.progress = progress / 100;
                });
              },
              // ✅ SỬA LỖI: Xử lý khi có cửa sổ mới được tạo
              onCreateWindow: (controller, createWindowAction) async {
                print("onCreateWindow event detected");
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: SizedBox(
                        width: double.maxFinite,
                        height: 500,
                        child: InAppWebView(
                          // Gán key cho webview trong popup
                          windowId: createWindowAction.windowId,
                          initialOptions: InAppWebViewGroupOptions(
                            crossPlatform: InAppWebViewOptions(
                              useShouldOverrideUrlLoading: true,
                            ),
                            android: AndroidInAppWebViewOptions(
                              useHybridComposition: true,
                            ),
                          ),
                          onWebViewCreated: (controller) {
                            popupWebViewController = controller;
                          },
                          shouldOverrideUrlLoading: (popupController, navigationAction) async {
                            final uri = navigationAction.request.url;
                            print("Intercepted URL in Popup: $uri");
                            if (uri != null && uri.scheme == "myshopsense") {
                              // Đóng dialog
                              Navigator.of(context, rootNavigator: true).pop(); 
                              // Đóng màn hình webview chính và trả kết quả
                              if (Navigator.canPop(context)) {
                                Navigator.of(context).pop(uri.toString());
                              }
                              return NavigationActionPolicy.CANCEL;
                            }
                            return NavigationActionPolicy.ALLOW;
                          },
                        ),
                      ),
                    );
                  },
                );
                // Trả về true để cho phép mở cửa sổ mới
                return true;
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                print("Intercepted URL in Main WebView: $uri");

                if (uri != null && uri.scheme == "myshopsense") {
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop(uri.toString());
                  }
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              onLoadError: (controller, url, code, message) {
                print("Main WebView error: $message (code $code)");
              },
              onLoadHttpError: (controller, url, statusCode, description) {
                print("Main HTTP error: $description (statusCode $statusCode)");
              },
            ),
          ),
        ],
      ),
    );
  }
}
