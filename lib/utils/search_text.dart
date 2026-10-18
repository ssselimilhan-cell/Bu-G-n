/// Normalizes text for accent-insensitive Turkish search and filtering.
String normalizeSearchText(String value) {
  return value
      .toLowerCase()
      // Dart lowercases capital dotted İ as "i" + COMBINING DOT ABOVE.
      // Remove that mark so "İstanbul" matches a user query of "istanbul".
      .replaceAll('\u0307', '')
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
