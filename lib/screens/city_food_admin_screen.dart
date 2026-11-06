import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CityFoodAdminScreen extends StatefulWidget {
  const CityFoodAdminScreen({super.key});
  @override State<CityFoodAdminScreen> createState()=>_CityFoodAdminScreenState();
}
class _CityFoodAdminScreenState extends State<CityFoodAdminScreen> {
  final _db=Supabase.instance.client;
  static const _cities=['Adana','Adıyaman','Afyonkarahisar','Ağrı','Aksaray','Amasya','Ankara','Antalya','Ardahan','Artvin','Aydın','Balıkesir','Bartın','Batman','Bayburt','Bilecik','Bingöl','Bitlis','Bolu','Burdur','Bursa','Çanakkale','Çankırı','Çorum','Denizli','Diyarbakır','Düzce','Edirne','Elazığ','Erzincan','Erzurum','Eskişehir','Gaziantep','Giresun','Gümüşhane','Hakkâri','Hatay','Iğdır','Isparta','İstanbul','İzmir','Kahramanmaraş','Karabük','Karaman','Kars','Kastamonu','Kayseri','Kırıkkale','Kırklareli','Kırşehir','Kilis','Kocaeli','Konya','Kütahya','Malatya','Manisa','Mardin','Mersin','Muğla','Muş','Nevşehir','Niğde','Ordu','Osmaniye','Rize','Sakarya','Samsun','Şanlıurfa','Siirt','Sinop','Sivas','Şırnak','Tekirdağ','Tokat','Trabzon','Tunceli','Uşak','Van','Yalova','Yozgat','Zonguldak'];
  String _city='Ankara'; bool _loading=true; String? _error; List<Map<String,dynamic>> _rows=[];
  bool get _admin=>_db.auth.currentUser?.appMetadata['role']=='admin';
  @override void initState(){super.initState();_load();}
  void _msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
  Future<void> _load() async {
    if(!_admin){setState(()=>_loading=false);return;}
    setState(()=>{_loading=true;_error=null;});
    try{final data=await _db.from('city_foods').select('id,city,name,short_description,long_description,where_to_eat,venue_name,venue_address,map_url,image_url,sort_order,is_active').eq('city',_city).order('sort_order');
      if(mounted)setState(()=>_rows=data.whereType<Map<String,dynamic>>().toList());
    }catch(_){if(mounted)setState(()=>_error='Yemek kayıtları alınamadı. 113 numaralı migration ve yönetici iznini kontrol et.');}
    finally{if(mounted)setState(()=>_loading=false);}
  }
  int _nextAvailableOrder() {
    final used=_rows.map((r)=>(r['sort_order'] as num?)?.toInt()).toSet();
    return used.whereType<int>().fold<int>(0, (maxValue, value) => value > maxValue ? value : maxValue) + 1;
  }
  Future<void> _move(int index,int delta) async {
    final other=index+delta;
    if(other<0||other>=_rows.length)return;
    try {
      await _db.rpc('swap_city_food_order',params:{
        'p_food_a':_rows[index]['id'],
        'p_food_b':_rows[other]['id'],
      });
      await _load();
    } catch (_) {
      _msg('Sıralama değiştirilemedi. 113 numaralı migration uygulanmış olmalı.');
    }
  }
  String? _nil(String s)=>s.trim().isEmpty?null:s.trim();
  Future<void> _edit([Map<String,dynamic>? row]) async {
    final c=<String,TextEditingController>{
      'name':TextEditingController(text:row?['name']?.toString()??''),
      'short':TextEditingController(text:row?['short_description']?.toString()??''),
      'long':TextEditingController(text:row?['long_description']?.toString()??''),
      'where':TextEditingController(text:row?['where_to_eat']?.toString()??''),
      'venue':TextEditingController(text:row?['venue_name']?.toString()??''),
      'address':TextEditingController(text:row?['venue_address']?.toString()??''),
      'map':TextEditingController(text:row?['map_url']?.toString()??''),
      'image':TextEditingController(text:row?['image_url']?.toString()??''),
    };
    final key=GlobalKey<FormState>(); int order=(row?['sort_order'] as num?)?.toInt()??_nextAvailableOrder(); bool active=row?['is_active']!=false;
    Widget field(String id,String label,{bool required=false,int lines=1})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextFormField(controller:c[id],maxLines:lines,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder(),isDense:true),validator:required?(v)=>v==null||v.trim().isEmpty?'Bu alan gerekli.':null:null));
    final ok=await showDialog<bool>(context:context,builder:(dc)=>StatefulBuilder(builder:(context,ss)=>AlertDialog(
      title:Text(row==null?'Yeni yemek ekle':'Yemek kaydını düzenle'),
      content:SizedBox(width:540,height:MediaQuery.of(dc).size.height*.68,child:SingleChildScrollView(child:Form(key:key,child:Column(mainAxisSize:MainAxisSize.min,children:[
        field('name','Yemek adı *',required:true),
        field('short','Listede yemek adının altında görünecek kısa bilgi',lines:2),
        field('long','Yemek hakkında detaylı bilgi',lines:5),
        const Divider(height:22),
        field('where','NEREDE YENİR? açıklaması',lines:5),
        field('venue','Mekân adı'),
        field('address','Adres / konum açıklaması',lines:2),
        field('map','Harita bağlantısı'),
        field('image','Görsel bağlantısı (isteğe bağlı)'),
        const Padding(padding:EdgeInsets.only(bottom:8),child:Align(alignment:Alignment.centerLeft,child:Text('Sıralama, kayıttan sonra yukarı/aşağı oklarıyla yapılır.',style:TextStyle(fontSize:12,color:Colors.black54)))),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Yayında'),value:active,onChanged:(v)=>ss(()=>active=v)),
      ])))),
      actions:[TextButton(onPressed:()=>Navigator.pop(dc,false),child:const Text('İPTAL')),FilledButton(onPressed:()=>key.currentState!.validate()?Navigator.pop(dc,true):null,child:const Text('KAYDET'))],
    )));
    if(ok!=true||!mounted){for(final x in c.values){x.dispose();}return;}
    final payload=<String,dynamic>{'city':_city,'name':c['name']!.text.trim(),'short_description':_nil(c['short']!.text),'long_description':_nil(c['long']!.text),'where_to_eat':_nil(c['where']!.text),'venue_name':_nil(c['venue']!.text),'venue_address':_nil(c['address']!.text),'map_url':_nil(c['map']!.text),'image_url':_nil(c['image']!.text),'sort_order':order,'is_active':active,'updated_at':DateTime.now().toUtc().toIso8601String()};
    try{if(row==null){await _db.from('city_foods').insert(payload);}else{await _db.from('city_foods').update(payload).eq('id',row['id']);}_msg('Yemek kaydı kaydedildi.');await _load();}
    on PostgrestException catch(e){_msg(e.code=='23505'?'Bu şehirde ${order}. sıra zaten dolu. Başka bir sıra seç.':'Kaydedilemedi: ${e.message}');}
    catch(_){_msg('Kaydedilemedi. Yönetici iznini ve 113 numaralı migration durumunu kontrol et.');}
    finally{for(final x in c.values){x.dispose();}}
  }
  Future<void> _delete(Map<String,dynamic> row) async {
    final yes=await showDialog<bool>(context:context,builder:(dc)=>AlertDialog(title:const Text('Yemek kaydı silinsin mi?'),content:Text('" ${row['name']}" kaydı kalıcı olarak silinecek.'),actions:[TextButton(onPressed:()=>Navigator.pop(dc,false),child:const Text('VAZGEÇ')),FilledButton(onPressed:()=>Navigator.pop(dc,true),child:const Text('SİL'))]));
    if(yes!=true)return;try{await _db.from('city_foods').delete().eq('id',row['id']);_msg('Yemek kaydı silindi.');await _load();}catch(_){_msg('Kayıt silinemedi.');}
  }
  @override Widget build(BuildContext context){
    if(!_admin)return Scaffold(appBar:AppBar(title:const Text('Ne Yenir? yönetimi')),body:const Center(child:Text('Bu alan yalnızca yöneticilere açıktır.')));
    return Scaffold(appBar:AppBar(title:const Text('Yönetici paneli · Ne Yenir?'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),
      floatingActionButton:FloatingActionButton.extended(onPressed:()=>_edit(),icon:const Icon(Icons.add),label:const Text('Yemek ekle')),
      body:Column(children:[
        Padding(padding:const EdgeInsets.all(12),child:DropdownButtonFormField<String>(value:_city,isExpanded:true,decoration:const InputDecoration(labelText:'Şehir',border:OutlineInputBorder()),items:_cities.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v){if(v!=null){setState(()=>_city=v);_load();}})),
        if(_loading)const Expanded(child:Center(child:CircularProgressIndicator()))
        else if(_error!=null)Expanded(child:Center(child:Padding(padding:const EdgeInsets.all(24),child:Text(_error!,textAlign:TextAlign.center))))
        else Expanded(child:_rows.isEmpty?const Center(child:Text('Bu şehir için henüz yemek eklenmemiş.')):ListView.separated(itemCount:_rows.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(context,i){final r=_rows[i];return ListTile(leading:CircleAvatar(child:Text('${r['sort_order']}')),title:Text(r['name']?.toString()??'İsimsiz yemek',style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(r['is_active']==false?'Yayında değil':'Yayında'),onTap:()=>_edit(r),trailing:Row(mainAxisSize:MainAxisSize.min,children:[IconButton(tooltip:'Yukarı taşı',icon:const Icon(Icons.keyboard_arrow_up),onPressed:i==0?null:()=>_move(i,-1)),IconButton(tooltip:'Aşağı taşı',icon:const Icon(Icons.keyboard_arrow_down),onPressed:i==_rows.length-1?null:()=>_move(i,1)),IconButton(tooltip:'Sil',icon:const Icon(Icons.delete_outline),onPressed:()=>_delete(r))]));})),
        if(!_loading&&_error==null)Padding(padding:const EdgeInsets.fromLTRB(16,0,16,12),child:Text('${_rows.length} yemek kaydı · Sınır yok',style:const TextStyle(color:Colors.black54,fontSize:12))),
      ]));
  }
}
