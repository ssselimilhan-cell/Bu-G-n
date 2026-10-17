import 'dart:convert';

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
    if (localIds.isNotEmpty) {
      final existingRows = await _client
          .from('saved_items')
          .select('entity_id')
          .eq('user_id', user.id)
          .eq('entity_type', 'place')
          .inFilter('entity_id', localIds.toList());
      final existingIds = existingRows
          .whereType<Map<String, dynamic>>()
          .map((row) => row['entity_id'].toString())
          .toSet();
      for (final id in localIds.difference(existingIds)) {
        await _client.from('saved_items').insert({
          'user_id': user.id,
          'entity_type': 'place',
          'entity_id': id,
        });
      }
      await prefs.remove(_key);
    }

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
        await _client.from('saved_items').insert({
          'user_id': user.id,
          'entity_type': 'place',
          'entity_id': placeId,
        });
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

  Future<String> getNote(String placeId) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      final row = await _client
          .from('saved_items')
          .select('note')
          .eq('user_id', user.id)
          .eq('entity_type', 'place')
          .eq('entity_id', placeId)
          .maybeSingle();
      return (row?['note'] as String?) ?? '';
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('saved_place_notes');
    if (raw == null) return '';
    try {
      final notes = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return notes[placeId]?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> saveNote(String placeId, String note) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      final existing = await _client
          .from('saved_items')
          .select('entity_id')
          .eq('user_id', user.id)
          .eq('entity_type', 'place')
          .eq('entity_id', placeId)
          .maybeSingle();
      if (existing == null) {
        await _client.from('saved_items').insert({
          'user_id': user.id,
          'entity_type': 'place',
          'entity_id': placeId,
          'note': note.trim(),
        });
      } else {
        await _client.from('saved_items')
            .update({'note': note.trim()})
            .eq('user_id', user.id)
            .eq('entity_type', 'place')
            .eq('entity_id', placeId);
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('saved_place_notes');
    Map<String, dynamic> notes = {};
    if (raw != null) {
      try {
        notes = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    if (note.trim().isEmpty) {
      notes.remove(placeId);
    } else {
      notes[placeId] = note.trim();
    }
    await prefs.setString('saved_place_notes', jsonEncode(notes));
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
