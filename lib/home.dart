import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:shopsense_new/views/explore.dart';
import 'package:shopsense_new/views/profile.dart';
import 'package:shopsense_new/views/search.dart';
import 'package:shopsense_new/views/wishlist_view.dart';
import 'package:shopsense_new/views/auth_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedScreen = 0;

  Future<bool> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId != null && userId.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Loading tạm thời
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == false) {
          // Chưa login -> điều hướng sang AuthView
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AuthView()),
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Đã login -> hiển thị Home bình thường
        List<Widget> screens = [
          const Explore(),
          const Search(),
          const WishlistScreen(),
          const Profile(),
        ];

        return Scaffold(
          body: screens[selectedScreen],
          bottomNavigationBar: Container(
            color: Colors.indigo,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: GNav(
                onTabChange: (index) {
                  setState(() {
                    selectedScreen = index;
                  });
                },
                gap: 8,
                padding: const EdgeInsets.all(12),
                backgroundColor: Colors.indigo,
                color: Colors.white,
                activeColor: Colors.white,
                tabBackgroundColor: Colors.white38,
                tabs: const [
                  GButton(icon: Icons.home, text: 'Home'),
                  GButton(icon: Icons.search, text: 'Search'),
                  GButton(icon: Icons.favorite, text: 'Wishlist'),
                  GButton(icon: Icons.account_circle, text: 'Profile'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
