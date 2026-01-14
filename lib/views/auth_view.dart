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
    // BƯỚC 1: LOGIN → LẤY TOKEN
    final String? token = await login(
      _emailLogin.text.trim(),
      _passwordLogin.text.trim(),
    );

    if (token == null) {
      showMessage("Invalid email or password");
      return;
    }

    // LƯU TOKEN TRƯỚC
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    // BƯỚC 2: LẤY PROFILE BẰNG TOKEN
    final Customer customer = await customerProfile();

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

  // ======================
  // SIGNUP
  // ======================
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
        decoration: const BoxDecoration(gradient: gradient),
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

  // ======================
  // UI
  // ======================
  Widget _buildLoginForm() {
    return Column(
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
          decoration: const InputDecoration(
            labelText: "Email",
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _passwordLogin,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Password",
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 20),

        //Login thường
        ElevatedButton(
          onPressed: signin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text("Login", style: TextStyle(fontSize: 18)),
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
      children: [
        const Text(
          "Create Account ✨",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: "Name",
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _email,
          decoration: const InputDecoration(
            labelText: "Email",
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Password",
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _address,
          decoration: const InputDecoration(
            labelText: "Address",
            prefixIcon: Icon(Icons.home_outlined),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: signup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text("Sign up", style: TextStyle(fontSize: 18)),
        ),
        TextButton(
          onPressed: () => setState(() => isLogin = true),
          child: const Text("Already have an account? Login"),
        ),
      ],
    );
  }
}
