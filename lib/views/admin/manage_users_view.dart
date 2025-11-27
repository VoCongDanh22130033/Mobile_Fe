import 'package:flutter/material.dart';

class ManageUsersView extends StatelessWidget {
  const ManageUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final users = [
      {'name': 'Nguyễn Văn A', 'email': 'a@gmail.com', 'role': 'User'},
      {'name': 'Trần Thị B', 'email': 'b@gmail.com', 'role': 'Admin'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý người dùng')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(user['name']!),
              subtitle: Text(user['email']!),
              trailing: Text(user['role']!,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                // TODO: mở chi tiết người dùng
              },
            ),
          );
        },
      ),
    );
  }
}
