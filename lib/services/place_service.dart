import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';

class PlaceService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Place>> getPlaces({
    String city = 'Ankara',
    String? category,
    int limit = 50,
  }) async {
    final normalizedCity = _normalizeCity(city);

    // Normal path: let Postgres filter by city so we don't download unrelated
    // records. The final client-side check protects against inconsistent casing.
    var query = _client
        .from('places')
        .select()
        .eq('is_active', true)
        .ilike('city', city.trim());

    if (category != null &&
        category.trim().isNotEmpty &&
        category != 'Tümü') {
      query = query.eq('category', category);
    }

    final rows = await query.limit(limit);
    var matchingRows = rows
        .whereType<Map<String, dynamic>>()
        .where((row) =>
            _normalizeCity(row['city']?.toString() ?? '') == normalizedCity)
        .toList();

    // Defensive fallback: if Postgres ILIKE and the app's Unicode/city spelling
    // don't agree (notably Turkish I/İ/ı), scan active rows in bounded pages and
    // normalize city names locally. There are only a few thousand place rows,
    // so this fallback is small and only runs when the indexed query finds none.
    if (matchingRows.isEmpty && normalizedCity.isNotEmpty) {
      final fallbackRows = <Map<String, dynamic>>[];
      const pageSize = 1000;
      for (var start = 0; start < 10000; start += pageSize) {
        final page = await _client
            .from('places')
            .select()
            .eq('is_active', true)
            .range(start, start + pageSize - 1);
        final typedPage = page.whereType<Map<String, dynamic>>().toList();
        fallbackRows.addAll(typedPage.where((row) =>
            _normalizeCity(row['city']?.toString() ?? '') == normalizedCity));
        if (typedPage.length < pageSize || fallbackRows.length >= limit) {
          break;
        }
      }
      matchingRows = fallbackRows;
      if (category != null &&
          category.trim().isNotEmpty &&
          category != 'Tümü') {
        matchingRows = matchingRows
            .where((row) => row['category']?.toString() == category)
            .toList();
      }
    }

    return matchingRows.take(limit).map(Place.fromMap).toList();
  }

  String _normalizeCity(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('\u0307', '');

  Future<List<Place>> getPlacesByIds(Iterable<String> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) return <Place>[];

    final rows = await _client
        .from('places')
        .select()
        .inFilter('id', idList)
        .eq('is_active', true);

    return rows.whereType<Map<String, dynamic>>().map(Place.fromMap).toList();
  }
}
