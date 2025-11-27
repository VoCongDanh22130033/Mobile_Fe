import 'package:flutter/material.dart';
import 'package:shopsense_new/views/admin/manage_users_view.dart';
import 'package:shopsense_new/views/admin/manage_products_view.dart';
import 'package:shopsense_new/views/admin/manage_orders_view.dart';
import 'package:shopsense_new/views/auth_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_AdminMenuItem> menuItems = [
      _AdminMenuItem(
        title: 'Quản lý người dùng',
        icon: Icons.people,
        color: Colors.blue,
        route: const ManageUsersView(),
      ),
      _AdminMenuItem(
        title: 'Quản lý sản phẩm',
        icon: Icons.shopping_bag,
        color: Colors.green,
        route: const ManageProductsView(),
      ),
      _AdminMenuItem(
        title: 'Quản lý đơn hàng',
        icon: Icons.receipt_long,
        color: Colors.orange,
        route: const ManageOrdersView(),
      ),
    ];

    // Dùng WillPopScope để chặn back button
    return WillPopScope(
      onWillPop: () async => false, // trả về false => chặn back
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trang Quản Trị'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                // Xóa token / dữ liệu lưu
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                // Quay về trang login và xóa toàn bộ history
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthView()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
        body: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: menuItems.map((item) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item.route),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: item.color.withOpacity(0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: item.color, size: 50),
                    const SizedBox(height: 12),
                    Text(item.title,
                        style: TextStyle(
                            color: item.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AdminMenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget route;

  _AdminMenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}
