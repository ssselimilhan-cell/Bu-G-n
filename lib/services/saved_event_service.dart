import 'package:shared_preferences/shared_preferences.dart';

class SavedEventService {
  static const String _key = 'saved_event_ids';

  Future<Set<String>> getSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.toSet() ?? <String>{};
  }

  Future<bool> isSaved(String eventId) async {
    final ids = await getSavedIds();
    return ids.contains(eventId);
  }

  Future<void> toggleSaved(String eventId) async {
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
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key)?.toSet() ?? <String>{};

    ids.remove(eventId);

    await prefs.setStringList(_key, ids.toList());
  }
}