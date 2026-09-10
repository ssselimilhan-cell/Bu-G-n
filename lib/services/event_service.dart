import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/event.dart';

class EventService {
  final SupabaseClient _client =
      Supabase.instance.client;

  Future<List<Event>> getTodayEvents({
    String city = 'Ankara',
    int limit = 50,
  }) async {
    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfDay =
        startOfDay.add(const Duration(days: 1));

    return _getEvents(
      city: city,
      start: startOfDay.toUtc(),
      end: endOfDay.toUtc(),
      limit: limit,
    );
  }

  Future<List<Event>> getUpcomingEvents({
    String city = 'Ankara',
    int days = 7,
    int limit = 100,
  }) async {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final end = start.add(
      Duration(days: days + 1),
    );

    return _getEvents(
      city: city,
      start: start.toUtc(),
      end: end.toUtc(),
      limit: limit,
    );
  }

  Future<List<Event>> _getEvents({
    required String city,
    required DateTime start,
    required DateTime end,
    required int limit,
  }) async {
    final rows = await _client
        .from('events')
        .select('''
          id,
          title,
          category,
          subcategory,
          description,
          starts_at,
          ends_at,
          price_min,
          price_max,
          image_url,
          source_url,
          ticket_url,
          venue_name,
          venue_address,
          trust_score,
          recommendation_score,
          is_active
        ''')
        .eq('city', city)
        .eq('is_active', true)
        .gte(
          'starts_at',
          start.toIso8601String(),
        )
        .lt(
          'starts_at',
          end.toIso8601String(),
        )
        .order(
          'starts_at',
          ascending: true,
        )
        .limit(limit);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(Event.fromMap)
        .toList();
  }
}
