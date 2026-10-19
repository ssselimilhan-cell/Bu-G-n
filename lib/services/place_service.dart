import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';
import '../utils/search_text.dart';

class PlaceService {
  final SupabaseClient _client =
      Supabase.instance.client;

  Future<List<Place>> getPlaces({
    String? city = 'Ankara',
    String? category,
    int limit = 50,
  }) async {
    var query = _client
        .from('places')
        .select()
        .eq('is_active', true);

    if (city != null && city.trim().isNotEmpty) {
      query = query.eq('city', city);
    }

    if (category != null &&
        category.trim().isNotEmpty &&
        category != 'Tümü') {
      query = query.eq(
        'category',
        category,
      );
    }

    final rows = await query
        .limit(limit);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(Place.fromMap)
        .toList();
  }

  /// Searches the database directly for places in a city, independent of the
  /// currently selected city and the size of the general search cache.
  Future<List<Place>> searchPlacesByCity(String city, {int limit = 500}) async {
    final value = city.trim();
    final normalized = normalizeSearchText(value);
    if (normalized.length < 3) return <Place>[];

    // Match province names in normalized form first. PostgreSQL ILIKE can
    // miss Turkish dotted/dotless-I variants depending on database collation
    // (for example, "istanbul" against a stored "İstanbul").
    const provinces = <String>[
      'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Amasya', 'Ankara',
      'Antalya', 'Artvin', 'Aydın', 'Balıkesir', 'Bilecik', 'Bingöl',
      'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı',
      'Çorum', 'Denizli', 'Diyarbakır', 'Edirne', 'Elazığ', 'Erzincan',
      'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane',
      'Hakkâri', 'Hatay', 'Isparta', 'Mersin', 'İstanbul', 'İzmir',
      'Kars', 'Kastamonu', 'Kayseri', 'Kırklareli', 'Kırşehir', 'Kocaeli',
      'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Kahramanmaraş', 'Mardin',
      'Muğla', 'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Rize', 'Sakarya',
      'Samsun', 'Siirt', 'Sinop', 'Sivas', 'Tekirdağ', 'Tokat', 'Trabzon',
      'Tunceli', 'Şanlıurfa', 'Uşak', 'Van', 'Yozgat', 'Zonguldak',
      'Aksaray', 'Bayburt', 'Karaman', 'Kırıkkale', 'Batman', 'Şırnak',
      'Bartın', 'Ardahan', 'Iğdır', 'Yalova', 'Karabük', 'Kilis',
      'Osmaniye', 'Düzce',
    ];

    final matchingProvince = provinces.cast<String?>().firstWhere(
      (province) => normalizeSearchText(province!) == normalized,
      orElse: () => null,
    );

    dynamic rows;
    if (matchingProvince != null) {
      final variants = <String>{
        matchingProvince,
        matchingProvince.toLowerCase(),
        matchingProvince.toUpperCase(),
        normalizeSearchText(matchingProvince),
      }.toList();
      rows = await _client
          .from('places')
          .select()
          .eq('is_active', true)
          .inFilter('city', variants)
          .limit(limit);
    } else {
      rows = await _client
          .from('places')
          .select()
          .eq('is_active', true)
          .ilike('city', '%$value%')
          .limit(limit);
    }

    return rows
        .whereType<Map<String, dynamic>>()
        .map(Place.fromMap)
        .toList();
  }

  Future<List<Place>> getPlacesByIds(
    Iterable<String> ids,
  ) async {
    final idList = ids.toList();

    if (idList.isEmpty) {
      return <Place>[];
    }

    final rows = await _client
        .from('places')
        .select()
        .inFilter('id', idList)
        .eq('is_active', true);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(Place.fromMap)
        .toList();
  }
}
