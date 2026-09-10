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
    var query = _client
        .from('places')
        .select()
        .eq('city', city)
        .eq('is_active', true);

    if (category != null &&
        category.trim().isNotEmpty &&
        category != 'Tümü') {
      query = query.eq(
        'category',
        category,
      );
    }

    final rows = await query
        .limit(limit);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(Place.fromMap)
        .toList();
  }

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
