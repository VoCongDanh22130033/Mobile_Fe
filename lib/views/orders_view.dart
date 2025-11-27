import 'package:flutter/material.dart';
import 'package:shopsense_new/models/order.dart';
import 'package:shopsense_new/repository/customer_repo.dart';
import 'package:shopsense_new/views/order_view.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text("My Orders"),
      ),
      body: FutureBuilder<List<Order>>(
        future: customerOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderView(
                            orderId: snapshot.data![index].id.toString()),
                      ),
                    );
                  },
                  leading: Text(
                    snapshot.data![index].id.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                  title: Text(
                    snapshot.data![index].status,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle:
                      Text(snapshot.data![index].orderDate.toIso8601String()),
                  trailing: Text(
                    "\$${snapshot.data![index].orderTotal.toString()}",
                    style: const TextStyle(fontSize: 16),
                  ),

                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
