import 'dart:io';
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
  Future<Customer>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Tự động tải profile khi vào trang
    _refreshProfile();
  }

  void _refreshProfile({Customer? updatedData}) {
    if (mounted) {
      setState(() {
        if (updatedData != null) {
          // Nếu có data mới từ trang Edit trả về -> Dùng luôn (hiển thị ngay lập tức)
          _profileFuture = Future.value(updatedData);
        } else {
          // Nếu không -> Gọi API tải lại từ đầu
          final auth = Provider.of<AuthProvider>(context, listen: false);
          if (auth.userId.isNotEmpty) {
            _profileFuture = customerProfile();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- VIEW 1: CHƯA ĐĂNG NHẬP ---
  Widget _buildNotLoggedInView() {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.person_off_rounded, color: Colors.white, size: 80),
              ),
              const SizedBox(height: 20),
              const Text("Chào bạn!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const Text("Đăng nhập để xem hồ sơ của bạn", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthView())
                ).then((_) => _refreshProfile()),
                child: const Text("ĐĂNG NHẬP NGAY", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- VIEW 2: ĐÃ ĐĂNG NHẬP (PROFILE CHÍNH) ---
  Widget _buildProfileView() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        title: const Text("Tài khoản", style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshProfile(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshProfile(),
        color: Colors.indigo,
        child: FutureBuilder<Customer>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.indigo));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Lỗi kết nối: ${snapshot.error}"));
            }
            if (!snapshot.hasData) return const SizedBox.shrink();

            final user = snapshot.data!;
            return _buildMainContent(user);
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(Customer user) {

    // Hàm hỗ trợ lấy ảnh (URL mạng hoặc File máy)
    ImageProvider? getAvatarImage() {
      if (user.img == null || user.img!.isEmpty) return null;

      if (user.img!.startsWith('http')) {
        // Trường hợp 1: Ảnh từ Server
        return NetworkImage("${user.img}?t=${DateTime.now().millisecondsSinceEpoch}");
      } else {
        // Trường hợp 2: Ảnh cục bộ vừa cập nhật (không có http)
        return FileImage(File(user.img!));
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                ),
              ),
              Positioned(
                bottom: -50,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    // SỬ DỤNG HÀM XỬ LÝ ẢNH MỚI
                    backgroundImage: getAvatarImage(),
                    child: (user.img == null || user.img!.isEmpty)
                        ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
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
          const SizedBox(height: 60),

          Text(
            user.name ?? "Người dùng",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(user.email ?? "", style: TextStyle(color: Colors.grey[600])),

          const SizedBox(height: 30),

          // Grid Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard("Đơn Hàng", Icons.local_shipping_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersView()));
                }),

                // NÚT CHỈNH SỬA
                _buildActionCard("Chỉnh Sửa", Icons.manage_accounts_outlined, () async {
                  // Chuyển sang màn hình Edit và CHỜ kết quả trả về
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfileView(currentUser: user))
                  );

                  // Nếu màn hình Edit trả về một Customer object -> Cập nhật ngay
                  if (result != null && result is Customer) {
                    _refreshProfile(updatedData: result);
                  }
                }),

                _buildActionCard("Yêu Thích", Icons.favorite_border_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistScreen()));
                }),
                _buildActionCard("Địa Chỉ", Icons.location_on_outlined, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng đang phát triển")));
                }),
              ],
            ),
          ),

          const SizedBox(height: 40),
          _buildLogoutButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.indigo, size: 28),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: TextButton.icon(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Đăng xuất?"),
                    content: const Text("Bạn có muốn đăng xuất khỏi tài khoản này?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("HỦY")),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            auth.logout();
                          },
                          child: const Text("ĐĂNG XUẤT", style: TextStyle(color: Colors.red))
                      ),
                    ],
                  )
              );
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text("ĐĂNG XUẤT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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