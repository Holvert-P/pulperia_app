class ProductTextNormalizer {
  ProductTextNormalizer._();

  static String normalizeName(String value) {
    return _slugify(value, separator: '-');
  }

  static String normalizeCategory(String value) {
    return _slugify(value, separator: '_');
  }

  static String _slugify(String value, {required String separator}) {
    final lower = _removeDiacritics(value).toLowerCase().trim();
    final normalized = lower
        .replaceAll(RegExp(r'[^a-z0-9]+'), separator)
        .replaceAll(RegExp('$separator+'), separator)
        .replaceAll(RegExp('^$separator|$separator\$'), '');
    return normalized;
  }

  static String _removeDiacritics(String value) {
    const replacements = {
      'a': 'áàäâã',
      'e': 'éèëê',
      'i': 'íìïî',
      'o': 'óòöôõ',
      'u': 'úùüû',
      'n': 'ñ',
      'c': 'ç',
    };

    var output = value;
    replacements.forEach((plain, accented) {
      for (final char in accented.split('')) {
        output = output.replaceAll(char, plain);
        output = output.replaceAll(char.toUpperCase(), plain);
      }
    });
    return output;
  }
}
