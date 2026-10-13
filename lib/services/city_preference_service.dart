import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the selected city on the device for guests and in the user's
/// Supabase profile for signed-in users.
class CityPreferenceService {
  static const String _localCityKey = 'bugun_selected_city';
  static const String defaultCity = 'Ankara';

  final SupabaseClient _client = Supabase.instance.client;

  Future<String> getSelectedCity() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      try {
        final row = await _client
            .from('profiles')
            .select('city')
            .eq('id', user.id)
            .maybeSingle();
        final city = row?['city'] as String?;
        if (city != null && city.trim().isNotEmpty) {
          await _saveLocal(city);
          return city;
        }
      } catch (_) {
        // A local preference keeps discovery available if the profile
        // cannot be reached temporarily.
      }
    }

    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_localCityKey) ?? defaultCity;
  }

  Future<void> saveSelectedCity(String city) async {
    final normalized = city.trim();
    if (normalized.isEmpty) return;

    await _saveLocal(normalized);
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('profiles').upsert({
      'id': user.id,
      'city': normalized,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> _saveLocal(String city) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localCityKey, city);
  }
}
