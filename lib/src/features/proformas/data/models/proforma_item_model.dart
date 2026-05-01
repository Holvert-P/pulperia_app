import 'package:app/src/features/proformas/domain/entities/proforma_item.dart';

class ProformaItemModel {
  const ProformaItemModel({
    required this.proformaId,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  final String proformaId;
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final double subtotal;

  factory ProformaItemModel.fromMap(Map<String, Object?> map) {
    return ProformaItemModel(
      proformaId: map['proforma_id'] as String,
      productId: map['product_id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toInt(),
      price: (map['price'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'proforma_id': proformaId,
      'product_id': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }

  ProformaItem toEntity() {
    return ProformaItem(
      productId: productId,
      name: name,
      quantity: quantity,
      price: price,
      subtotal: subtotal,
    );
  }

  factory ProformaItemModel.fromEntity({
    required String proformaId,
    required ProformaItem item,
  }) {
    return ProformaItemModel(
      proformaId: proformaId,
      productId: item.productId,
      name: item.name,
      quantity: item.quantity,
      price: item.price,
      subtotal: item.subtotal,
    );
  }
}
