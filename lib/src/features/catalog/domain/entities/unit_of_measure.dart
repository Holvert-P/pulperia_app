class UnitOfMeasure {
  const UnitOfMeasure({
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

  UnitOfMeasure copyWith({
    String? id,
    String? name,
    String? normalizedName,
    String? symbol,
    bool? allowsDecimal,
    String? description,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? productCount,
  }) {
    return UnitOfMeasure(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      symbol: symbol ?? this.symbol,
      allowsDecimal: allowsDecimal ?? this.allowsDecimal,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productCount: productCount ?? this.productCount,
    );
  }
}
