class CityFood {
  final String id, city, name;
  final String? shortDescription, longDescription, whereToEat, venueName, venueAddress, mapUrl, imageUrl;
  final int sortOrder;
  final bool isActive;
  const CityFood({required this.id, required this.city, required this.name, this.shortDescription, this.longDescription, this.whereToEat, this.venueName, this.venueAddress, this.mapUrl, this.imageUrl, required this.sortOrder, required this.isActive});
  factory CityFood.fromMap(Map<String,dynamic> m) => CityFood(
    id:m['id'].toString(), city:m['city']?.toString()??'', name:m['name']?.toString()??'',
    shortDescription:m['short_description']?.toString(), longDescription:m['long_description']?.toString(),
    whereToEat:m['where_to_eat']?.toString(), venueName:m['venue_name']?.toString(),
    venueAddress:m['venue_address']?.toString(), mapUrl:m['map_url']?.toString(), imageUrl:m['image_url']?.toString(),
    sortOrder:(m['sort_order'] as num?)?.toInt()??1, isActive:m['is_active']!=false);
}
