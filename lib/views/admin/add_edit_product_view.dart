import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shopsense_new/models/product.dart';
import 'package:shopsense_new/repository/admin_product_repo.dart';
import 'package:shopsense_new/repository/file_repo.dart';
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
  late TextEditingController priceCtrl;
  File? _selectedImage;
  String? _imageUrl; // URL của ảnh đã upload hoặc ảnh hiện tại
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.product?.title ?? "");
    priceCtrl = TextEditingController(text: widget.product?.regularPrice ?? "");
    // Nếu đang sửa, lấy URL ảnh hiện tại
    if (widget.product != null && widget.product!.thumbnailUrl.isNotEmpty) {
      _imageUrl = widget.product!.thumbnailUrl;
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
          _imageUrl = null; // Reset URL khi chọn ảnh mới
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi chọn ảnh: $e")),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final uploadedUrl = await uploadFile(_selectedImage!);
      if (uploadedUrl != null) {
        setState(() {
          _imageUrl = uploadedUrl;
          _isUploading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Upload ảnh thành công!")),
          );
        }
      } else {
        setState(() {
          _isUploading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Upload ảnh thất bại!")),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi upload: $e")),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Nếu có ảnh mới chọn nhưng chưa upload, upload trước
    if (_selectedImage != null && _imageUrl == null) {
      await _uploadImage();
      if (_imageUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vui lòng upload ảnh trước khi lưu!")),
          );
        }
        return;
      }
    }

    // Nếu không có ảnh mới và không có URL, dùng URL cũ hoặc rỗng
    String thumbnailUrl = _imageUrl ?? widget.product?.thumbnailUrl ?? "";

    final product = Product(
      id: widget.product?.id ?? 0,
      title: titleCtrl.text,
      regularPrice: priceCtrl.text,
      salePrice: priceCtrl.text,
      thumbnailUrl: thumbnailUrl,
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

    if (ok && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lưu sản phẩm thất bại!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? "Thêm sản phẩm" : "Sửa sản phẩm")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Ảnh sản phẩm
              const SizedBox(height: 10),
              const Text(
                "Ảnh sản phẩm",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            )
                          : _imageUrl != null && _imageUrl!.isNotEmpty
                              ? Image.network(
                                  getImageUrl(_imageUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.broken_image, size: 50),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, size: 50),
                                      SizedBox(height: 8),
                                      Text("Chọn ảnh sản phẩm"),
                                    ],
                                  ),
                                ),
                ),
              ),
              const SizedBox(height: 10),
              if (_selectedImage != null && _imageUrl == null)
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadImage,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isUploading ? "Đang upload..." : "Upload ảnh"),
                ),
              const SizedBox(height: 20),
              // Tên sản phẩm
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Tên sản phẩm"),
                validator: (v) => v!.isEmpty ? "Không được để trống" : null,
              ),
              const SizedBox(height: 16),
              // Giá
              TextFormField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: "Giá"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Không được để trống" : null,
              ),
              const SizedBox(height: 30),
              // Nút lưu
              ElevatedButton(
                onPressed: _isUploading ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Lưu"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
