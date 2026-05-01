import 'package:app/src/features/catalog/domain/services/catalog_text_normalizer.dart';

class ProductSkuGenerator {
  const ProductSkuGenerator();

  String call({required String categoryNormalizedName, required int sequence}) {
    final prefix = CatalogTextNormalizer.initials(categoryNormalizedName);
    final group = (sequence ~/ 100).clamp(1, 99).toString().padLeft(2, '0');
    final number = sequence.clamp(1, 999).toString().padLeft(3, '0');
    return '$prefix-$group-$number';
  }
}
