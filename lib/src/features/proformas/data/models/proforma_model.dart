import 'package:app/src/features/proformas/domain/entities/proforma.dart';
import 'package:app/src/features/proformas/domain/entities/proforma_item.dart';

class ProformaModel {
  const ProformaModel({
    required this.id,
    required this.customerName,
    required this.total,
    this.discount = 0.0,
    required this.createdAtIso,
    required this.items,
  });

  final String id;
  final String customerName;
  final double total;
  final double discount;
  final String createdAtIso;
  final List<ProformaItem> items;

  factory ProformaModel.fromMap(
    Map<String, Object?> map, {
    List<ProformaItem> items = const [],
  }) {
    return ProformaModel(
      id: map['id'] as String,
      customerName: map['customer_name'] as String,
      total: (map['total'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      createdAtIso: map['created_at'] as String,
      items: items,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'total': total,
      'discount': discount,
      'created_at': createdAtIso,
    };
  }

  Proforma toEntity() {
    return Proforma(
      id: id,
      customerName: customerName,
      total: total,
      discount: discount,
      createdAt: DateTime.parse(createdAtIso),
      items: items,
    );
  }

  factory ProformaModel.fromEntity(Proforma entity) {
    return ProformaModel(
      id: entity.id,
      customerName: entity.customerName,
      total: entity.total,
      discount: entity.discount,
      createdAtIso: entity.createdAt.toIso8601String(),
      items: entity.items,
    );
  }
}
