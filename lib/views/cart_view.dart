import 'package:flutter/material.dart';
import 'package:shopsense_new/models/cart_item.dart';
import 'package:shopsense_new/views/checkout_view.dart';
import 'package:shopsense_new/repository/customer_repo.dart';
import 'package:shopsense_new/util/constants.dart';
import 'dart:math'; // ✅ Cần import thư viện math cho hàm pow

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  late Future<List<CartItem>> _cartFuture;

  @override
  void initState() {
    super.initState();
    _cartFuture = customerCart(); // Load giỏ hàng khi mở trang
  }

  void refreshCart() {
    setState(() {
      _cartFuture = customerCart();
    });
  }

  // =========================================================
  // ✅ HÀM TIỆN ÍCH LÀM TRÒN SỐ (Đảm bảo độ chính xác 2 số thập phân)
  // =========================================================
  double roundDouble(double value, int places) {
    num mod = pow(10.0, places);
    return ((value * mod).round().toDouble() / mod);
  }

  // =========================================================
  // ✅ HÀM TIỆN ÍCH ĐỊNH DẠNG TIỀN TỆ (Loại bỏ .00 nếu là số nguyên)
  // =========================================================
  String formatCurrency(double value) {
    // Kiểm tra xem giá trị có phần thập phân bằng 0 không
    if (value == value.toInt().toDouble()) {
      // Nếu là số nguyên (ví dụ: 100.0), chỉ hiển thị số nguyên
      return '\$${value.toInt()}';
    } else {
      // Nếu có phần thập phân (ví dụ: 100.55), hiển thị 2 chữ số thập phân
      return '\$${value.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text("My Cart"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 📦 Danh sách sản phẩm
          Expanded(
            child: FutureBuilder<List<CartItem>>(
              future: _cartFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final cartItems = snapshot.data ?? [];

                if (cartItems.isEmpty) {
                  return const Center(
                    child: Text(
                      "🛒 Your cart is empty",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Danh sách sản phẩm trong giỏ
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            // 🖼️ Hình ảnh sản phẩm
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.productThumbnailUrl != null
                                    ? (item.productThumbnailUrl!.startsWith('http')
                                    ? item.productThumbnailUrl!
                                    : '$baseUrl/${item.productThumbnailUrl}')
                                    : 'https://via.placeholder.com/80',
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported,
                                    size: 50, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 🏷️ Thông tin sản phẩm
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName ?? "Unknown Product",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.storeName ?? "Unknown Store",
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    // ✅ SỬ DỤNG formatCurrency
                                    formatCurrency(item.productUnitPrice),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green),
                                  ),
                                ],
                              ),
                            ),

                            // 🔘 Các nút tăng giảm, xóa
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Hàng điều chỉnh số lượng
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.grey),
                                      onPressed: () async {
                                        if (item.productQuantity > 1) {
                                          setState(() {
                                            item.productQuantity--;
                                            // ✅ ÁP DỤNG roundDouble
                                            item.subTotal = roundDouble(
                                                item.productQuantity *
                                                    item.productUnitPrice,
                                                2);
                                          });
                                          await customerUpdateCart(item);
                                        }
                                      },
                                    ),
                                    Text(
                                      "${item.productQuantity}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    IconButton(
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.grey),
                                      onPressed: () async {
                                        setState(() {
                                          item.productQuantity++;
                                          // ✅ ÁP DỤNG roundDouble
                                          item.subTotal = roundDouble(
                                              item.productQuantity *
                                                  item.productUnitPrice,
                                              2);
                                        });
                                        await customerUpdateCart(item);
                                      },
                                    ),
                                  ],
                                ),
                                // Nút xóa
                                IconButton(
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () async {
                                    final success =
                                    await customerRemoveCart(item.id!);
                                    if (success) refreshCart();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 💳 Thanh Checkout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 70,
            color: Colors.indigo,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.shopify, color: Colors.white),
                  label: const Text(
                    'Checkout',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckoutView(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}