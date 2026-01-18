
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

  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _emailLogin = TextEditingController();
  final TextEditingController _passwordLogin = TextEditingController();

// default

  Future<void> signin() async {
    // chỉ gửi email + password
    Customer loginUser = Customer(
      id: 0,
      name: "",
      email: _emailLogin.text,
      password: _passwordLogin.text,
      address: "",
      status: "",
      emailVerified: false,
      role: "", // Không gửi role nữa
    );

    // API đăng nhập (server tự trả role)
    Customer? loggedInUser = await customerSignin(loginUser);

    if (loggedInUser == null) {
      showMessage("Invalid email or password");
      return;
    }

    // cập nhật userId/provider
    context.read<AuthProvider>().updateUserId();

    // ✅ Điều hướng dựa theo role do server trả về
    if (loggedInUser.role == "ADMIN") {
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

    showMessage("Welcome, ${loggedInUser.name}!");
  }

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> signup() async {
    Customer c = Customer(
      id: 0,
      name: _name.text,
      email: _email.text,
      password: _password.text,
      address: _address.text,
      status: "Pending",
      emailVerified: false,
      role: "CUSTOMER",
    );

    bool ok = await customerSignup(c);
    showMessage(ok ? "Sign up successful!" : "Something went wrong");
    if (ok) setState(() => isLogin = true);
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
      children: [
        const Text(
          "Welcome Back 👋",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailLogin,
          decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passwordLogin,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock_outline)),
        ),
        const SizedBox(height: 10),
        // Dropdown chọn role

        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: signin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text("Login", style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => isLogin = false),
          child: const Text("Don’t have an account? Sign up"),
        ),
      ],
    );
  }

  Widget buildSignupForm() {
    return Column(
      children: [
        const Text(
          "Create Account ✨",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: "Name", prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _email,
          decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock_outline)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _address,
          decoration: const InputDecoration(labelText: "Address", prefixIcon: Icon(Icons.home_outlined)),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: signup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
