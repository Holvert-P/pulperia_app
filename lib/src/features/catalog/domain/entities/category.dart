class CatalogCategory {
  const CatalogCategory({
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

  CatalogCategory copyWith({
    String? id,
    String? name,
    String? normalizedName,
    String? description,
    String? iconName,
    String? colorHex,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? subcategoryCount,
    int? productCount,
  }) {
    return CatalogCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subcategoryCount: subcategoryCount ?? this.subcategoryCount,
      productCount: productCount ?? this.productCount,
    );
  }
}
