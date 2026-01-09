import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopsense_new/models/customer.dart';
import 'package:shopsense_new/providers/auth_provider.dart';
import 'package:shopsense_new/repository/customer_repo.dart';
import 'package:shopsense_new/views/admin/admin_home.dart';
import 'package:shopsense_new/home.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool _isLoading = false; // Trạng thái chờ xử lý API

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _emailLogin = TextEditingController();
  final TextEditingController _passwordLogin = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600)
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    // Giải phóng bộ nhớ cho các controller
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _address.dispose();
    _emailLogin.dispose();
    _passwordLogin.dispose();
    _controller.dispose();
    super.dispose();
  }

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Xử lý Đăng nhập
  Future<void> signin() async {
    if (_emailLogin.text.isEmpty || _passwordLogin.text.isEmpty) {
      showMessage("Vui lòng điền đầy đủ email và mật khẩu");
      return;
    }

    setState(() => _isLoading = true);

    try {
      Customer loginUser = Customer(
        id: 0,
        name: "",
        email: _emailLogin.text.trim(),
        password: _passwordLogin.text.trim(),
        address: "",
        status: "",
        emailVerified: false,
        role: "",
      );

      Customer? loggedInUser = await customerSignin(loginUser);

      if (loggedInUser == null) {
        showMessage("Email hoặc mật khẩu không chính xác");
        return;
      }

      // 🟢 Cập nhật Provider (Dùng await nếu updateUserId trả về Future)
      await context.read<AuthProvider>().updateUserId();

      if (!mounted) return;

      // Điều hướng dựa trên Role
      Widget destination = (loggedInUser.role == "ADMIN")
          ? const AdminHomeView()
          : const Home();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );

      showMessage("Chào mừng quay lại, ${loggedInUser.name}!");
    } catch (e) {
      showMessage("Lỗi đăng nhập: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Xử lý Đăng ký
  Future<void> signup() async {
    if (_email.text.isEmpty || _password.text.isEmpty || _name.text.isEmpty) {
      showMessage("Vui lòng điền các trường bắt buộc");
      return;
    }

    setState(() => _isLoading = true);

    try {
      Customer c = Customer(
        id: 0,
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text.trim(),
        address: _address.text.trim(),
        status: "Pending",
        emailVerified: false,
        role: "CUSTOMER",
      );

      bool ok = await customerSignup(c);
      if (ok) {
        showMessage("Đăng ký thành công! Hãy đăng nhập.");
        setState(() => isLogin = true);
      } else {
        showMessage("Đăng ký thất bại. Email có thể đã tồn tại.");
      }
    } catch (e) {
      showMessage("Lỗi kết nối: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Colors.indigo, Colors.blueAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: AnimatedCrossFade(
                      crossFadeState: isLogin ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 500),
                      firstChild: buildLoginForm(),
                      secondChild: buildSignupForm(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Welcome Back 👋",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailLogin,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: "Email",
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _passwordLogin,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Password",
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 25),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: signin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text("LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 15),
        TextButton(
          onPressed: () => setState(() => isLogin = false),
          child: const Text("Don’t have an account? Sign up"),
        ),
      ],
    );
  }

  Widget buildSignupForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Create Account ✨",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        const SizedBox(height: 20),
        _buildTextField(_name, "Name", Icons.person_outline),
        const SizedBox(height: 10),
        _buildTextField(_email, "Email", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 10),
        _buildTextField(_password, "Password", Icons.lock_outline, obscureText: true),
        const SizedBox(height: 10),
        _buildTextField(_address, "Address", Icons.home_outlined),
        const SizedBox(height: 25),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: signup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text("SIGN UP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => isLogin = true),
          child: const Text("Already have an account? Login"),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}