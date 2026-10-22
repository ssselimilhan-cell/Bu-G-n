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
    const columns = 'id,name,category,city,address,latitude,longitude,website,short_description,long_description,source_url,verified_at,content_review_status,is_free,visit_duration_min,indoor,outdoor,parking_available,kids_friendly,pet_friendly,difficulty_level,best_time,tags,verified,trust_score,place_type';

    var query = _client
        .from('places')
        .select(columns)
        .ilike('city', '%${city.trim()}%')
        .eq('is_active', true);

    if (category != null &&
        category.trim().isNotEmpty &&
        category != 'Tümü') {
      query = query.eq(
        'category',
        category,
      );
    }

    final rows = await query.limit(limit);

    // The city filter is normally handled by Postgres. If it returns no rows,
    // retry the active list and normalize the city locally so Turkish casing
    // or unexpected whitespace in a stored city name cannot blank the screen.
    if (rows.isNotEmpty) {
      return rows
          .whereType<Map<String, dynamic>>()
          .map(Place.fromMap)
          .toList();
    }

    var fallback = _client
        .from('places')
        .select(columns)
        .eq('is_active', true);
    if (category != null &&
        category.trim().isNotEmpty &&
        category != 'Tümü') {
      fallback = fallback.eq('category', category);
    }

    final fallbackRows = await fallback.limit(2000);
    final normalizedCity = _normalizeCity(city);
    return fallbackRows
        .whereType<Map<String, dynamic>>()
        .where((row) => _normalizeCity(row['city']?.toString() ?? '') == normalizedCity)
        .map(Place.fromMap)
        .take(limit)
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
