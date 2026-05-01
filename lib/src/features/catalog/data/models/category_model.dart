import 'package:app/src/features/catalog/domain/entities/category.dart';

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.description,
    required this.iconName,
    required this.colorHex,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.subcategoryCount = 0,
    this.productCount = 0,
  });

  final String id;
  final String name;
  final String normalizedName;
  final String? description;
  final String? iconName;
  final String? colorHex;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int subcategoryCount;
  final int productCount;

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      normalizedName: map['normalized_name'] as String,
      description: map['description'] as String?,
      iconName: map['icon_name'] as String?,
      colorHex: map['color_hex'] as String?,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isActive: ((map['is_active'] as num?)?.toInt() ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      subcategoryCount: (map['subcategory_count'] as num?)?.toInt() ?? 0,
      productCount: (map['product_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'normalized_name': normalizedName,
      'description': description,
      'icon_name': iconName,
      'color_hex': colorHex,
      'sort_order': sortOrder,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CatalogCategory toEntity() {
    return CatalogCategory(
      id: id,
      name: name,
      normalizedName: normalizedName,
      description: description,
      iconName: iconName,
      colorHex: colorHex,
      sortOrder: sortOrder,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      subcategoryCount: subcategoryCount,
      productCount: productCount,
    );
  }

  static CategoryModel fromEntity(CatalogCategory entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      normalizedName: entity.normalizedName,
      description: entity.description,
      iconName: entity.iconName,
      colorHex: entity.colorHex,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      subcategoryCount: entity.subcategoryCount,
      productCount: entity.productCount,
    );
  }
}
