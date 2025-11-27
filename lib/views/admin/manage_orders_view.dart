import 'package:flutter/material.dart';

class ManageOrdersView extends StatelessWidget {
  const ManageOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      {'id': 'ORD001', 'status': 'Đang xử lý', 'total': '1.200.000đ'},
      {'id': 'ORD002', 'status': 'Đã giao', 'total': '650.000đ'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý đơn hàng')),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('Mã đơn: ${order['id']}'),
              subtitle: Text('Tổng tiền: ${order['total']}'),
              trailing: Text(order['status']!,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                // TODO: xem chi tiết đơn hàng
              },
            ),
          );
        },
      ),
    );
  }
}
