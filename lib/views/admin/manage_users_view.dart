import 'package:flutter/material.dart';
import 'package:shopsense_new/models/customer.dart';
import 'package:shopsense_new/repository/admin_customer_repo.dart';
import 'add_edit_user_view.dart';

class ManageUsersView extends StatefulWidget {
  const ManageUsersView({super.key});

  @override
  State<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<ManageUsersView> {
  late Future<List<Customer>> future;

  @override
  void initState() {
    super.initState();
    future = adminFetchUsers();
  }

  void _reload() {
    setState(() {
      future = adminFetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý người dùng")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final r = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditUserView()),
          );
          if (r == true) _reload();
        },
      ),
      body: FutureBuilder<List<Customer>>(
        future: future,
        builder: (c, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) return Center(child: Text(s.error.toString()));

          final users = s.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (c, i) {
              final u = users[i];
              return ListTile(
                title: Text(u.name),
                subtitle: Text(u.email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(u.role,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: u.role == "ADMIN"
                                ? Colors.red
                                : Colors.green)),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final r = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddEditUserView(user: u)),
                        );
                        if (r == true) _reload();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await adminDeleteUser(u.id);
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
