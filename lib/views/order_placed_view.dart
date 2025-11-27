import 'package:flutter/material.dart';
import 'package:shopsense_new/home.dart';
import 'package:shopsense_new/views/order_view.dart';

class OrderPlacedView extends StatefulWidget {
  final orderId;

  const OrderPlacedView({super.key, this.orderId});

  @override
  State<OrderPlacedView> createState() => _OrderPlacedViewState();
}

class _OrderPlacedViewState extends State<OrderPlacedView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_outlined,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 50),
            const Text(
              "Your Order Has\nBeen Accepted",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your item has been placed and is\non it's way to being processed",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderView(orderId: widget.orderId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
              ),
              child: const Text(
                "Track Order",
                style: TextStyle(fontSize: 17),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Home(),
                    ),
                    (route) => false);
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
              ),
              child: const Text(
                "Back To Home",
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.black,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
