import 'package:flutter/material.dart';
import 'package:shopsense_new/models/wishlist.dart';
import 'package:shopsense_new/repository/customer_repo.dart';
import 'package:shopsense_new/views/product_view.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late Future<List<Wishlist>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _wishlistFuture = fetchWishlist(); // ✅ JWT-only
  }

  void _reloadWishlist() {
    setState(() {
      _wishlistFuture = fetchWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách yêu thích'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder<List<Wishlist>>(
        future: _wishlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có sản phẩm nào trong danh sách yêu thích 😢',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final wishlistItems = snapshot.data!;

          return ListView.builder(
            itemCount: wishlistItems.length,
            itemBuilder: (context, index) {
              final item = wishlistItems[index];
              final imageUrl = item.thumbnailUrl.isNotEmpty
                  ? item.thumbnailUrl
                  : 'https://via.placeholder.com/150';

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductView(
                          productId: item.productId.toString(),
                        ),
                      ),
                    );
                  },
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Image.asset(
                          'assets/images/avatar-1.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  title: Text(
                    item.title.isNotEmpty ? item.title : 'No title',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${item.salePrice.toStringAsFixed(0)} VNĐ',
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: () async {
                      final success = await removeFromWishlist(item);
                      if (success) {
                        _reloadWishlist();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${item.title} đã bị xóa khỏi wishlist'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
