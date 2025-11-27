import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsense_new/models/cart_item.dart';
import 'package:shopsense_new/models/product.dart';
import 'package:shopsense_new/models/wishlist.dart';
import 'package:shopsense_new/repository/customer_repo.dart';
import 'package:shopsense_new/repository/product_repo.dart';
import 'package:shopsense_new/util/constants.dart';

class ProductView extends StatefulWidget {
  final String productId;

  const ProductView({super.key, required this.productId});

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  Product? product;
  int quantity = 1;
  double subTotal = 0;
  int rating = 5;
  final TextEditingController _commentController = TextEditingController();

  // Đã sửa: Loại bỏ decimalDigits: 2 để hiển thị số nguyên
  final currencyFormatter = NumberFormat.currency(symbol: "\$", decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    getProduct();
  }

  // Hàm tiện ích để làm sạch và chuyển đổi giá tiền
  double _parsePrice(String? price) {
    if (price == null || price.isEmpty) return 0.0;

    // Loại bỏ dấu phân cách hàng nghìn (',' và '.') để tránh lỗi Parse
    String cleanedPrice = price.replaceAll(',', '').replaceAll('.', '');

    // Chuyển đổi thành double an toàn
    return double.tryParse(cleanedPrice) ?? 0.0;
  }

  // Hàm lấy giá bán (ưu tiên giá giảm)
  double _getSellingPrice() {
    // Luôn ưu tiên giá giảm (salePrice) khi tính toán tổng tiền
    if (product == null) return 0.0;
    return _parsePrice(product!.salePrice);
  }

  void getProduct() async {
    product = await fetchProduct(widget.productId);
    setState(() {
      // ✅ SỬA: Tính subTotal ban đầu dựa trên giá giảm
      subTotal = _getSellingPrice();
    });
  }

  void incrementQuantity() {
    setState(() {
      quantity++;
      // ✅ SỬA: Tính tổng dựa trên giá giảm
      subTotal = _getSellingPrice() * quantity;
    });
  }

  void decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
        // ✅ SỬA: Tính tổng dựa trên giá giảm
        subTotal = _getSellingPrice() * quantity;
      });
    }
  }

  void addToCart() async {
    // Dùng _getSellingPrice() để đảm bảo giá đơn vị nhất quán
    final unitPrice = _getSellingPrice();

    CartItem c = CartItem(
      id: 0,
      customerId: 0,
      productId: product!.id,
      sellerId: product!.sellerId,
      storeName: product!.storeName,
      productName: product!.title,
      productThumbnailUrl: product!.thumbnailUrl,
      productUnitPrice: unitPrice, // Giá đã giảm
      productQuantity: quantity,
      subTotal: subTotal, // subTotal đã được tính đúng ở trên
    );

    await customerAddToCart(c)
        ? showMessage("✅ Added to cart")
        : showMessage("❌ Something went wrong");
  }

  // ✅ HÀM SUBMIT REVIEW ĐÃ KHÔI PHỤC
  void submitReview() {
    if (_commentController.text.isEmpty) {
      showMessage("Please write a comment!");
      return;
    }
    showMessage("⭐ You rated $rating stars and commented: ${_commentController.text}");
    _commentController.clear();
    setState(() {
      rating = 5;
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text("Product Details"),
      ),
      body: FutureBuilder<Product>(
        future: fetchProduct(widget.productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("No product found"));
          }

          final product = snapshot.data!;

          // Tính toán giá tiền hiển thị an toàn
          final salePrice = _parsePrice(product.salePrice);
          final regularPrice = _parsePrice(product.regularPrice);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh sản phẩm
                Container(
                  height: 250,
                  width: double.infinity,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.grey[100],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    product.thumbnailUrl.startsWith('http')
                        ? product.thumbnailUrl
                        : '$baseUrl/${product.thumbnailUrl}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                  ),
                ),

                // Tiêu đề và giá
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Dùng giá trị double đã chuẩn hóa (Sale Price)
                          Text(
                            currencyFormatter.format(salePrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                              color: Colors.green,
                            ),
                          ),
                          // Dùng giá trị double đã chuẩn hóa (Regular Price)
                          Text(
                            currencyFormatter.format(regularPrice),
                            style: const TextStyle(
                              color: Colors.red,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Đánh giá giả lập
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const Icon(Icons.star_half, color: Colors.amber, size: 20),
                      const Icon(Icons.star_border, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      const Text(
                        "(24 reviews)",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // Mô tả
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    product.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),

                // Số lượng & tổng tiền
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: decrementQuantity,
                              ),
                              Text(
                                quantity.toString(),
                                style: const TextStyle(fontSize: 20.0),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: incrementQuantity,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              textAlign: TextAlign.center,
                              // subTotal đã được tính theo giá giảm
                              currencyFormatter.format(subTotal),
                              style: const TextStyle(
                                  fontSize: 20.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(thickness: 1),

                // ✅ KHÔI PHỤC: Review Section
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Write a Review",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () {
                              setState(() {
                                rating = index + 1;
                              });
                            },
                            icon: Icon(
                              Icons.star,
                              color: index < rating ? Colors.amber : Colors.grey,
                            ),
                          );
                        }),
                      ),
                      TextField(
                        controller: _commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Write your comment here...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                          ),
                          onPressed: submitReview,
                          icon: const Icon(Icons.send, color: Colors.white),
                          label: const Text(
                            "Submit Review",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Nút yêu thích & giỏ hàng
                Container(
                  color: Colors.indigo,
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white),
                        iconSize: 35,
                        onPressed: () async {
                          if (product == null) return;

                          // Dùng _getSellingPrice() để chuẩn hóa giá trị salePrice
                          final wishlistSalePrice = _getSellingPrice();

                          final prefs = await SharedPreferences.getInstance();
                          String? userId = prefs.getString('userId');
                          int customerId = int.tryParse(userId ?? '0') ?? 0;

                          Wishlist wishlist = Wishlist(
                            customerId: customerId,
                            productId: int.parse(widget.productId),
                            title: product.title,
                            thumbnailUrl: product.thumbnailUrl,
                            salePrice: wishlistSalePrice,
                            stockStatus: product.stockStatus ?? 'In Stock',
                          );

                          try {
                            bool success = await addToWishlist(wishlist);
                            if (success) {
                              showMessage("❤️ Added to favorites");
                            } else {
                              showMessage("⚠️ Already in favorites");
                            }
                          } catch (e) {
                            showMessage("❌ Failed to add to favorites");
                          }
                        },
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                        ),
                        onPressed: addToCart,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_shopping_cart, color: Colors.white),
                            SizedBox(width: 8.0),
                            Text(
                              'Add to Cart',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}