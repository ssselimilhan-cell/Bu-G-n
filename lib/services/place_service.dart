import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';

class PlaceService {
  final SupabaseClient _client =
      Supabase.instance.client;

  Future<List<Place>> getPlaces({
    String city = 'Ankara',
    String? category,
    int limit = 50,
  }) async {
    // Filter by city in the database BEFORE applying the row limit.
    // Filtering a global 2,000-row sample locally can omit every place for
    // a city simply because its rows occur later in the table.
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
    final normalizedCity = _normalizeCity(city);
    return rows
        .whereType<Map<String, dynamic>>()
        // Keep a local normalized check as a defensive guard.
        .where((row) => _normalizeCity(row['city']?.toString() ?? '') == normalizedCity)
        .map(Place.fromMap)
        .toList();
  }

  String _normalizeCity(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('İ', 'i')
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  Future<List<Place>> getPlacesByIds(
    Iterable<String> ids,
  ) async {
    final idList = ids.toList();

    if (idList.isEmpty) {
      return <Place>[];
    }

    final rows = await _client
        .from('places')
        .select()
        .inFilter('id', idList)
        .eq('is_active', true);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(Place.fromMap)
        .toList();
  }
}
