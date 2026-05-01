class ProformaItem {
  const ProformaItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  final String productId;
  final String name;
  final int quantity;
  final double price;
  final double subtotal;

  ProformaItem copyWith({
    String? productId,
    String? name,
    int? quantity,
    double? price,
    double? subtotal,
  }) {
    return ProformaItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}
