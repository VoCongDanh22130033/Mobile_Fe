class Wishlist {
  int customerId;
  int productId;
  String title;
  String thumbnailUrl;
  double salePrice;
  String stockStatus;

  Wishlist({
    required this.customerId,
    required this.productId,
    required this.title,
    required this.thumbnailUrl,
    required this.salePrice,
    required this.stockStatus,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      customerId: json['customerId'] ?? 0,
      productId: json['productId'] ?? 0,
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      salePrice: (json['salePrice'] ?? 0).toDouble(),
      stockStatus: json['stockStatus'] ?? '',
    );
  }

  // ✅ Thêm hàm toJson để gửi dữ liệu lên API
  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'productId': productId,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'salePrice': salePrice,
      'stockStatus': stockStatus,
    };
  }
}
