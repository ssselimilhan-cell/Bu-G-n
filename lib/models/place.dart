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
    required this.id,
    required this.name,
    required this.category,
    this.placeType,
    required this.city,
    this.address,
    this.latitude,
    this.longitude,
    this.website,
    this.shortDescription,
    this.isFree,
    this.visitDurationMin,
    this.indoor,
    this.outdoor,
    this.parkingAvailable,
    this.kidsFriendly,
    this.petFriendly,
    this.difficultyLevel,
    this.bestTime,
    this.tags = const [],
    this.verified = false,
    this.trustScore = 0,
  });

  factory Place.fromMap(Map<String, dynamic> map) {
    final rawTags = map['tags'];

    return Place(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'Diğer',
      placeType: map['place_type'] as String?,
      city: map['city'] as String? ?? 'Ankara',
      address: map['address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      website: map['website'] as String?,
      shortDescription: map['short_description'] as String?,
      isFree: map['is_free'] as bool?,
      visitDurationMin: (map['visit_duration_min'] as num?)?.toInt(),
      indoor: map['indoor'] as bool?,
      outdoor: map['outdoor'] as bool?,
      parkingAvailable: map['parking_available'] as bool?,
      kidsFriendly: map['kids_friendly'] as bool?,
      petFriendly: map['pet_friendly'] as bool?,
      difficultyLevel: map['difficulty_level'] as String?,
      bestTime: map['best_time'] as String?,
      tags: rawTags is List
          ? rawTags.map((e) => e.toString()).toList()
          : const [],
      verified: map['verified'] as bool? ?? false,
      trustScore: (map['trust_score'] as num?)?.toInt() ?? 0,
    );
  }
}
