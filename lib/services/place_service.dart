import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';

class PlaceService {
  final SupabaseClient _client = Supabase.instance.client;

  // Public lists must not remove a place merely because its description
  // contains editorial uncertainty wording. Missing descriptive fields are
  // presented as "Veri yok" in the UI; valid coordinates are still required
  // for map directions.
  bool _hasUsableCoordinates(Place place) {
    if (place.latitude == null || place.longitude == null) return false;
    if (place.latitude! < -90 || place.latitude! > 90) return false;
    if (place.longitude! < -180 || place.longitude! > 180) return false;
    return true;
  }

  Future<List<Place>> getPlaces({
    String city = 'Ankara',
    String? category,
    int limit = 50,
  }) async {
    var query = _client
        .from('places')
        .select()
        .ilike('city', city.trim())
        .eq('is_active', true)
        .inFilter('content_review_status', ['verified'])
        .not('latitude', 'is', null)
        .not('longitude', 'is', null);

    if (category != null &&
        category.trim().isNotEmpty &&
        category != 'Tümü') {
      query = query.eq('category', category);
    }

    final rows = await query.limit(limit);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(Place.fromMap)
        .where(_hasUsableCoordinates)
        .toList();
  }

  Future<List<Place>> getPlacesByIds(Iterable<String> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) return <Place>[];

    final rows = await _client
        .from('places')
        .select()
        .inFilter('id', idList)
        .eq('is_active', true)
        .inFilter('content_review_status', ['verified', 'source_backed'])
        .not('latitude', 'is', null)
        .not('longitude', 'is', null);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(Place.fromMap)
        .where(_hasUsableCoordinates)
        .toList();
  }
}
