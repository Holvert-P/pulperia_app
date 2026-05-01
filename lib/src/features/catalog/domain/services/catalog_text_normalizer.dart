import 'package:app/src/features/products/domain/services/product_text_normalizer.dart';

class CatalogTextNormalizer {
  const CatalogTextNormalizer._();

  static String normalize(String value) {
    final normalized = ProductTextNormalizer.normalizeCategory(value);
    return normalized.isEmpty ? 'general' : normalized;
  }

  static String displayName(String normalizedName) {
    final words = normalize(normalizedName).split('_');
    return words
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  static String initials(String normalizedName, {int length = 3}) {
    final normalized = normalize(normalizedName);
    final parts = normalized.split('_').where((part) => part.isNotEmpty);
    final fromWords = parts.map((part) => part[0]).join().toUpperCase();
    final source = fromWords.length >= length
        ? fromWords
        : normalized.replaceAll('_', '').toUpperCase();
    if (source.length <= length) return source.padRight(length, 'X');
    return source.substring(0, length);
  }
}
