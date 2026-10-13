import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Saves place IDs locally for guests and in Supabase for signed-in users.
class SavedPlaceService {
  static const String _key = 'saved_place_ids';
  final SupabaseClient _client = Supabase.instance.client;

  Future<Set<String>> getSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final localIds = prefs.getStringList(_key)?.toSet() ?? <String>{};
    final user = _client.auth.currentUser;
    if (user == null) return localIds;

    // Import guest saves into the authenticated account once, then remove the
    // device-only copy so it cannot leak into a different account later.
    for (final id in localIds) {
      await _client.from('saved_items').upsert({
        'user_id': user.id,
        'entity_type': 'place',
        'entity_id': id,
      }, onConflict: 'user_id,entity_type,entity_id');
    }
    if (localIds.isNotEmpty) await prefs.remove(_key);

    final rows = await _client
        .from('saved_items')
        .select('entity_id')
        .eq('user_id', user.id)
        .eq('entity_type', 'place');
    return rows
        .whereType<Map<String, dynamic>>()
        .map((row) => row['entity_id'].toString())
        .toSet();
  }

  Future<bool> isSaved(String placeId) async {
    return (await getSavedIds()).contains(placeId);
  }

  Future<void> toggleSaved(String placeId) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      final existing = await _client
          .from('saved_items')
          .select('entity_id')
          .eq('user_id', user.id)
          .eq('entity_type', 'place')
          .eq('entity_id', placeId)
          .maybeSingle();
      if (existing != null) {
        await _client.from('saved_items')
            .delete()
            .eq('user_id', user.id)
            .eq('entity_type', 'place')
            .eq('entity_id', placeId);
      } else {
        await _client.from('saved_items').upsert({
          'user_id': user.id,
          'entity_type': 'place',
          'entity_id': placeId,
        }, onConflict: 'user_id,entity_type,entity_id');
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key)?.toSet() ?? <String>{};
    if (ids.contains(placeId)) {
      ids.remove(placeId);
    } else {
      ids.add(placeId);
    }
    await prefs.setStringList(_key, ids.toList());
  }

  Future<void> remove(String placeId) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      await _client.from('saved_items')
          .delete()
          .eq('user_id', user.id)
          .eq('entity_type', 'place')
          .eq('entity_id', placeId);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key)?.toSet() ?? <String>{};
    ids.remove(placeId);
    await prefs.setStringList(_key, ids.toList());
  }
}
