import 'package:flutter/material.dart';
import 'package:shopsense_new/models/product.dart';
import 'package:shopsense_new/models/wishlist.dart';
import 'package:shopsense_new/models/cart_item.dart';
import 'package:shopsense_new/repository/product_repo.dart';
import 'package:shopsense_new/repository/customer_repo.dart';
import 'package:shopsense_new/util/constants.dart';
import 'package:shopsense_new/views/cart_view.dart';
import 'package:shopsense_new/views/product_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Explore extends StatefulWidget {
  const Explore({super.key});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> with SingleTickerProviderStateMixin {
  final List<String> categories = ["Tất cả", "Đồng Hồ", "Điện Thoại", "Laptop"];
  String selectedCategory = "Tất Cả";

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Product> products = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _scrollController.addListener(_scrollListener);
    _fetchProducts(); // load lần đầu
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        hasMore) {
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts({bool reset = false}) async {
    if (isLoading) return;
    if (!hasMore && !reset) return;

    setState(() => isLoading = true);

    if (reset) {
      currentPage = 1;
      products.clear();
      hasMore = true;
    }

    try {
      final newProducts =
      await fetchProductsByCategory(selectedCategory, currentPage);
      if (!mounted) return;

      setState(() {
        if (newProducts.isEmpty) {
          hasMore = false;
        } else {
          products.addAll(newProducts);
          currentPage++;
        }
      });
    } catch (e) {
      debugPrint('Lỗi load sản phẩm: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _onCategorySelected(String category) {
    if (selectedCategory == category) return;
    setState(() {
      selectedCategory = category;
    });
    _fetchProducts(reset: true);
  }

  // ✅ HÀM TIỆN ÍCH ĐỂ CHUẨN HÓA VÀ TRẢ VỀ GIÁ TRỊ KIỂU INT
  int _parsePrice(String price) {
    if (price.isEmpty) return 0;

    // 1. Loại bỏ dấu phân cách hàng nghìn (giả sử là phẩy)
    String cleanedPrice = price.replaceAll(',', '');

    // 2. Chuyển sang double (để xử lý dấu thập phân, vd: "950.00" -> 950.0)
    double value = double.tryParse(cleanedPrice) ?? 0.0;

    // 3. Chuyển sang int, loại bỏ phần thập phân (vd: 950.0 -> 950)
    return value.toInt();
  }

  Future<void> _addToCart(Product product, int quantity) async {
    // Chúng ta vẫn cần unitPrice là double để tính toán subTotal chính xác,
    // trừ khi bạn chắc chắn không có xu/cent nào (giá luôn là số nguyên)
    // Nếu muốn unitPrice là double: final double unitPrice = _parseDoublePrice(product.salePrice);

    // Nếu bạn chắc chắn giá là số nguyên, dùng int:
    final int unitPriceInt = _parsePrice(product.salePrice);
    final double unitPrice = unitPriceInt.toDouble();


    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '0';
    final customerId = int.tryParse(userId) ?? 0;

    final cartItem = CartItem(
      id: 0,
      customerId: customerId,
      productId: product.id,
      sellerId: product.sellerId > 0 ? product.sellerId : 1,
      storeName: product.storeName,
      productName: product.title,
      productThumbnailUrl: product.thumbnailUrl,

      // ✅ Dùng giá trị double đã được làm sạch
      productUnitPrice: unitPrice,

      productQuantity: quantity,

      // ✅ SubTotal cũng dùng giá trị đã chuẩn hóa
      subTotal: unitPrice * quantity,
    );

    try {
      bool success = await customerAddToCart(cartItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? "✅ Thêm ${product.title} thành công vào giỏ hàng"
              : "❌ Thêm thất bại"),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Lỗi khi thêm sản phẩm: $e"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addToWishlist(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    int customerId = int.tryParse(userId ?? '0') ?? 0;

    // Sử dụng _parsePrice để lấy giá trị int
    final int salePriceInt = _parsePrice(product.salePrice);
    final double salePrice = salePriceInt.toDouble();

    Wishlist wishlist = Wishlist(
      customerId: customerId,
      productId: product.id,
      title: product.title,
      thumbnailUrl: product.thumbnailUrl,
      // ✅ Dùng giá trị đã được làm sạch và chuẩn hóa (double)
      salePrice: salePrice,
      stockStatus: product.stockStatus ?? 'In Stock',
    );

    bool success = await addToWishlist(wishlist);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
        Text(success ? "Đã thêm vào mục yêu thích" : "Đã có trong mục yêu thích"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // HEADER
          Container(
            decoration: const BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 3),
                  blurRadius: 6,
                ),
              ],
            ),
            padding:
            const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ShopSense",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.shopping_cart, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CartView()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm sản phẩm...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CATEGORIES
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () => _onCategorySelected(category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                            colors: [Colors.indigo, Colors.blueAccent])
                            : const LinearGradient(
                            colors: [Colors.white, Colors.white]),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.indigo),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.indigo,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // PRODUCTS
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: products.isEmpty && isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                onRefresh: () async => _fetchProducts(reset: true),
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 300,
                  ),
                  itemCount: products.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == products.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final product = products[index];

                    // ✅ Lấy giá trị số nguyên đã chuẩn hóa
                    final int salePriceValue =
                    _parsePrice(product.salePrice);
                    final int regularPriceValue =
                    _parsePrice(product.regularPrice);
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductView(
                                productId: product.id.toString()),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.network(
                                      product.thumbnailUrl.startsWith(
                                          'http')
                                          ? product.thumbnailUrl
                                          : "$baseUrl${product.thumbnailUrl}",
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, _) =>
                                      const Icon(Icons
                                          .image_not_supported),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: InkWell(
                                      onTap: () =>
                                          _addToWishlist(product),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withOpacity(0.9),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(5),
                                        child: const Icon(
                                          Icons.favorite_border,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                product.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  // ✅ Hiển thị Sale Price (kiểu int)
                                  Text(
                                    "${salePriceValue} VNĐ",
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  // ✅ Hiển thị Regular Price (kiểu int)
                                  Text(
                                    "${regularPriceValue} VNĐ",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                      decoration:
                                      TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 5),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _addToCart(product, 1),
                                  icon: const Icon(
                                      Icons.add_shopping_cart,
                                      size: 18),
                                  label: const Text("Thêm"),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}