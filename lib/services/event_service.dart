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

    final start = now;
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    );

    return _getEvents(
      city: city,
      start: start.toUtc(),
      end: end.toUtc(),
      limit: limit,
    );
  }

  Future<List<Event>> getThisWeekEvents({
    String city = 'Ankara',
    int limit = 100,
  }) async {
    final now = DateTime.now();

    final dayFromMonday =
        now.weekday - DateTime.monday;

    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(
      Duration(days: dayFromMonday),
    );

    final nextMonday = monday.add(
      const Duration(days: 7),
    );

    final start = now;
    final end = nextMonday.subtract(
      const Duration(milliseconds: 1),
    );

    return _getEvents(
      city: city,
      start: start.toUtc(),
      end: end.toUtc(),
      limit: limit,
    );
  }

  Future<List<Event>> getThisMonthEvents({
    String city = 'Ankara',
    int limit = 200,
  }) async {
    final now = DateTime.now();

    final nextMonth = now.month == 12
        ? DateTime(
            now.year + 1,
            1,
            1,
          )
        : DateTime(
            now.year,
            now.month + 1,
            1,
          );

    final start = now;
    final end = nextMonth.subtract(
      const Duration(milliseconds: 1),
    );

    return _getEvents(
      city: city,
      start: start.toUtc(),
      end: end.toUtc(),
      limit: limit,
    );
  }

  Future<List<Event>> getUpcomingEvents({
    String city = 'Ankara',
    int days = 7,
    int limit = 100,
  }) async {
    final now = DateTime.now();

    final end = now.add(
      Duration(days: days),
    );

    return _getEvents(
      city: city,
      start: now.toUtc(),
      end: end.toUtc(),
      limit: limit,
    );
  }

  Future<List<Event>> getEventsByIds(
    Iterable<String> ids,
  ) async {
    final idList = ids.toList();

    if (idList.isEmpty) {
      return <Event>[];
    }

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
        .inFilter('id', idList)
        .order(
          'starts_at',
          ascending: true,
        );

    return rows
        .whereType<Map<String, dynamic>>()
        .map(Event.fromMap)
        .toList();
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
        .lte(
          'starts_at',
          end.toIso8601String(),
        )
        .order(
          'starts_at',
          ascending: true,
        )
        .order(
          'recommendation_score',
          ascending: false,
        )
        .limit(limit);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(Event.fromMap)
        .where(
          (event) =>
              event.startsAt.isAfter(
                DateTime.now(),
              ),
        )
        .toList();
  }
}
