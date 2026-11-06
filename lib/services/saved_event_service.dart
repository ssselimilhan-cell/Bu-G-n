import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedEventService {
  static const String _key = 'saved_event_ids';
  static const String _entityType = 'event';

  final SupabaseClient _client = Supabase.instance.client;

  Future<Set<String>> getSavedIds() async {
    final user = _client.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();

    if (user == null) {
      return prefs.getStringList(_key)?.toSet() ?? <String>{};
    }

    // Preserve existing device-only saves by importing them into the account.
    final localIds = prefs.getStringList(_key)?.toSet() ?? <String>{};
    if (localIds.isNotEmpty) {
      final rows = localIds.map((id) => <String, dynamic>{
        'user_id': user.id,
        'entity_type': _entityType,
        'entity_id': id,
      }).toList();

      await _client.from('saved_items').upsert(
        rows,
        onConflict: 'user_id,entity_type,entity_id',
        ignoreDuplicates: true,
      );
      // Remove local copies only after the server accepted the import.
      await prefs.remove(_key);
    }

    final rows = await _client
        .from('saved_items')
        .select('entity_id')
        .eq('user_id', user.id)
        .eq('entity_type', _entityType);

    return rows
        .whereType<Map<String, dynamic>>()
        .map((row) => row['entity_id'].toString())
        .toSet();
  }

  Future<bool> isSaved(String eventId) async {
    final ids = await getSavedIds();
    return ids.contains(eventId);
  }

  Future<void> toggleSaved(String eventId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_key)?.toSet() ?? <String>{};
      if (ids.contains(eventId)) {
        ids.remove(eventId);
      } else {
        ids.add(eventId);
      }
      await prefs.setStringList(_key, ids.toList());
      return;
    }

    final saved = await _client
        .from('saved_items')
        .select('entity_id')
        .eq('user_id', user.id)
        .eq('entity_type', _entityType)
        .eq('entity_id', eventId)
        .maybeSingle();

    if (saved != null) {
      await _client
          .from('saved_items')
          .delete()
          .eq('user_id', user.id)
          .eq('entity_type', _entityType)
          .eq('entity_id', eventId);
    } else {
      await _client.from('saved_items').insert({
        'user_id': user.id,
        'entity_type': _entityType,
        'entity_id': eventId,
      });
    }
  }

  Future<void> remove(String eventId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_key)?.toSet() ?? <String>{};
      ids.remove(eventId);
      await prefs.setStringList(_key, ids.toList());
      return;
    }

    await _client
        .from('saved_items')
        .delete()
        .eq('user_id', user.id)
        .eq('entity_type', _entityType)
        .eq('entity_id', eventId);
  }
}
