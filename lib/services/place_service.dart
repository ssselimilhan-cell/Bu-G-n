import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';

class PlaceService {
  final SupabaseClient _client = Supabase.instance.client;

  // A place is shown to users only when it has a usable map point and
  // its user-facing text does not contain uncertainty/verification warnings.
  // The same rule applies to all cities because all city lists use this service.
  static const List<String> _uncertaintyPhrases = [
    'teyit gerekli',
    'teyit edilmeli',
    'doğrulanmalıdır',
    'doğrulanmalı',
    'doğrulama bekliyor',
    'kontrol edilmeli',
    'kontrol edilmelidir',
    'yeniden kontrol edilmeli',
    'ziyarete açıklığı bilinmiyor',
    'ziyarete açık olup olmadığı bilinmiyor',
    'ziyaret durumu bilinmiyor',
    'erişilebilirliği bilinmiyor',
    'açılma durumu bilinmiyor',
    'ziyaretçi erişimi belirlenmeli',
    'erişim ayrıca belirlenmeli',
    'konum doğrulaması bekleyen',
    'kaynak doğrulaması bekleyen',
    'koordinat eksik',
  ];

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i');

  bool _isSuitableForPublicList(Place place) {
    if (place.latitude == null || place.longitude == null) return false;
    if (place.latitude! < -90 || place.latitude! > 90) return false;
    if (place.longitude! < -180 || place.longitude! > 180) return false;

    final visibleText = _normalize([
      place.name,
      place.address ?? '',
      place.shortDescription ?? '',
      place.longDescription ?? '',
      place.bestTime ?? '',
      ...place.tags,
    ].join(' '));
    return !_uncertaintyPhrases.any(
      (phrase) => visibleText.contains(_normalize(phrase)),
    );
  }

  Future<List<Place>> getPlaces({
    String city = 'Ankara',
    String? category,
    int limit = 50,
  }) async {
    var query = _client
        .from('places')
        .select()
        .ilike('city', city.trim())
        .eq('is_active', true)
        .not('latitude', 'is', null)
        .not('longitude', 'is', null);

    if (category != null &&
        category.trim().isNotEmpty &&
        category != 'Tümü') {
      query = query.eq('category', category);
    }

    final rows = await query.limit(limit);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(Place.fromMap)
        .where(_isSuitableForPublicList)
        .toList();
  }

  Future<List<Place>> getPlacesByIds(Iterable<String> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) return <Place>[];

    final rows = await _client
        .from('places')
        .select()
        .inFilter('id', idList)
        .eq('is_active', true)
        .not('latitude', 'is', null)
        .not('longitude', 'is', null);

    return rows
        .whereType<Map<String, dynamic>>()
        .map(Place.fromMap)
        .where(_isSuitableForPublicList)
        .toList();
  }
}
