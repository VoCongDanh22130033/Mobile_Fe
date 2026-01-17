import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shopsense_new/models/product.dart';
import 'package:shopsense_new/repository/admin_product_repo.dart';
import 'package:shopsense_new/util/constants.dart';

class AddEditProductView extends StatefulWidget {
  final Product? product;
  const AddEditProductView({super.key, this.product});

  @override
  State<AddEditProductView> createState() => _AddEditProductViewState();
}

class _AddEditProductViewState extends State<AddEditProductView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController regularPriceCtrl;
  late TextEditingController salePriceCtrl;
  late TextEditingController stockCountCtrl;
  
  String selectedCategory = "Phone";
  String selectedStockStatus = "IN_STOCK";
  String selectedStatus = "ACTIVE";
  File? _selectedImage;
  String? _imageUrl;
  bool _isUploading = false;

  final List<String> categories = ["Phone", "Laptop", "Watch", "Tablet", "Other"];
  final List<String> stockStatuses = ["IN_STOCK", "OUT_OF_STOCK", "LOW_STOCK"];
  final List<String> statuses = ["ACTIVE", "INACTIVE", "PENDING"];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    titleCtrl = TextEditingController(text: p?.title ?? "");
    descriptionCtrl = TextEditingController(text: p?.description ?? "");
    regularPriceCtrl = TextEditingController(text: p?.regularPrice ?? "");
    salePriceCtrl = TextEditingController(text: p?.salePrice ?? p?.regularPrice ?? "");
    stockCountCtrl = TextEditingController(text: p?.stockCount ?? "10");
    
    if (p != null) {
      selectedCategory = p.category.isNotEmpty ? p.category : "Phone";
      selectedStockStatus = p.stockStatus.isNotEmpty ? p.stockStatus : "IN_STOCK";
      selectedStatus = p.status.isNotEmpty ? p.status : "ACTIVE";
      _imageUrl = p.thumbnailUrl.isNotEmpty ? p.thumbnailUrl : null;
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
        _imageUrl = null; // Clear old URL when new image is selected
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    String? thumbnailUrl = _imageUrl; // Use existing URL if no new image

    // Upload new image if selected
    if (_selectedImage != null) {
      thumbnailUrl = await uploadImage(_selectedImage!);
      if (thumbnailUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi upload ảnh")),
          );
          setState(() => _isUploading = false);
        }
        return;
      }
    }

    final product = Product(
      id: widget.product?.id ?? 0,
      title: titleCtrl.text,
      regularPrice: regularPriceCtrl.text,
      salePrice: salePriceCtrl.text.isEmpty ? regularPriceCtrl.text : salePriceCtrl.text,
      thumbnailUrl: thumbnailUrl ?? "",
      description: descriptionCtrl.text,
      category: selectedCategory,
      stockStatus: selectedStockStatus,
      stockCount: stockCountCtrl.text,
      sellerId: 1,
      storeName: "Admin Store",
      status: selectedStatus,
    );

    final ok = widget.product == null
        ? await adminAddProduct(product)
        : await adminUpdateProduct(product);

    if (mounted) {
      setState(() => _isUploading = false);
      if (ok) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi lưu sản phẩm")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? "Thêm sản phẩm" : "Sửa sản phẩm")),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            : _imageUrl != null && _imageUrl!.isNotEmpty
                                ? Image.network(getImageUrl(_imageUrl), fit: BoxFit.cover)
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text("Chọn ảnh sản phẩm"),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: "Tên sản phẩm *"),
                      validator: (v) => v!.isEmpty ? "Không được để trống" : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: descriptionCtrl,
                      decoration: const InputDecoration(labelText: "Mô tả"),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    // Category
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: "Danh mục"),
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (v) => setState(() => selectedCategory = v!),
                    ),
                    const SizedBox(height: 16),
                    
                    // Regular Price
                    TextFormField(
                      controller: regularPriceCtrl,
                      decoration: const InputDecoration(labelText: "Giá gốc *"),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Không được để trống" : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Sale Price
                    TextFormField(
                      controller: salePriceCtrl,
                      decoration: const InputDecoration(labelText: "Giá khuyến mãi"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    
                    // Stock Count
                    TextFormField(
                      controller: stockCountCtrl,
                      decoration: const InputDecoration(labelText: "Số lượng tồn kho"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    
                    // Stock Status
                    DropdownButtonFormField<String>(
                      value: selectedStockStatus,
                      decoration: const InputDecoration(labelText: "Trạng thái tồn kho"),
                      items: stockStatuses.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                      onChanged: (v) => setState(() => selectedStockStatus = v!),
                    ),
                    const SizedBox(height: 16),
                    
                    // Status
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: "Trạng thái"),
                      items: statuses.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                      onChanged: (v) => setState(() => selectedStatus = v!),
                    ),
                    const SizedBox(height: 24),
                    
                    // Save Button
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text("Lưu"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
