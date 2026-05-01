import 'package:app/src/features/catalog/domain/entities/subcategory.dart';

class SubcategoryModel {
  const SubcategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.normalizedName,
    required this.description,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.categoryNormalizedName,
    this.productCount = 0,
  });

  final String id;
  final String categoryId;
  final String name;
  final String normalizedName;
  final String? description;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryName;
  final String? categoryNormalizedName;
  final int productCount;

  factory SubcategoryModel.fromMap(Map<String, Object?> map) {
    return SubcategoryModel(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      normalizedName: map['normalized_name'] as String,
      description: map['description'] as String?,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isActive: ((map['is_active'] as num?)?.toInt() ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      categoryName: map['category_name'] as String?,
      categoryNormalizedName: map['category_normalized_name'] as String?,
      productCount: (map['product_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'normalized_name': normalizedName,
      'description': description,
      'sort_order': sortOrder,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CatalogSubcategory toEntity() {
    return CatalogSubcategory(
      id: id,
      categoryId: categoryId,
      name: name,
      normalizedName: normalizedName,
      description: description,
      sortOrder: sortOrder,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      categoryName: categoryName,
      categoryNormalizedName: categoryNormalizedName,
      productCount: productCount,
    );
  }

  static SubcategoryModel fromEntity(CatalogSubcategory entity) {
    return SubcategoryModel(
      id: entity.id,
      categoryId: entity.categoryId,
      name: entity.name,
      normalizedName: entity.normalizedName,
      description: entity.description,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      categoryName: entity.categoryName,
      categoryNormalizedName: entity.categoryNormalizedName,
      productCount: entity.productCount,
    );
  }
}
