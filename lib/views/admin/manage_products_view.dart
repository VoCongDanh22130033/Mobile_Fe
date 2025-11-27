import 'package:flutter/material.dart';

class ManageProductsView extends StatelessWidget {
  const ManageProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final products = [
      {'name': 'Tai nghe Bluetooth', 'price': '450,000đ'},
      {'name': 'Chuột gaming', 'price': '520,000đ'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý sản phẩm')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: thêm sản phẩm
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(p['name']!),
              subtitle: Text('Giá: ${p['price']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      // TODO: sửa sản phẩm
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // TODO: xóa sản phẩm
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
