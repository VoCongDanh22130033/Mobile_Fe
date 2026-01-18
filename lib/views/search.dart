import 'package:flutter/material.dart';
import 'package:shopsense_new/models/product.dart';
import 'package:shopsense_new/repository/product_repo.dart';
import 'package:shopsense_new/util/constants.dart';
import 'package:shopsense_new/views/product_view.dart';
import 'package:shopsense_new/widgets/product_card.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = "";

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = "";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      // Giả sử fetchProducts() trả về toàn bộ danh sách sản phẩm
      final products = await fetchProducts();
      final results = products
          .where((p) =>
          p.title.toLowerCase().contains(query.toLowerCase().trim()))
          .toList();

      setState(() {
        _searchResults = results;
        _isLoading = false;
        if (results.isEmpty) {
          _errorMessage = "Không tìm thấy sản phẩm nào.";
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Lỗi khi tải dữ liệu: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text("Tìm kiếm sản phẩm"),
      ),
      body: Column(
        children: [
          // Ô tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchProducts,
              decoration: InputDecoration(
                hintText: "Nhập tên sản phẩm...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Nội dung hiển thị kết quả
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 18),
              ),
            )
                : _searchResults.isEmpty
                ? const Center(
              child: Text(
                "Hãy nhập từ khóa để tìm sản phẩm.",
                style:
                TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                mainAxisExtent: 330,
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final product = _searchResults[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductView(
                          productId: product.id.toString(),
                        ),
                      ),
                    );
                  },
                  child: ProductCard(
                    title: product.title,
                    price: double.parse(product.regularPrice),
                    salePrice: double.parse(product.salePrice),
                    thumbnailUrl: product.thumbnailUrl
                        .startsWith('http')
                        ? product.thumbnailUrl
                        : "${ApiConfig.baseUrl}${product.thumbnailUrl.startsWith('/') ? product.thumbnailUrl : '/${product.thumbnailUrl}'}",
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
