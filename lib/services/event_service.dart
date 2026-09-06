import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/event.dart';

class EventService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Event>> getTodayEvents({
    String city = 'Ankara',
  }) async {
    final now = DateTime.now();

    final startLocal = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endLocal = startLocal.add(
      const Duration(days: 1),
    );

    final startUtc = startLocal.toUtc().toIso8601String();
    final endUtc = endLocal.toUtc().toIso8601String();

    final rows = await _client
        .from('events')
        .select('''
          id,
          title,
          category,
          description,
          starts_at,
          ends_at,
          price_min,
          price_max,
          image_url,
          trust_score,
          recommendation_score,
          place_id,
          places(
            name,
            address,
            latitude,
            longitude
          )
        ''')
        .eq('city', city)
        .eq('is_active', true)
        .gte('starts_at', startUtc)
        .lt('starts_at', endUtc)
        .order(
          'recommendation_score',
          ascending: false,
        )
        .order(
          'starts_at',
          ascending: true,
        )
        .limit(50);

    return rows.map<Event>((row) {
      final place = row['places'] as Map<String, dynamic>?;

      return Event.fromMap({
        ...row,
        'venue_name': place?['name'],
        'address': place?['address'],
        'latitude': place?['latitude'],
        'longitude': place?['longitude'],
      });
    }).toList();
  }
}