import 'package:shared_preferences/shared_preferences.dart';

class SavedPlaceService {
  static const String _key = 'saved_place_ids';

  Future<Set<String>> getSavedIds() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getStringList(_key)?.toSet() ?? <String>{};
  }

  Future<bool> isSaved(String placeId) async {
    final ids = await getSavedIds();

    return ids.contains(placeId);
  }

  Future<void> toggleSaved(String placeId) async {
    final prefs = await SharedPreferences.getInstance();

    final ids =
        prefs.getStringList(_key)?.toSet() ?? <String>{};

    if (ids.contains(placeId)) {
      ids.remove(placeId);
    } else {
      ids.add(placeId);
    }

    await prefs.setStringList(
      _key,
      ids.toList(),
    );
  }

  Future<void> remove(String placeId) async {
    final prefs = await SharedPreferences.getInstance();

    final ids =
        prefs.getStringList(_key)?.toSet() ?? <String>{};

    ids.remove(placeId);

    await prefs.setStringList(
      _key,
      ids.toList(),
    );
  }
}
