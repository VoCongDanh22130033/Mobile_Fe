import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopsense_new/models/customer.dart';
import 'package:shopsense_new/providers/auth_provider.dart';
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
    // Khởi tạo controller với dữ liệu hiện tại
    _nameController = TextEditingController(text: widget.currentUser.name);
    _addressController = TextEditingController(text: widget.currentUser.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Chọn ảnh từ thiết bị
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
      _showError("Không thể mở trình chọn ảnh: $e");
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // 1. Chuẩn bị dữ liệu cập nhật
      Customer updatedData = Customer(
        id: widget.currentUser.id,
        name: _nameController.text.trim(),
        email: widget.currentUser.email,
        address: _addressController.text.trim(),
        role: widget.currentUser.role,
        status: widget.currentUser.status,
        // Lưu ý: Nếu có server upload ảnh, bạn nên gọi API upload trước rồi lấy URL gán vào đây
        img: _selectedImage != null ? _selectedImage!.path : widget.currentUser.img,
        emailVerified: widget.currentUser.emailVerified,
      );

      // 2. Gọi API cập nhật
      final bool success = await customerUpdateProfile(updatedData);

      if (!mounted) return;

      if (success) {
        // Lấy lại dữ liệu "tươi" nhất từ Server để đảm bảo đồng bộ
        // Điều này tránh việc dữ liệu local và server khác nhau
        final freshCustomer = await customerProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cập nhật thành công! ✨"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // TRẢ VỀ ĐỐI TƯỢNG MỚI: Giúp màn hình Profile cập nhật ngay lập tức
          Navigator.pop(context, freshCustomer);
        }
      } else {
        _showError("Cập nhật thất bại. Vui lòng kiểm tra lại kết nối.");
      }
    } catch (e) {
      // Log lỗi chi tiết để debug nếu gặp FormatException (lỗi HTML từ Ngrok)
      debugPrint("❌ Error during update: $e");
      _showError("Lỗi hệ thống: Vui lòng thử lại sau.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chỉnh sửa cá nhân", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Nền trang trí indigo phía trên
          Container(height: 120, color: Colors.indigo),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 30),
                  _buildAvatarHeader(),
                  const SizedBox(height: 40),
                  _buildCardForm(),
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
          // Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarHeader() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.indigo.shade50,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : (widget.currentUser.img != null && widget.currentUser.img!.isNotEmpty)
                    ? NetworkImage(widget.currentUser.img!) as ImageProvider
                    : null,
                child: (_selectedImage == null && (widget.currentUser.img == null || widget.currentUser.img!.isEmpty))
                    ? const Icon(Icons.person, size: 60, color: Colors.indigo)
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: CircleAvatar(
                backgroundColor: Colors.indigo,
                radius: 18,
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Họ và tên",
                prefixIcon: const Icon(Icons.person_outline, color: Colors.indigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
              ),
              validator: (v) => v!.trim().isEmpty ? "Vui lòng nhập họ tên" : null,
            ),
            const SizedBox(height: 25),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Địa chỉ",
                prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.indigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
              ),
              validator: (v) => v!.trim().isEmpty ? "Vui lòng nhập địa chỉ" : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : _updateProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
      ),
      child: const Text(
        "LƯU THAY ĐỔI",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }
}