import 'package:app/src/features/proformas/domain/entities/proforma_item.dart';

class Proforma {
  const Proforma({
    required this.id,
    required this.customerName,
    required this.total,
    this.discount = 0.0,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String customerName;
  final double total;
  final double discount;
  final DateTime createdAt;
  final List<ProformaItem> items;

  Proforma copyWith({
    String? id,
    String? customerName,
    double? total,
    double? discount,
    DateTime? createdAt,
    List<ProformaItem>? items,
  }) {
    return Proforma(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      total: total ?? this.total,
      discount: discount ?? this.discount,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
