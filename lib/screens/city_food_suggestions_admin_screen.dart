import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CityFoodSuggestionsAdminScreen extends StatefulWidget {
  const CityFoodSuggestionsAdminScreen({super.key});
  @override State<CityFoodSuggestionsAdminScreen> createState() => _CityFoodSuggestionsAdminScreenState();
}
class _CityFoodSuggestionsAdminScreenState extends State<CityFoodSuggestionsAdminScreen> {
  final _db = Supabase.instance.client;
  bool _loading = true; String? _error; List<Map<String,dynamic>> _rows = [];
  bool get _admin => _db.auth.currentUser?.appMetadata['role'] == 'admin';
  @override void initState() { super.initState(); _load(); }
  void _msg(String value) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value))); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try { final data = await _db.from('city_food_suggestions').select('id,city,food_name,note,created_at').eq('status','pending').order('created_at'); if (mounted) setState(() => _rows = data.whereType<Map<String,dynamic>>().toList()); }
    catch (_) { if (mounted) setState(() => _error = 'Öneriler yüklenemedi. 113 numaralı migration ve yönetici iznini kontrol et.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _publish(Map<String,dynamic> row) async {
    try {
      final last = await _db.from('city_foods').select('sort_order').eq('city',row['city']).order('sort_order',ascending:false).limit(1).maybeSingle();
      final next = ((last?['sort_order'] as num?)?.toInt() ?? 0) + 1;
      await _db.from('city_foods').insert({'city':row['city'],'name':row['food_name'],'short_description':row['note'],'sort_order':next,'is_active':true});
      await _db.from('city_food_suggestions').update({'status':'reviewed'}).eq('id',row['id']);
      _msg('Öneri yayımlandı.'); await _load();
    } catch (_) { _msg('Öneri yayımlanamadı. Kayıt ve yönetici izinlerini kontrol et.'); }
  }
  Future<void> _dismiss(Map<String,dynamic> row) async {
    try { await _db.from('city_food_suggestions').delete().eq('id',row['id']); _msg('Öneri kaldırıldı.'); await _load(); }
    catch (_) { _msg('Öneri silinemedi.'); }
  }
  @override Widget build(BuildContext context) {
    if (!_admin) return Scaffold(appBar: AppBar(title: const Text('Yemek önerileri')),body: const Center(child: Text('Bu alan yalnızca yöneticilere açıktır.')));
    return Scaffold(appBar: AppBar(title: const Text('Kullanıcı yemek önerileri'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),body:_loading?const Center(child:CircularProgressIndicator()):_error!=null?Center(child:Text(_error!,textAlign:TextAlign.center)): _rows.isEmpty?const Center(child:Text('Bekleyen yemek önerisi yok.')):ListView.separated(padding:const EdgeInsets.all(12),itemCount:_rows.length,separatorBuilder:(_,__)=>const Divider(),itemBuilder:(context,index){final row=_rows[index];return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(row['food_name']?.toString()??'İsimsiz yemek',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),Text(row['city']?.toString()??'',style:const TextStyle(color:Color(0xFF1268B3),fontWeight:FontWeight.w700)),if((row['note']??'').toString().trim().isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(row['note'].toString())),const SizedBox(height:10),Row(mainAxisAlignment:MainAxisAlignment.end,children:[TextButton(onPressed:()=>_dismiss(row),child:const Text('REDDET')),FilledButton.icon(onPressed:()=>_publish(row),icon:const Icon(Icons.publish),label:const Text('YAYIMLA'))])])));}) );
  }
}
