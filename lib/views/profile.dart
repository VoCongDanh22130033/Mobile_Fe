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

    _refreshProfile();
  }

  // Cải tiến: Thêm option truyền trực tiếp data để tránh gọi API nếu không cần
  void _refreshProfile({Customer? updatedData}) {
    if (mounted) {
      setState(() {
        if (updatedData != null) {
          _profileFuture = Future.value(updatedData);
        } else {
          _profileFuture = customerProfile();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// --- UI KHI CHƯA ĐĂNG NHẬP ---
  Widget _buildNotLoggedInView() {
    return Scaffold( // Thêm Scaffold để đồng bộ layout
      backgroundColor: Colors.indigo,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, color: Colors.white, size: 100),
              const SizedBox(height: 20),
              const Text(
                "Chào bạn!",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Đăng nhập để trải nghiệm đầy đủ tính năng",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 8,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthView()),
                ).then((_) => _refreshProfile()),
                child: const Text("ĐĂNG NHẬP / ĐĂNG KÝ", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// --- UI CARD CHỨC NĂNG ---
  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return ScaleTransition(
      scale: _fadeIn,
      child: Card(
        elevation: 1, // Giảm shadow để giao diện hiện đại hơn
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: Colors.indigo),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// --- UI CHÍNH KHI ĐÃ ĐĂNG NHẬP ---
  Widget _buildProfileView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        title: const Text("Tài khoản của tôi", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _refreshProfile(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshProfile(),
        child: FutureBuilder<Customer>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingSkeleton();
            }
            if (snapshot.hasError) {
              return _buildErrorView();
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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Header Indigo với đường cong
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: (user.img != null && user.img!.isNotEmpty)
                            ? NetworkImage("${user.img}?t=${DateTime.now().millisecondsSinceEpoch}") // Chống cache ảnh
                            : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name ?? "Người dùng Sense",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(
                      user.email ?? "",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600], letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 140), // Khoảng cách cho avatar lồi ra

          // Grid chức năng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.1,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard("Đơn Hàng", Icons.local_shipping_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdersView()));
                }),
                _buildActionCard("Chỉnh Sửa", Icons.manage_accounts_outlined, () async {
                  // Logic: Chỉ mở trang edit khi lấy được dữ liệu mới nhất
                  final freshProfile = await customerProfile();
                  if (!mounted) return;

                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfileView(currentUser: freshProfile))
                  );

                  // Cải tiến: Nếu edit trả về Customer object, dùng luôn không cần gọi API lại
                  if (result != null && result is Customer) {
                    _refreshProfile(updatedData: result);
                  } else if (result == true) {
                    _refreshProfile();
                  }
                }),
                _buildActionCard("Yêu Thích", Icons.favorite_border_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const WishlistScreen()));
                }),
                _buildActionCard("Địa Chỉ", Icons.location_on_outlined, () {
                  // TODO: Implement Address Manager
                }),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Nút Đăng xuất
          _buildLogoutButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.indigo, strokeWidth: 3),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text("Không thể tải thông tin cá nhân"),
          TextButton(onPressed: () => _refreshProfile(), child: const Text("Thử lại")),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: TextButton.icon(
          onPressed: () => _confirmLogout(auth),
          icon: const Icon(Icons.logout_rounded, color: Colors.red),
          label: const Text("ĐĂNG XUẤT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1)),
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.red.withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đăng xuất?"),
        content: const Text("Bạn có chắc chắn muốn thoát khỏi tài khoản này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                auth.logout();
              },
              child: const Text("ĐĂNG XUẤT", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return auth.userId.isEmpty ? _buildNotLoggedInView() : _buildProfileView();
      },
    );
  }
}