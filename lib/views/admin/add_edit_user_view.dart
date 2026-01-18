import 'package:flutter/material.dart';
import 'package:shopsense_new/models/customer.dart';
import 'package:shopsense_new/repository/admin_customer_repo.dart';

class AddEditUserView extends StatefulWidget {
  final Customer? user;
  const AddEditUserView({super.key, this.user});

  @override
  State<AddEditUserView> createState() => _AddEditUserViewState();
}

class _AddEditUserViewState extends State<AddEditUserView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController passwordCtrl;
  String role = "CUSTOMER";

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.user?.name ?? "");
    emailCtrl = TextEditingController(text: widget.user?.email ?? "");
    passwordCtrl = TextEditingController();
    role = widget.user?.role ?? "CUSTOMER";
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Customer(
      id: widget.user?.id ?? 0,
      name: nameCtrl.text,
      email: emailCtrl.text,
      password: passwordCtrl.text.isEmpty ? null : passwordCtrl.text,
      address: "",
      emailVerified: true,
      role: role,
    );

    final ok = widget.user == null
        ? await adminAddUser(user)
        : await adminUpdateUser(user);

    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.user == null ? "Thêm người dùng" : "Sửa người dùng")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Tên"),
              validator: (v) => v!.isEmpty ? "Không được để trống" : null,
            ),
            TextFormField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
              validator: (v) => v!.isEmpty ? "Không được để trống" : null,
            ),
            if (widget.user == null)
              TextFormField(
                controller: passwordCtrl,
                decoration: const InputDecoration(labelText: "Mật khẩu"),
                obscureText: true,
              ),
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: "CUSTOMER", child: Text("CUSTOMER")),
                DropdownMenuItem(value: "ADMIN", child: Text("ADMIN")),
              ],
              onChanged: (v) => setState(() => role = v!),
              decoration: const InputDecoration(labelText: "Vai trò"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text("Lưu"))
          ]),
        ),
      ),
    );
  }
}
