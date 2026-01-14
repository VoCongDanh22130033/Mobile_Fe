import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopsense_new/models/customer.dart';
import 'package:shopsense_new/providers/auth_provider.dart';
import 'package:shopsense_new/repository/customer_repo.dart';
import 'package:shopsense_new/views/auth_view.dart';
import 'package:shopsense_new/views/orders_view.dart';
import 'package:shopsense_new/views/edit_profile_view.dart';
import 'package:shopsense_new/views/wishlist_view.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return ScaleTransition(
      scale: _fadeIn,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          splashColor: Colors.indigo.withOpacity(0.3),
          onTap: onTap,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade100, Colors.indigo.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.indigo.shade800),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Container(
      color: Colors.indigo,
      child: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: Colors.white, size: 80),
              const SizedBox(height: 20),
              const Text(
                "Bạn chưa đăng nhập ?",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text("Đăng Nhập"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 12),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthView()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text("Hồ Sơ"),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              FutureBuilder<Customer>(
                future: customerProfile(), // không truyền tham số
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text(
                      "Lỗir: ${snapshot.error}",
                      style: const TextStyle(fontSize: 18, color: Colors.red),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Text("Không tìm thấy dữ liệu hồ sơ");
                  }

                  final avatarUrl = snapshot.data!.img;

                  return Column(
                    children: [
                      if (avatarUrl != null && avatarUrl.isNotEmpty)
                        CircleAvatar(
                          radius: 70,
                          backgroundImage: NetworkImage(avatarUrl),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        snapshot.data!.name ?? "Unknown",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Consumer<AuthProvider>(
                builder: (context, auth, child) =>
                    ElevatedButton.icon(
                      onPressed: () {
                        auth.logout();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Đăng Xuất"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 25),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  " ",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1,
                  children: [
                    _buildActionCard(
                      "Đơn Hàng",
                      Icons.shopping_bag,
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (
                              context) => const OrdersView()),
                        );
                      },
                    ),
                    _buildActionCard(
                      "Chỉnh sửa ",
                      Icons.edit,
                          () async {
                        final profile = await customerProfile(); // không truyền tham số
                        final updatedUser = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfileView(currentUser: profile),
                          ),
                        );
                        if (updatedUser != null) setState(() {});
                      },
                    ),
                    _buildActionCard(
                      "Yêu thích",
                      Icons.favorite,
                          () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (
                              context) => const WishlistScreen()),
                        );
                      },
                    ),
                    _buildActionCard(
                      "Địa Chỉ",
                      Icons.location_on,
                          () {
                        debugPrint('Địa chỉ.');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (!auth.isLoggedIn) {
          return _buildNotLoggedInView();
        } else {
          return _buildProfileView();
        }
      },
    );
  }
}
