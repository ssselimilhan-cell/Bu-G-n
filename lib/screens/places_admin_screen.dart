import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlacesAdminScreen extends StatefulWidget {
  const PlacesAdminScreen({super.key});
  @override
  State<PlacesAdminScreen> createState() => _PlacesAdminScreenState();
}

class _PlacesAdminScreenState extends State<PlacesAdminScreen> {
  final _client = Supabase.instance.client;
  static const _cities = ['Adana','Adıyaman','Afyonkarahisar','Ağrı','Aksaray','Amasya','Ankara','Antalya','Ardahan','Artvin','Aydın','Balıkesir','Bartın','Batman','Bayburt','Bilecik','Bingöl','Bitlis','Bolu','Burdur','Bursa','Çanakkale','Çankırı','Çorum','Denizli','Diyarbakır','Düzce','Edirne','Elazığ','Erzincan','Erzurum','Eskişehir','Gaziantep','Giresun','Gümüşhane','Hakkâri','Hatay','Iğdır','Isparta','İstanbul','İzmir','Kahramanmaraş','Karabük','Karaman','Kars','Kastamonu','Kayseri','Kırıkkale','Kırklareli','Kırşehir','Kilis','Kocaeli','Konya','Kütahya','Malatya','Manisa','Mardin','Mersin','Muğla','Muş','Nevşehir','Niğde','Ordu','Osmaniye','Rize','Sakarya','Samsun','Şanlıurfa','Siirt','Sinop','Sivas','Şırnak','Tekirdağ','Tokat','Trabzon','Tunceli','Uşak','Van','Yalova','Yozgat','Zonguldak'];
  String _city = 'Ankara';
  bool _loading = false;
  List<Map<String, dynamic>> _places = [];
  bool get _isAdmin => _client.auth.currentUser?.appMetadata['role'] == 'admin';
  @override
  void initState() { super.initState(); _load(); }
  void _message(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
  Future<void> _load() async {
    if (!_isAdmin) return;
    setState(() => _loading = true);
    try {
      final rows = await _client.from('places').select('id,name,category,city,address,latitude,longitude,short_description,long_description,visit_duration_min,parking_available,is_free,kids_friendly,pet_friendly,indoor,outdoor,best_time,is_active,website,source_url').eq('city', _city).order('name').limit(1000);
      if (mounted) setState(() { _places = rows.whereType<Map<String, dynamic>>().toList(); _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); _message('Yerler yüklenemedi. Yönetici rolünü ve places tablosu izinlerini kontrol et.'); }
  }
  String? _empty(String value) => value.trim().isEmpty ? null : value.trim();
  Future<void> _edit(Map<String, dynamic> p) async {
    final controllers = <String, TextEditingController>{
      'name': TextEditingController(text: '${p['name'] ?? ''}'),
      'category': TextEditingController(text: '${p['category'] ?? ''}'),
      'address': TextEditingController(text: '${p['address'] ?? ''}'),
      'latitude': TextEditingController(text: '${p['latitude'] ?? ''}'),
      'longitude': TextEditingController(text: '${p['longitude'] ?? ''}'),
      'short_description': TextEditingController(text: '${p['short_description'] ?? ''}'),
      'long_description': TextEditingController(text: '${p['long_description'] ?? ''}'),
      'visit_duration_min': TextEditingController(text: '${p['visit_duration_min'] ?? ''}'),
      'best_time': TextEditingController(text: '${p['best_time'] ?? ''}'),
      'website': TextEditingController(text: '${p['website'] ?? ''}'),
      'source_url': TextEditingController(text: '${p['source_url'] ?? ''}'),
    };
    bool? parking = p['parking_available'] as bool?; bool? free = p['is_free'] as bool?; bool? kids = p['kids_friendly'] as bool?; bool? pets = p['pet_friendly'] as bool?; bool? indoor = p['indoor'] as bool?; bool? outdoor = p['outdoor'] as bool?; bool active = p['is_active'] != false;
    final key = GlobalKey<FormState>();
    Widget field(String id, String label, {bool required = false, bool number = false, int lines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextFormField(controller: controllers[id], maxLines: lines, keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true), validator: required ? (v) => v == null || v.trim().isEmpty ? 'Bu alan gerekli.' : null : null));
    Widget nullableBool(String label, bool? value, ValueChanged<bool?> changed, {String yes = 'Var', String no = 'Yok'}) => Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<bool?>(value: value, isExpanded: true, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true), items: [const DropdownMenuItem<bool?>(value: null, child: Text('Veri yok')), DropdownMenuItem<bool?>(value: true, child: Text(yes)), DropdownMenuItem<bool?>(value: false, child: Text(no))], onChanged: changed));
    final saved = await showDialog<bool>(context: context, builder: (dc) => StatefulBuilder(builder: (context, setD) => AlertDialog(title: Text('Yeri düzenle: ' + (p['name']?.toString() ?? '')), content: SizedBox(width: 560, height: MediaQuery.of(dc).size.height * 0.58, child: SingleChildScrollView(child: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, children: [field('name','Yer adı *',required:true),field('category','Kategori *',required:true),field('address','Adres'),Row(children:[Expanded(child:field('latitude','Enlem',number:true)),const SizedBox(width:8),Expanded(child:field('longitude','Boylam',number:true))]),field('short_description','Kısa açıklama',lines:3),field('long_description','Uzun açıklama',lines:4),field('visit_duration_min','Tahmini ziyaret süresi (dakika)',number:true),field('best_time','En uygun ziyaret zamanı'),field('website','Web sitesi'),field('source_url','Kaynak bağlantısı (yönetici alanı)'),nullableBool('Otopark',parking,(v)=>setD(()=>parking=v)),nullableBool('Ücret',free,(v)=>setD(()=>free=v),yes:'Ücretsiz',no:'Ücretli'),nullableBool('Çocuklar için uygun',kids,(v)=>setD(()=>kids=v),yes:'Uygun',no:'Uygun değil'),nullableBool('Evcil hayvan kabulü',pets,(v)=>setD(()=>pets=v),yes:'Uygun',no:'Uygun değil'),nullableBool('Kapalı alan',indoor,(v)=>setD(()=>indoor=v)),nullableBool('Açık alan',outdoor,(v)=>setD(()=>outdoor=v)),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Yayında'),value:active,onChanged:(v)=>setD(()=>active=v))])))), actions:[TextButton(onPressed:()=>Navigator.pop(dc,false),child:const Text('İPTAL')),FilledButton(onPressed:()=>key.currentState!.validate()?Navigator.pop(dc,true):null,child:const Text('KAYDET'))])));
    if (saved != true || !mounted) { for (final c in controllers.values) { c.dispose(); } return; }
    double? number(String id) => controllers[id]!.text.trim().isEmpty ? null : double.tryParse(controllers[id]!.text.trim().replaceAll(',', '.'));
    final lat = number('latitude'); final lng = number('longitude'); final durText = controllers['visit_duration_min']!.text.trim(); final duration = durText.isEmpty ? null : int.tryParse(durText);
    if ((controllers['latitude']!.text.trim().isNotEmpty && lat == null) || (controllers['longitude']!.text.trim().isNotEmpty && lng == null) || (durText.isNotEmpty && duration == null)) { _message('Koordinatları sayı, süreyi dakika cinsinden tam sayı gir.'); return; }
    if ((lat != null && (lat < -90 || lat > 90)) || (lng != null && (lng < -180 || lng > 180))) { _message('Koordinat aralığı geçersiz.'); return; }
    try {
      final updated = await _client.from('places').update({'name':controllers['name']!.text.trim(),'category':controllers['category']!.text.trim(),'address':_empty(controllers['address']!.text),'latitude':lat,'longitude':lng,'short_description':_empty(controllers['short_description']!.text),'long_description':_empty(controllers['long_description']!.text),'visit_duration_min':duration,'best_time':_empty(controllers['best_time']!.text),'website':_empty(controllers['website']!.text),'source_url':_empty(controllers['source_url']!.text),'parking_available':parking,'is_free':free,'kids_friendly':kids,'pet_friendly':pets,'indoor':indoor,'outdoor':outdoor,'is_active':active,'updated_at':DateTime.now().toUtc().toIso8601String()}).eq('id',p['id']).select('id,is_active');
      if (updated.isEmpty) {
        _message('Yer durumu değişmedi: Supabase güncelleme izni veya satır politikası kontrol edilmeli.');
        return;
      }
      _message('Yer bilgileri kaydedildi.'); await _load();
    } catch (_) { _message('Kaydedilemedi. Supabase places tablosu ve yönetici izinlerini kontrol et.'); }
    for (final c in controllers.values) { c.dispose(); }
  }
  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) return Scaffold(appBar: AppBar(title: const Text('Yer yönetimi')),body: const Center(child: Text('Bu alan yalnızca yöneticilere açıktır.')));
    return Scaffold(appBar: AppBar(title: const Text('Yer yönetimi'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),body:Column(children:[Padding(padding:const EdgeInsets.all(12),child:DropdownButtonFormField<String>(value:_city,isExpanded:true,decoration:const InputDecoration(labelText:'Şehir',border:OutlineInputBorder()),items:_cities.map((c)=>DropdownMenuItem(value:c,child:Text(c))).toList(),onChanged:(v){if(v!=null){setState(()=>_city=v);_load();}})),if(_loading) const Expanded(child:Center(child:CircularProgressIndicator())) else Expanded(child:_places.isEmpty?const Center(child:Text('Bu şehir için yer kaydı bulunamadı.')):ListView.separated(itemCount:_places.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(context,i){final p=_places[i];final coords=p['latitude']!=null&&p['longitude']!=null;return ListTile(title:Text(p['name']?.toString()??'İsimsiz yer'),subtitle:Text((p['category']?.toString()??'Diğer')+' • '+(coords?'Konum mevcut':'Konum eksik')+' • '+(p['is_active']==false?'Pasif':'Yayında')),trailing:const Icon(Icons.edit_outlined),onTap:()=>_edit(p));}))]));
  }
}