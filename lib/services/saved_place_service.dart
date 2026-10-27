import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedPlaceService {
  static const String _key = 'saved_place_ids';
  static const String _entityType = 'place';

  final SupabaseClient _client = Supabase.instance.client;

  Future<Set<String>> getSavedIds() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key)?.toSet() ?? <String>{};
    }

    // Import any guest/device-only saves once into the signed-in account.
    final prefs = await SharedPreferences.getInstance();
    final localIds = prefs.getStringList(_key)?.toSet() ?? <String>{};
    if (localIds.isNotEmpty) {
      final rows = localIds
          .map((id) => <String, dynamic>{
                'user_id': user.id,
                'entity_type': _entityType,
                'entity_id': id,
              })
          .toList();
      await _client.from('saved_items').upsert(
            rows,
            onConflict: 'user_id,entity_type,entity_id',
            ignoreDuplicates: true,
          );
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

  Future<bool> isSaved(String placeId) async {
    final ids = await getSavedIds();
    return ids.contains(placeId);
  }

  Future<void> toggleSaved(String placeId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_key)?.toSet() ?? <String>{};
      if (ids.contains(placeId)) {
        ids.remove(placeId);
      } else {
        ids.add(placeId);
      }
      await prefs.setStringList(_key, ids.toList());
      return;
    }

    final saved = await _client
        .from('saved_items')
        .select('entity_id')
        .eq('user_id', user.id)
        .eq('entity_type', _entityType)
        .eq('entity_id', placeId)
        .maybeSingle();

    if (saved != null) {
      await _client
          .from('saved_items')
          .delete()
          .eq('user_id', user.id)
          .eq('entity_type', _entityType)
          .eq('entity_id', placeId);
    } else {
      await _client.from('saved_items').upsert(
        {
          'user_id': user.id,
          'entity_type': _entityType,
          'entity_id': placeId,
        },
        onConflict: 'user_id,entity_type,entity_id',
      );
    }
  }

  Future<void> remove(String placeId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_key)?.toSet() ?? <String>{};
      ids.remove(placeId);
      await prefs.setStringList(_key, ids.toList());
      return;
    }

    await _client
        .from('saved_items')
        .delete()
        .eq('user_id', user.id)
        .eq('entity_type', _entityType)
        .eq('entity_id', placeId);
  }
}
