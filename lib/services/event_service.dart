import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';

class EventService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Event>> getTodayEvents({String city = 'Ankara'}) async {
    final rows = await _client.from('events').select('''
      id,title,category,description,starts_at,ends_at,price_min,price_max,
      image_url,trust_score, recommendation_score,
      places(name,address,latitude,longitude)
    ''').eq('city', city).eq('is_active', true).gte('starts_at', _startOfToday())
      .lt('starts_at', _startOfTomorrow()).order('recommendation_score', ascending: false).limit(50);

    return rows.map<Event>((row) {
      final place = row['places'] as Map<String, dynamic>?;
      return Event.fromMap({...row, ...?place == null ? null : {
        'venue_name': place['name'],
        'address': place['address'],
        'latitude': place['latitude'],
        'longitude': place['longitude'],
      }});
    }).toList();
  }

  String _startOfToday() {
    final d = DateTime.now();
    return DateTime(d.year, d.month, d.day).toIso8601String();
  }

  String _startOfTomorrow() {
    final d = DateTime.now();
    return DateTime(d.year, d.month, d.day + 1).toIso8601String();
  }
}
