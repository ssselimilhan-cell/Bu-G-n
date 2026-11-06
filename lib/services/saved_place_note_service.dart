import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedPlaceNoteService {
  static const String _legacyPrefix = 'bugun_saved_place_note_';
  static const int maxLength = 240;

  final SupabaseClient _client = Supabase.instance.client;

  String _legacyKey(String placeId) => '$_legacyPrefix$placeId';

  Future<void> _importLegacyNotes(
    SharedPreferences prefs,
    String userId,
  ) async {
    final keys = prefs.getKeys()
        .where((key) => key.startsWith(_legacyPrefix))
        .toList();
    if (keys.isEmpty) return;

    final rows = <Map<String, dynamic>>[];
    for (final key in keys) {
      final placeId = key.substring(_legacyPrefix.length);
      final note = (prefs.getString(key) ?? '').trim();
      if (placeId.isEmpty || note.isEmpty) continue;
      rows.add({
        'user_id': userId,
        'place_id': placeId,
        'note': note.length > maxLength ? note.substring(0, maxLength) : note,
      });
    }

    if (rows.isNotEmpty) {
      await _client.from('saved_place_notes').upsert(
        rows,
        onConflict: 'user_id,place_id',
        ignoreDuplicates: true,
      );
    }

    // Remove old device copies only after the server import succeeds.
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<String> getNote(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final user = _client.auth.currentUser;
    if (user == null) {
      return prefs.getString(_legacyKey(placeId)) ?? '';
    }

    await _importLegacyNotes(prefs, user.id);
    final row = await _client
        .from('saved_place_notes')
        .select('note')
        .eq('user_id', user.id)
        .eq('place_id', placeId)
        .maybeSingle();
    return row?['note']?.toString() ?? '';
  }

  Future<void> saveNote(String placeId, String value) async {
    final note = value.trim();
    if (note.length > maxLength) {
      throw ArgumentError('Not en fazla $maxLength karakter olabilir.');
    }

    final prefs = await SharedPreferences.getInstance();
    final user = _client.auth.currentUser;
    if (user == null) {
      if (note.isEmpty) {
        await prefs.remove(_legacyKey(placeId));
      } else {
        await prefs.setString(_legacyKey(placeId), note);
      }
      return;
    }

    await _importLegacyNotes(prefs, user.id);
    if (note.isEmpty) {
      await _client
          .from('saved_place_notes')
          .delete()
          .eq('user_id', user.id)
          .eq('place_id', placeId);
    } else {
      await _client.from('saved_place_notes').upsert(
        {
          'user_id': user.id,
          'place_id': placeId,
          'note': note,
        },
        onConflict: 'user_id,place_id',
      );
    }
  }
}
