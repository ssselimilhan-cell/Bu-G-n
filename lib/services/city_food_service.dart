import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/city_food.dart';
class CityFoodService {
  final SupabaseClient _db=Supabase.instance.client;
  Future<List<CityFood>> getPublishedFoods(String city) async {
    final rows=await _db.from('city_foods').select('id,city,name,short_description,long_description,where_to_eat,venue_name,venue_address,map_url,image_url,sort_order,is_active').ilike('city',city.trim()).eq('is_active',true).order('sort_order').limit(5);
    return rows.whereType<Map<String,dynamic>>().map(CityFood.fromMap).toList();
  }
}
