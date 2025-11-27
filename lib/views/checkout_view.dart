import 'package:flutter/material.dart';
import 'package:shopsense_new/models/cart_item.dart';
import 'package:shopsense_new/models/order_details.dart';
import 'package:shopsense_new/models/place_order.dart';
import 'package:shopsense_new/repository/customer_repo.dart';
import 'package:shopsense_new/views/order_placed_view.dart';
import 'package:shopsense_new/util/constants.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import 'package:shopsense_new/models/payment_result_model.dart';
import 'package:shopsense_new/views/payment_success_screen.dart'; // Đã sửa đổi để chấp nhận callback

class PaymentService {
  final String backendBaseUrl;
  final String deepLinkScheme = 'myshopsense';
  PaymentService({required this.backendBaseUrl});


  Future<String?> fetchVnPayUrl(int amount) async {
    const apiEndpoint = '/api/payment/create';
    final createPaymentUrl = Uri.parse('$backendBaseUrl$apiEndpoint');

    try {
      final response = await http.post(
        createPaymentUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'returnUrlScheme': deepLinkScheme
        }),
      );

      if (response.statusCode != 200) {
        print('Backend Error: ${response.body}');
        return null;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final vnPayUrl = data['paymentUrl'] as String?;

      if (vnPayUrl != null && vnPayUrl.isNotEmpty) {
        return vnPayUrl;
      }
      return null;
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
  // --- Controllers ---
  final TextEditingController _division = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _postCode = TextEditingController();
  final TextEditingController _street = TextEditingController();

  // --- Logic Dữ liệu & Tính toán ---
  List<CartItem> items = [];
  double orderTotal = 0;
  double discount = 0;
  double shippingCharge = 0;
  double subTotal = 0;
  double gatewayFee = 0;

  // --- Logic Thanh toán ---
  final PaymentService paymentService = PaymentService(backendBaseUrl: 'http://192.168.2.4:8080');
  String _selectedPaymentMethod = 'COD';

  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    getCartItems();
    _initUniLinks();
  }

// --- CÁC HÀM TIỆN ÍCH FORMAT DỮ LIỆU ---

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

  // --- HÀM LẮNG NGHE DEEP LINK ---
  void _initUniLinks() async {
    // 1. Xử lý trường hợp App đang đóng (Initial Link)
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(Uri.parse(initialLink));
      }
    } on PlatformException catch (e) {
      print('Lỗi lấy Initial Link: $e');
    }

    // 2. Xử lý trường hợp App đang mở (Stream Link)
    _sub = linkStream.listen((String? uri) {
      if (!mounted) return;
      if (uri != null) {
        _handleDeepLink(Uri.parse(uri));
      }
    }, onError: (err) {
      if (!mounted) return;
      showMessage('Lỗi Deep Link: $err');
    });
  }

  // --- HÀM XỬ LÝ CHÍNH KẾT QUẢ TỪ VNPAY ---
  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'myshopsense' && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'vnpay_return') {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleVnPayResult(uri);
        }
      });
    }
  }


  @override
  void dispose() {
    _sub?.cancel();
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
    setState(() {});
  }

  // --- LOGIC XỬ LÝ ĐẶT HÀNG SAU KHI THANH TOÁN XONG ---
  void _processOrder(String paymentMethod, String paymentStatus) async {
    List<OrderDetail> orderDetails = [];
    for (CartItem item in items) {
      orderDetails.add(OrderDetail(
        id: 0,
        orderId: 0,
        productId: item.productId,
        sellerId: item.sellerId,
        storeName: item.storeName,
        productName: item.productName,
        productUnitPrice: item.productUnitPrice.round().toDouble(),
        productThumbnailUrl: item.productThumbnailUrl,
        status: "Pending",
        quantity: item.productQuantity,
        subTotal: item.subTotal.round().toDouble(),
        deliveryDate: DateTime.now(),
      ));
    }

    final order = PlaceOrder(
      id: 0,
      orderDate: DateTime.now(),
      orderTotal: orderTotal.round().toDouble(),
      customerId: 0,
      discount: discount.round().toDouble(),
      shippingCharge: 0.0,
      tax: 0.0,
      shippingStreet: _street.text,
      shippingCity: _district.text,
      shippingPostCode: _postCode.text,
      shippingState: _division.text,
      shippingCountry: "Bangladesh",
      status: "Processing",
      subTotal: subTotal.round().toDouble(),
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      cardNumber: "",
      cardCvv: "",
      cardHolderName: "",
      cardExpiryDate: "",
      gatewayFee: gatewayFee.round().toDouble(),
      orderDetails: orderDetails,
    );

    String orderId = await customerPlaceOrder(order);
    if (orderId != "") {
      // Sau khi xử lý đơn hàng, chuyển đến màn hình xác nhận đặt hàng
      // LƯU Ý: Dòng này sẽ được gọi SAU KHI PaymentResultScreen hiển thị 2s
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderPlacedView(orderId: orderId),
        ),
      );
    } else {
      showMessage("Something went wrong");
    }
  }

  // --- HÀM GỌI CHÍNH KHI NHẤN NÚT (Điều hướng logic) ---
  void placeOrder(String method) async {
    if (method == 'COD') {
      _processOrder("COD", "Pending");
      return;
    }
    if (method == 'VNPay') {
      showMessage("Đang chuẩn bị cổng VNPay...");

      int amountInVND = orderTotal.round();

      String? vnPayUrl = await paymentService.fetchVnPayUrl(amountInVND);

      if (vnPayUrl != null) {
        try {
          if (await canLaunchUrl(Uri.parse(vnPayUrl))) {
            await launchUrl(
              Uri.parse(vnPayUrl),
              mode: LaunchMode.externalApplication,
            );
            showMessage("Đã chuyển đến cổng thanh toán. Vui lòng hoàn tất.");
          } else {
            showMessage('Không thể mở URL thanh toán VNPAY.');
          }
        } catch (e) {
          showMessage('Lỗi khi mở URL: $e');
        }
      } else {
        showMessage("Không thể tạo URL thanh toán. Vui lòng thử lại.");
      }
    }

  }

  showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ✅ HÀM XỬ LÝ KẾT QUẢ TRẢ VỀ TỪ DEEP LINK VÀ CHUYỂN HƯỚNG (ĐÃ SỬA ĐỔI)
  void _handleVnPayResult(Uri uri) {
    final String responseCode = uri.queryParameters['vnp_ResponseCode'] ?? '';
    final String transactionStatus = uri.queryParameters['vnp_TransactionStatus'] ?? '';
    final String txnRef = uri.queryParameters['vnp_TxnRef'] ?? '';
    final String amount = uri.queryParameters['vnp_Amount'] ?? '0';
    final String bankCode = uri.queryParameters['vnp_BankCode'] ?? 'N/A';
    final String payDate = uri.queryParameters['vnp_PayDate'] ?? 'N/A';

    final resultData = PaymentResultModel(
      transactionRef: txnRef,
      amount: _formatVnPayAmount(amount),
      bankCode: bankCode,
      payDate: _formatVnPayDate(payDate),
      responseCode: responseCode,
      transactionStatus: transactionStatus,
    );

    // ✅ 1. XÁC ĐỊNH HÀM XỬ LÝ ĐƠN HÀNG (CHỈ KHI THÀNH CÔNG)
    final VoidCallback? processOrderCallback = resultData.isSuccess
        ? () => _processOrder("VNPay", "Paid")
        : null;

    // ✅ 2. CHUYỂN HƯỚNG TỚI MÀN HÌNH KẾT QUẢ VÀ TRUYỀN CALLBACK
    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PaymentResultScreen(
          result: resultData,
          // Truyền hàm callback vào màn hình kết quả
          onProcessOrderSuccess: processOrderCallback,
        ),
      ),
    );

    // ❌ KHÔNG GỌI .then((_) {...}) Ở ĐÂY NỮA
    print('✅ DEBUG: Cuối hàm _handleVnPayResult. Chuyển giao xử lý cho PaymentResultScreen.');
  }


  @override
  Widget build(BuildContext context) {
    // ... (Phần build không thay đổi)
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
                  // === Shipping Info ===
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Shipping Info",
                      style: TextStyle(
                        fontSize: 20,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  buildTextField(_street, "Street Address"),
                  buildTextField(_postCode, "Post Code"),
                  buildTextField(_district, "District"),
                  buildTextField(_division, "Division"),
                  const SizedBox(height: 25),

                  // === Order Summary ===
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Order Summary",
                      style: TextStyle(
                        fontSize: 20,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FutureBuilder<List<CartItem>>(
                    future: customerCart(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(snapshot.error.toString()),
                        );
                      } else if (snapshot.hasData) {
                        final cartItems = snapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  item.productThumbnailUrl != null
                                      ? (item.productThumbnailUrl!.startsWith('http')
                                      ? item.productThumbnailUrl!
                                      : '$baseUrl/${item.productThumbnailUrl}')
                                      : 'https://via.placeholder.com/80',
                                  width: 55,
                                  height: 55,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported,
                                      size: 40, color: Colors.grey),
                                ),
                              ),
                              title: Text(
                                "${item.productName} x${item.productQuantity}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                item.storeName ?? "",
                                style: const TextStyle(fontSize: 13),
                              ),
                              trailing: Text(
                                "\$${_formatIntPrice(item.subTotal)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),

                  const SizedBox(height: 15),

                  // === Payment Method Section ===
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Payment Method",
                      style: TextStyle(
                        fontSize: 20,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  RadioListTile<String>(
                    title: const Text('Thanh toán khi nhận hàng (COD)'),
                    value: 'COD',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Thanh toán VNPay (Online)'),
                    value: 'VNPay',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 15),

                  // === Summary Calculation ===
                  buildSummaryRow("Subtotal (Discounted) :", subTotal),

                  if (discount > 0)
                    buildSummaryRow("Discount :", -discount, color: Colors.red),

                  if (gatewayFee > 0)
                    buildSummaryRow("Gateway Fee :", gatewayFee),

                  const SizedBox(height: 15),

                  buildSummaryRow("Order Total :", orderTotal,
                      isBold: true, color: Colors.indigo),
                ],
              ),
            ),
          ),

          // === Footer: Nút Đặt hàng / Thanh toán ===
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
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                    ),
                    onPressed: () {
                      placeOrder(_selectedPaymentMethod);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            _selectedPaymentMethod == 'COD'
                                ? Icons.local_shipping
                                : Icons.payment,
                            color: Colors.white),
                        const SizedBox(width: 8.0),
                        Text(
                          _selectedPaymentMethod == 'COD'
                              ? 'Place Order (COD)'
                              : 'Thanh toán VNPay',
                          style: const TextStyle(fontSize: 15, color: Colors.white),
                        ),
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

  // --- tiện ích tạo input ---
  Widget buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 16),
          border: const OutlineInputBorder(),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  // --- tiện ích dòng tổng kết ---
  Widget buildSummaryRow(String title, double value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 25),
            child: Text(
              title,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 16, color: color),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 25),
            child: Text(
              "\$${_formatIntPrice(value)}",
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}