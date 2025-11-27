import 'package:flutter/material.dart';
import 'package:shopsense_new/models/place_order.dart';
import 'package:shopsense_new/repository/customer_repo.dart';
import 'package:shopsense_new/util/constants.dart';
import 'package:shopsense_new/home.dart';

class OrderView extends StatefulWidget {
  final String orderId;

  const OrderView({super.key, required this.orderId});

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  PlaceOrder? p;

  @override
  void initState() {
    super.initState();
    getOrder();
  }

  void getOrder() async {
    p = await customerGetOrder(widget.orderId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text("Order Details"),
      ),
      body: p == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order ID: ${p!.id}",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "Placed On: ${p!.orderDate.toString().split(" ")[0]}",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Order Items",
              style: TextStyle(
                fontSize: 20,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<PlaceOrder>(
              future: customerGetOrder(widget.orderId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final order = snapshot.data!;
                return ListView.builder(
                  itemCount: order.orderDetails.length,
                  itemBuilder: (context, index) {
                    final item = order.orderDetails[index];
                    final imageUrl = item.productThumbnailUrl != null &&
                        item.productThumbnailUrl!.isNotEmpty
                        ? (item.productThumbnailUrl!.startsWith("http")
                        ? item.productThumbnailUrl!
                        : "$baseUrl/${item.productThumbnailUrl}")
                        : "https://via.placeholder.com/80";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported,
                                size: 40, color: Colors.grey),
                          ),
                        ),
                        title: Text(
                          "${item.productName} x${item.quantity}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          item.status,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14),
                        ),
                        trailing: Text(
                          "\$${item.subTotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(thickness: 1),
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
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                _buildSummaryRow("Shipping Charge",
                    "\$${p!.shippingCharge.toStringAsFixed(2)}"),
                _buildSummaryRow(
                    "Tax (5%)", "\$${p!.tax.toStringAsFixed(2)}"),
                const SizedBox(height: 8),
                _buildSummaryRow(
                  "Order Total",
                  "\$${p!.orderTotal.toStringAsFixed(2)}",
                  bold: true,
                ),
              ],
            ),
          ),

          // 🔙 Nút quay lại trang chủ
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Home(),
                  ),
                      (route) => false);
            },
            style: TextButton.styleFrom(
              padding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
            ),
            child: const Text(
              "Back To Home",
              style: TextStyle(
                fontSize: 17,
                color: Colors.black,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(fontSize: 16, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(fontSize: 16, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
