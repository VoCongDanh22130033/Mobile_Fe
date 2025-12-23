import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String thumbnailUrl;
  final String title;
  final double price;
  final double salePrice;

  ProductCard({
    required this.thumbnailUrl,
    required this.title,
    required this.price,
    required this.salePrice,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0, // Add a shadow to the card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0), // Rounded corners
      ),
      child: Column(
        children: <Widget>[
          Image.network(
            thumbnailUrl,
            height: 150,
            width: double.infinity, // Expand the image to fit the card
            fit: BoxFit.cover,
          ),
          ListTile(
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${price.toStringAsFixed(2)}VNĐ',
                  style: const TextStyle(
                    color: Colors.red,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  '${salePrice.toStringAsFixed(2)}VNĐ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}