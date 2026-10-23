class Place {
  final String id;
  final String name;
  final String category;
  final String? placeType;
  final String city;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? website;
  final String? shortDescription;
  final String? longDescription;
  final String? sourceUrl;
  final DateTime? verifiedAt;
  final String? contentReviewStatus;
  final bool? isFree;
  final int? visitDurationMin;
  final bool? indoor;
  final bool? outdoor;
  final bool? parkingAvailable;
  final bool? kidsFriendly;
  final bool? petFriendly;
  final String? difficultyLevel;
  final String? bestTime;
  final List<String> tags;
  final bool verified;
  final int trustScore;

  const Place({
    required this.id, required this.name, required this.category,
    this.placeType, required this.city, this.address, this.latitude,
    this.longitude, this.website, this.shortDescription, this.longDescription,
    this.sourceUrl, this.verifiedAt, this.contentReviewStatus, this.isFree,
    this.visitDurationMin, this.indoor, this.outdoor, this.parkingAvailable,
    this.kidsFriendly, this.petFriendly, this.difficultyLevel, this.bestTime,
    this.tags = const [], this.verified = false, this.trustScore = 0,
  });

  static String _str(dynamic value, [String fallback = '']) =>
      value == null ? fallback : value.toString();

  static String? _nullable(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static double? _double(dynamic value) {
    if (value is num) return value.toDouble();
    return value is String ? double.tryParse(value.trim()) : null;
  }

  static int? _int(dynamic value) {
    if (value is num) return value.toInt();
    return value is String ? int.tryParse(value.trim()) : null;
  }

  static bool? _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true': case '1': case 'yes': case 'evet': return true;
        case 'false': case '0': case 'no': case 'hayır': return false;
      }
    }
    return null;
  }

  factory Place.fromMap(Map<String, dynamic> map) {
    final rawTags = map['tags'];
    return Place(
      id: _str(map['id']), name: _str(map['name'], 'İsimsiz yer'),
      category: _str(map['category'], 'Diğer'),
      placeType: _nullable(map['place_type']), city: _str(map['city'], 'Ankara'),
      address: _nullable(map['address']), latitude: _double(map['latitude']),
      longitude: _double(map['longitude']), website: _nullable(map['website']),
      shortDescription: _nullable(map['short_description']),
      longDescription: _nullable(map['long_description']),
      sourceUrl: _nullable(map['source_url']),
      verifiedAt: map['verified_at'] == null ? null : DateTime.tryParse(map['verified_at'].toString()),
      contentReviewStatus: _nullable(map['content_review_status']),
      isFree: _bool(map['is_free']), visitDurationMin: _int(map['visit_duration_min']),
      indoor: _bool(map['indoor']), outdoor: _bool(map['outdoor']),
      parkingAvailable: _bool(map['parking_available']), kidsFriendly: _bool(map['kids_friendly']),
      petFriendly: _bool(map['pet_friendly']), difficultyLevel: _nullable(map['difficulty_level']),
      bestTime: _nullable(map['best_time']),
      tags: rawTags is List ? rawTags.map((e) => e.toString()).toList() : const [],
      verified: _bool(map['verified']) ?? false, trustScore: _int(map['trust_score']) ?? 0,
    );
  }
}
