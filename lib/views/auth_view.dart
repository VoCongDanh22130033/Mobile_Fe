import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsense_new/models/customer.dart';
import 'package:shopsense_new/models/auth_response.dart';
import 'package:shopsense_new/providers/auth_provider.dart';
import 'package:shopsense_new/repository/customer_repo.dart';
import 'package:shopsense_new/views/admin/admin_home.dart';
import 'package:shopsense_new/home.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView>
    with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _address.dispose();
    _emailLogin.dispose();
    _passwordLogin.dispose();
    super.dispose();
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // LOGIN
  Future<void> signin() async {
    setState(() => _isLoading = true);
    
    try {
      // LOGIN → LẤY TOKEN VÀ CUSTOMER TỪ RESPONSE
      final result = await loginWithCustomer(
        _emailLogin.text.trim(),
        _passwordLogin.text.trim(),
      );

      if (result == null || result['token'] == null) {
        showMessage("Invalid email or password");
        return;
      }

      final String token = result['token'];
      Customer? customer = result['customer'];

      // Nếu không có customer trong response, thử lấy từ profile
      if (customer == null) {
        try {
          // LƯU TOKEN TRƯỚC
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          
          // LẤY PROFILE BẰNG TOKEN
          customer = await customerProfile();
        } catch (e) {
          showMessage("Không thể lấy thông tin người dùng");
          return;
        }
      } else {
        // LƯU TOKEN VÀ CUSTOMER ID
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('customerId', customer.id.toString());
      }

      // SET AUTH
      await context.read<AuthProvider>().setAuth(token, customer);

      // ROUTE THEO ROLE
      if (customer.role == "ADMIN") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeView()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Home()),
        );
      }

      showMessage("Welcome, ${customer.name}!");
    } catch (e) {
      showMessage("Lỗi đăng nhập: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> signinWithGoogle() async {
    try {
      // 1) Firebase login
      final authProvider = context.read<AuthProvider>();
      final String firebaseIdToken = await authProvider.loginWithGoogleFirebase();

      // 2) đổi Firebase ID Token -> JWT backend
      final String? token = await loginWithFirebaseIdToken(firebaseIdToken);
      if (token == null) {
        showMessage("Login Google thất bại (backend không cấp token)");
        return;
      }

      // 3) lưu token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      // 4) lấy profile backend
      final Customer customer = await customerProfile();
      
      // Lưu customerId
      await prefs.setString('customerId', customer.id.toString());

      await context.read<AuthProvider>().setAuth(token, customer);

      // 5) route theo role
      if (customer.role == "ADMIN") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeView()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Home()),
        );
      }

      showMessage("Welcome, ${customer.name}!");
    } catch (e) {
      showMessage("Google login error: $e");
    }
  }

  Future<void> signinWithFacebook() async {
    try {
      // 1) Firebase login
      final authProvider = context.read<AuthProvider>();
      final String firebaseIdToken = await authProvider.loginWithFacebookFirebase();

      // 2) đổi Firebase ID Token -> JWT backend
      final String? token = await loginWithFirebaseIdToken(firebaseIdToken);
      if (token == null) {
        showMessage("Login Facebook thất bại (backend không cấp token)");
        return;
      }

      // 3) lưu token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      // 4) lấy profile backend
      final Customer customer = await customerProfile();
      
      // Lưu customerId
      await prefs.setString('customerId', customer.id.toString());

      await context.read<AuthProvider>().setAuth(token, customer);

      // 5) route theo role
      if (customer.role == "ADMIN") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeView()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Home()),
        );
      }

      showMessage("Welcome, ${customer.name}!");
    } catch (e) {
      showMessage("Facebook login error: $e");
    }
  }

  // SIGNUP
  Future<void> signup() async {
    final Customer c = Customer(
      id: 0,
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      address: _address.text.trim(),
      status: null,
      emailVerified: false,
      role: "",
    );

    final bool ok = await customerSignup(c);

    showMessage(ok ? "Sign up successful!" : "Something went wrong");

    if (ok) {
      setState(() => isLogin = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
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
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: AnimatedCrossFade(
                      crossFadeState: isLogin
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 500),
                      firstChild: _buildLoginForm(),
                      secondChild: _buildSignupForm(),
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

  // UI
  Widget _buildLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Welcome Back 👋",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text("LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),

        const SizedBox(height: 12),

        //Google
        OutlinedButton.icon(
          onPressed: signinWithGoogle,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          icon: const Icon(Icons.g_mobiledata),
          label: const Text(
            "Đăng nhập bằng Google",
            style: TextStyle(fontSize: 16),
          ),
        ),

        const SizedBox(height: 10),

        //Facebook
        OutlinedButton.icon(
          onPressed: signinWithFacebook,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          icon: const Icon(Icons.facebook),
          label: const Text(
            "Đăng nhập bằng Facebook",
            style: TextStyle(fontSize: 16),
          ),
        ),

        const SizedBox(height: 10),

        TextButton(
          onPressed: () => setState(() => isLogin = false),
          child: const Text("Don’t have an account? Sign up"),
        ),
      ],
    );
  }


  Widget _buildSignupForm() {
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
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