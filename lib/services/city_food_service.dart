import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/city_food.dart';
class CityFoodService {
  final SupabaseClient _db=Supabase.instance.client;
  Future<List<CityFood>> getPublishedFoods(String city) async {
    final rows=await _db.from('city_foods').select('id,city,name,short_description,long_description,where_to_eat,venue_name,venue_address,map_url,image_url,sort_order,is_active').ilike('city',city.trim()).eq('is_active',true).order('sort_order');
    return rows.whereType<Map<String,dynamic>>().map(CityFood.fromMap).toList();
  }

  Future<void> submitSuggestion({required String city, required String foodName, String? note}) async {
    await _db.from('city_food_suggestions').insert({
      'city': city.trim(), 'food_name': foodName.trim(),
      'note': (note ?? '').trim().isEmpty ? null : note!.trim(),
      'user_id': _db.auth.currentUser?.id,
    });
  }
}
