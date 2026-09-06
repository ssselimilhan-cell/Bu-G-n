class Event {
  final String id;
  final String title;
  final String category;
  final String? description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? venueName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? priceMin;
  final double? priceMax;
  final String? imageUrl;
  final int trustScore;
  final double recommendationScore;

  const Event({
    required this.id,
    required this.title,
    required this.category,
    required this.startsAt,
    this.description,
    this.endsAt,
    this.venueName,
    this.address,
    this.latitude,
    this.longitude,
    this.priceMin,
    this.priceMax,
    this.imageUrl,
    this.trustScore = 0,
    this.recommendationScore = 0,
  });

  factory Event.fromMap(Map<String, dynamic> map) => Event(
        id: map['id'] as String,
        title: map['title'] as String,
        category: map['category'] as String,
        description: map['description'] as String?,
        startsAt: DateTime.parse(map['starts_at'] as String),
        endsAt: map['ends_at'] == null ? null : DateTime.parse(map['ends_at'] as String),
        venueName: map['venue_name'] as String?,
        address: map['address'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        priceMin: (map['price_min'] as num?)?.toDouble(),
        priceMax: (map['price_max'] as num?)?.toDouble(),
        imageUrl: map['image_url'] as String?,
        trustScore: (map['trust_score'] as num?)?.toInt() ?? 0,
        recommendationScore: (map['recommendation_score'] as num?)?.toDouble() ?? 0,
      );
}
