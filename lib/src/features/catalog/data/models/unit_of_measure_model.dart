import 'package:app/src/features/catalog/domain/entities/unit_of_measure.dart';

class UnitOfMeasureModel {
  const UnitOfMeasureModel({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.symbol,
    required this.allowsDecimal,
    required this.description,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.productCount = 0,
  });

  final String id;
  final String name;
  final String normalizedName;
  final String? symbol;
  final bool allowsDecimal;
  final String? description;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int productCount;

  factory UnitOfMeasureModel.fromMap(Map<String, Object?> map) {
    return UnitOfMeasureModel(
      id: map['id'] as String,
      name: map['name'] as String,
      normalizedName: map['normalized_name'] as String,
      symbol: map['symbol'] as String?,
      allowsDecimal: ((map['allows_decimal'] as num?)?.toInt() ?? 0) == 1,
      description: map['description'] as String?,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isActive: ((map['is_active'] as num?)?.toInt() ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      productCount: (map['product_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'normalized_name': normalizedName,
      'symbol': symbol,
      'allows_decimal': allowsDecimal ? 1 : 0,
      'description': description,
      'sort_order': sortOrder,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UnitOfMeasure toEntity() {
    return UnitOfMeasure(
      id: id,
      name: name,
      normalizedName: normalizedName,
      symbol: symbol,
      allowsDecimal: allowsDecimal,
      description: description,
      sortOrder: sortOrder,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      productCount: productCount,
    );
  }

  static UnitOfMeasureModel fromEntity(UnitOfMeasure entity) {
    return UnitOfMeasureModel(
      id: entity.id,
      name: entity.name,
      normalizedName: entity.normalizedName,
      symbol: entity.symbol,
      allowsDecimal: entity.allowsDecimal,
      description: entity.description,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      productCount: entity.productCount,
    );
  }
}
