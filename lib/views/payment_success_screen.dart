import 'package:flutter/material.dart';
import '../models/payment_result_model.dart';
import 'order_placed_view.dart';

class PaymentResultScreen extends StatelessWidget {
  final PaymentResultModel result;
  final String? orderId; 

  const PaymentResultScreen({
    Key? key,
    required this.result,
    this.orderId, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = result.isSuccess ? Colors.green : Colors.red;
    final IconData primaryIcon = result.isSuccess ? Icons.check_circle : Icons.cancel;
    final String statusText = result.isSuccess ? 'Thanh Toán Thành Công!' : 'Thanh Toán Thất Bại';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết Quả Giao Dịch'),
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false, // Không hiển thị nút back
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

              _buildInfoCard(
                icon: Icons.receipt,
                title: 'Mã Giao Dịch VNPAY',
                value: result.transactionRef,
              ),
              if (result.isSuccess && orderId != null)
                _buildInfoCard(
                  icon: Icons.inventory_2,
                  title: 'Mã Đơn Hàng Của Bạn',
                  value: '#$orderId',
                ),

              _buildInfoCard(
                icon: Icons.monetization_on,
                title: 'Số Tiền',
                value: result.amount,
              ),
              _buildInfoCard(
                icon: Icons.calendar_today,
                title: 'Thời Gian',
                value: result.payDate,
              ),

              const SizedBox(height: 40.0),

              if (result.isSuccess && orderId != null)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => OrderPlacedView(orderId: orderId!),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text('Xem Chi Tiết Đơn Hàng', style: TextStyle(color: Colors.white)),
                ),

              const SizedBox(height: 10),

              OutlinedButton(
                onPressed: () {
                   Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
                },
                child: Text(result.isSuccess ? 'Tiếp Tục Mua Sắm' : 'Thử Lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
