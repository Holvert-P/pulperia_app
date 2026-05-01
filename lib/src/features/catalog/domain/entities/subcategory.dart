class CatalogSubcategory {
  const CatalogSubcategory({
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

  CatalogSubcategory copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? normalizedName,
    String? description,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryNormalizedName,
    int? productCount,
  }) {
    return CatalogSubcategory(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      categoryNormalizedName:
          categoryNormalizedName ?? this.categoryNormalizedName,
      productCount: productCount ?? this.productCount,
    );
  }
}
