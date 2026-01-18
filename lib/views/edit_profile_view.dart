import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shopsense_new/models/customer.dart';
import 'package:shopsense_new/repository/customer_repo.dart';

class EditProfileView extends StatefulWidget {
  final Customer currentUser;
  const EditProfileView({super.key, required this.currentUser});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  File? _selectedImage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _addressController = TextEditingController(text: widget.currentUser.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --- HÀM CHỌN ẢNH (Bổ sung vì bị thiếu) ---
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _selectedImage = File(result.files.single.path!));
      }
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
    }
  }

  // --- HÀM CẬP NHẬT (Đã sửa logic hiển thị ngay lập tức) ---
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus(); // Ẩn bàn phím
    setState(() => isLoading = true);

    try {
      // 1. Tạo object Customer mới từ dữ liệu người dùng vừa nhập
      Customer updatedData = Customer(
        id: widget.currentUser.id,
        name: _nameController.text.trim(), // Lấy tên MỚI NHẤT từ ô nhập
        email: widget.currentUser.email,
        address: _addressController.text.trim(), // Lấy địa chỉ MỚI NHẤT
        role: widget.currentUser.role,
        status: widget.currentUser.status,
        // Nếu có chọn ảnh mới thì lấy đường dẫn file, nếu không thì giữ ảnh cũ
        img: _selectedImage != null ? _selectedImage!.path : widget.currentUser.img,
        emailVerified: widget.currentUser.emailVerified,
      );

      // 2. Gọi API để lưu lên Server
      final bool success = await customerUpdateProfile(updatedData);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thành công! ✨"), backgroundColor: Colors.green),
        );

        // 3. QUAN TRỌNG: Trả về object 'updatedData' vừa tạo
        // Màn hình Profile sẽ nhận object này và hiển thị ngay lập tức
        // KHÔNG gọi lại customerProfile() để tránh độ trễ server
        Navigator.pop(context, updatedData);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thất bại."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint("Update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Chỉnh sửa thông tin"),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar Picker
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          // Logic hiển thị ảnh preview
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!) // Ưu tiên ảnh vừa chọn từ máy
                              : (widget.currentUser.img != null && widget.currentUser.img!.startsWith('http'))
                              ? NetworkImage(widget.currentUser.img!) as ImageProvider // Ảnh cũ từ server
                              : null,
                          child: (_selectedImage == null && (widget.currentUser.img == null || !widget.currentUser.img!.startsWith('http')))
                              ? const Icon(Icons.person, size: 60, color: Colors.indigo)
                              : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Form Fields
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Họ và tên",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.trim().isEmpty ? "Không được để trống" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: "Địa chỉ",
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.trim().isEmpty ? "Không được để trống" : null,
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("LƯU THAY ĐỔI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay loading
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}