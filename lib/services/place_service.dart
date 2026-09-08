import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';

class PlaceService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Place>> getPlaces({
    String city = 'Ankara',
    String? category,
    int limit = 50,
  }) async {
    var query = _client
        .from('places')
        .select('''
          id,
          name,
          category,
          place_type,
          city,
          address,
          latitude,
          longitude,
          website,
          short_description,
          is_free,
          visit_duration_min,
          indoor,
          outdoor,
          parking_available,
          kids_friendly,
          pet_friendly,
          difficulty_level,
          best_time,
          tags,
          verified,
          trust_score
        ''')
        .eq('city', city)
        .eq('is_active', true);

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    final rows = await query
        .order('trust_score', ascending: false)
        .order('name', ascending: true)
        .limit(limit);

    return rows
        .map<Place>(
          (row) => Place.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<List<Place>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    String city = 'Ankara',
    String? category,
    int limit = 20,
  }) async {
    final places = await getPlaces(
      city: city,
      category: category,
      limit: 100,
    );

    final sorted = [...places];

    sorted.sort((a, b) {
      final distanceA = _distanceScore(
        latitude,
        longitude,
        a.latitude,
        a.longitude,
      );

      final distanceB = _distanceScore(
        latitude,
        longitude,
        b.latitude,
        b.longitude,
      );

      return distanceA.compareTo(distanceB);
    });

    return sorted.take(limit).toList();
  }

  double _distanceScore(
    double latitude1,
    double longitude1,
    double? latitude2,
    double? longitude2,
  ) {
    if (latitude2 == null || longitude2 == null) {
      return double.infinity;
    }

    final latDifference = latitude1 - latitude2;
    final lonDifference = longitude1 - longitude2;

    return (latDifference * latDifference) +
        (lonDifference * lonDifference);
  }
}
