import 'package:flutter/material.dart';
import 'package:shopsense_new/models/product.dart';
import 'package:shopsense_new/repository/admin_product_repo.dart';
import 'add_edit_product_view.dart';

class ManageProductsView extends StatefulWidget {
  const ManageProductsView({super.key});

  @override
  State<ManageProductsView> createState() => _ManageProductsViewState();
}

class _ManageProductsViewState extends State<ManageProductsView> {
  late Future<List<Product>> future;

  @override
  void initState() {
    super.initState();
    future = adminFetchProducts();
  }

  void _reload() {
    setState(() {
      future = adminFetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý sản phẩm")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final r = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditProductView()),
          );
          if (r == true) _reload();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Product>>(
        future: future,
        builder: (c, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) return Center(child: Text(s.error.toString()));

          final products = s.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (c, i) {
              final p = products[i];
              return ListTile(
                title: Text(p.title),
                subtitle: Text("Giá: ${p.regularPrice}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final r = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditProductView(product: p),
                          ),
                        );
                        if (r == true) _reload();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await adminDeleteProduct(p.id);
                        _reload();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
