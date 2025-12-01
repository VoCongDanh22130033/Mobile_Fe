import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopsense_new/home.dart';
import 'package:shopsense_new/providers/auth_provider.dart';
import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// A global navigator key is useful for navigation from services
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Ensure Flutter is initialized before using plugins.
  WidgetsFlutterBinding.ensureInitialized();

  // NOTE: The web contents debugging line was removed to fix a compatibility issue.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const Home(),
      ),
    );
  }
}
