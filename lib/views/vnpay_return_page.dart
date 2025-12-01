import 'package:flutter/material.dart';

class VnPayReturnPage extends StatelessWidget {
  final Uri deepLink;

  const VnPayReturnPage({super.key, required this.deepLink});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VNPAY Return'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Deep Link: $deepLink'),
            // TODO: Add your logic here to handle the VNPAY return data
          ],
        ),
      ),
    );
  }
}
