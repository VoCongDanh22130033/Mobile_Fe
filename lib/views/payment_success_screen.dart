// File: lib/views/payment_success_screen.dart

import 'package:flutter/material.dart';
import '../models/payment_result_model.dart'; // Import Model

// ✅ 1. Sửa đổi thành StatefulWidget
class PaymentResultScreen extends StatefulWidget {
  final PaymentResultModel result;

  // ✅ 2. Thêm tham số callback
  final VoidCallback? onProcessOrderSuccess;

  const PaymentResultScreen({
    Key? key,
    required this.result,
    this.onProcessOrderSuccess, // ✅ Nhận callback
  }) : super(key: key);

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {

  @override
  void initState() {
    super.initState();

    // ✅ 3. Xử lý logic độ trễ và chuyển hướng trong initState
    // Chỉ xử lý nếu giao dịch thành công và có callback được truyền vào
    if (widget.result.isSuccess && widget.onProcessOrderSuccess != null) {
      // Đặt độ trễ 2 giây
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          // Thực thi hàm _processOrder được truyền từ CheckoutView
          widget.onProcessOrderSuccess!();

          // Thao tác này sẽ ghi đè màn hình hiện tại (PaymentResultScreen)
          // bằng OrderPlacedView, hoàn tất luồng.
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu từ widget.result thay vì result (do là State)
    final Color primaryColor = widget.result.isSuccess ? Colors.green : Colors.red;
    final IconData primaryIcon = widget.result.isSuccess ? Icons.check_circle : Icons.cancel;
    final String statusText = widget.result.isSuccess ? 'Thanh Toán Thành Công!' : 'Thanh Toán Thất Bại';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết Quả Thanh Toán'),
        backgroundColor: primaryColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                primaryIcon,
                color: primaryColor,
                size: 100.0,
              ),
              const SizedBox(height: 20.0),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30.0),

              // Hiển thị thông tin giao dịch (Sử dụng widget.result)
              _buildInfoCard(
                icon: Icons.monetization_on,
                title: 'Số Tiền Thanh Toán',
                value: widget.result.amount,
              ),
              _buildInfoCard(
                icon: Icons.receipt,
                title: 'Mã Đơn Hàng',
                value: widget.result.transactionRef,
              ),
              _buildInfoCard(
                icon: Icons.calendar_today,
                title: 'Thời Gian Giao Dịch',
                value: widget.result.payDate,
              ),
              _buildInfoCard(
                icon: Icons.info_outline,
                title: 'Mã Phản Hồi VNPAY',
                value: widget.result.responseCode,
              ),

              const SizedBox(height: 40.0),
              // ✅ Tùy chỉnh: Nút này chỉ đơn thuần đóng màn hình,
              // nhưng hành động hoàn tất đã được xử lý bởi initState (có độ trễ)
              ElevatedButton(
                onPressed: () {
                  // Nếu là thất bại, cho phép người dùng đóng màn hình ngay lập tức
                  if (!widget.result.isSuccess) {
                    Navigator.pop(context);
                  }
                  // Nếu thành công, có thể để mặc cho initState xử lý hoặc pop ngay (tùy ý)
                  // Để nhất quán, nếu thành công thì để initState xử lý chuyển hướng.
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  widget.result.isSuccess ? 'Đang Hoàn Tất...' : 'Đóng',
                  style: const TextStyle(fontSize: 18.0, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Phương thức tiện ích được chuyển vào lớp State
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.grey),
        ),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Colors.black87),
        ),
      ),
    );
  }
}