import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Saves event IDs locally for guests and in Supabase for signed-in users.
class SavedEventService {
  static const String _key = 'saved_event_ids';
  final SupabaseClient _client = Supabase.instance.client;

  Future<Set<String>> getSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final localIds = prefs.getStringList(_key)?.toSet() ?? <String>{};
    final user = _client.auth.currentUser;
    if (user == null) return localIds;

    // Import guest saves into the authenticated account once, then remove the
    // device-only copy so it cannot leak into a different account later.
    if (localIds.isNotEmpty) {
      final existingRows = await _client
          .from('saved_items')
          .select('entity_id')
          .eq('user_id', user.id)
          .eq('entity_type', 'event')
          .inFilter('entity_id', localIds.toList());
      final existingIds = existingRows
          .whereType<Map<String, dynamic>>()
          .map((row) => row['entity_id'].toString())
          .toSet();
      for (final id in localIds.difference(existingIds)) {
        await _client.from('saved_items').insert({
          'user_id': user.id,
          'entity_type': 'event',
          'entity_id': id,
        });
      }
      await prefs.remove(_key);
    }

    final rows = await _client
        .from('saved_items')
        .select('entity_id')
        .eq('user_id', user.id)
        .eq('entity_type', 'event');
    return rows
        .whereType<Map<String, dynamic>>()
        .map((row) => row['entity_id'].toString())
        .toSet();
  }

  Future<bool> isSaved(String eventId) async {
    return (await getSavedIds()).contains(eventId);
  }

  Future<void> toggleSaved(String eventId) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      final existing = await _client
          .from('saved_items')
          .select('entity_id')
          .eq('user_id', user.id)
          .eq('entity_type', 'event')
          .eq('entity_id', eventId)
          .maybeSingle();
      if (existing != null) {
        await _client.from('saved_items')
            .delete()
            .eq('user_id', user.id)
            .eq('entity_type', 'event')
            .eq('entity_id', eventId);
      } else {
        await _client.from('saved_items').insert({
          'user_id': user.id,
          'entity_type': 'event',
          'entity_id': eventId,
        });
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key)?.toSet() ?? <String>{};
    if (ids.contains(eventId)) {
      ids.remove(eventId);
    } else {
      ids.add(eventId);
    }
    await prefs.setStringList(_key, ids.toList());
  }

  Future<void> remove(String eventId) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      await _client.from('saved_items')
          .delete()
          .eq('user_id', user.id)
          .eq('entity_type', 'event')
          .eq('entity_id', eventId);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key)?.toSet() ?? <String>{};
    ids.remove(eventId);
    await prefs.setStringList(_key, ids.toList());
  }
}
