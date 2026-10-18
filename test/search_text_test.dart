import 'package:flutter_test/flutter_test.dart';
import 'package:bugun/utils/search_text.dart';

void main() {
  group('normalizeSearchText', () {
    test('matches dotted Turkish capital I with plain Latin search', () {
      expect(normalizeSearchText('İstanbul'), 'istanbul');
      expect(normalizeSearchText('İSTANBUL'), 'istanbul');
      expect(normalizeSearchText('istanbul'), 'istanbul');
    });

    test('normalizes Turkish characters and repeated whitespace', () {
      expect(normalizeSearchText('  ÇANKAYA   İLÇESİ '), 'cankaya ilcesi');
      expect(normalizeSearchText('İzmir'), 'izmir');
    });
  });
}
