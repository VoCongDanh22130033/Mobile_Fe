import 'package:flutter/material.dart';
import 'package:shopsense_new/models/product.dart';
import 'package:shopsense_new/repository/admin_product_repo.dart';

class AddEditProductView extends StatefulWidget {
  final Product? product;
  const AddEditProductView({super.key, this.product});

  @override
  State<AddEditProductView> createState() => _AddEditProductViewState();
}

class _AddEditProductViewState extends State<AddEditProductView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleCtrl;
  late TextEditingController priceCtrl;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.product?.title ?? "");
    priceCtrl = TextEditingController(text: widget.product?.regularPrice ?? "");
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: widget.product?.id ?? 0,
      title: titleCtrl.text,
      regularPrice: priceCtrl.text,
      salePrice: priceCtrl.text,
      thumbnailUrl: "",
      description: "",
      category: "Phone",
      stockStatus: "IN_STOCK",
      stockCount: "10",
      sellerId: 1,
      storeName: "Admin Store",
      status: "ACTIVE",
    );

    final ok = widget.product == null
        ? await adminAddProduct(product)
        : await adminUpdateProduct(product);

    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? "Thêm sản phẩm" : "Sửa sản phẩm")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Tên sản phẩm"),
              validator: (v) => v!.isEmpty ? "Không được để trống" : null,
            ),
            TextFormField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: "Giá"),
              validator: (v) => v!.isEmpty ? "Không được để trống" : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text("Lưu"))
          ]),
        ),
      ),
    );
  }
}
