import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventsAdminScreen extends StatefulWidget {
  const EventsAdminScreen({super.key});
  @override
  State<EventsAdminScreen> createState() => _EventsAdminScreenState();
}

class _EventsAdminScreenState extends State<EventsAdminScreen> {
  final _db = Supabase.instance.client;
  final _search = TextEditingController();
  static const _cities = ['Adana','Adıyaman','Afyonkarahisar','Ağrı','Aksaray','Amasya','Ankara','Antalya','Ardahan','Artvin','Aydın','Balıkesir','Bartın','Batman','Bayburt','Bilecik','Bingöl','Bitlis','Bolu','Burdur','Bursa','Çanakkale','Çankırı','Çorum','Denizli','Diyarbakır','Düzce','Edirne','Elazığ','Erzincan','Erzurum','Eskişehir','Gaziantep','Giresun','Gümüşhane','Hakkâri','Hatay','Iğdır','Isparta','İstanbul','İzmir','Kahramanmaraş','Karabük','Karaman','Kars','Kastamonu','Kayseri','Kırıkkale','Kırklareli','Kırşehir','Kilis','Kocaeli','Konya','Kütahya','Malatya','Manisa','Mardin','Mersin','Muğla','Muş','Nevşehir','Niğde','Ordu','Osmaniye','Rize','Sakarya','Samsun','Şanlıurfa','Siirt','Sinop','Sivas','Şırnak','Tekirdağ','Tokat','Trabzon','Tunceli','Uşak','Van','Yalova','Yozgat','Zonguldak'];
  String _city = 'Tüm şehirler', _scope = 'Tümü';
  bool _loading = true, _saving = false;
  String? _error;
  List<Map<String,dynamic>> _rows = [];
  bool get _admin => _db.auth.currentUser?.appMetadata['role'] == 'admin';

  @override
  void initState() { super.initState(); _search.addListener(_refresh); _load(); }
  @override
  void dispose() { _search.removeListener(_refresh); _search.dispose(); super.dispose(); }
  void _refresh() => setState(() {});
  void _msg(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s))); }
  String _date(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '')?.toLocal();
    return d == null ? 'Tarih yok' : DateFormat('d MMM yyyy · HH:mm','tr_TR').format(d);
  }
  Future<void> _load() async {
    if (!_admin) { setState(() { _loading=false; _error='Bu ekran yalnızca yöneticilere açıktır.'; }); return; }
    setState(() { _loading=true; _error=null; });
    try {
      final data = await _db.from('events').select('id,title,category,city,description,starts_at,ends_at,venue_name,venue_address,latitude,longitude,price_min,price_max,image_url,ticket_url,source_url,source_id,external_id,external_source,is_active,admin_managed,is_featured').order('is_featured',ascending:false).order('starts_at').limit(1000);
      if (mounted) setState(() { _rows=data.whereType<Map<String,dynamic>>().toList(); _loading=false; });
    } catch (_) {
      if (mounted) setState(() { _loading=false; _error='Etkinlikler yüklenemedi. 112 numaralı Supabase migration uygulanmamış veya yönetici yetkisi eksik olabilir.'; });
    }
  }
  List<Map<String,dynamic>> get _visible {
    final q=_search.text.trim().toLowerCase();
    return _rows.where((r) {
      final managed=r['admin_managed']==true;
      if (_city!='Tüm şehirler' && r['city']!=_city) return false;
      if (_scope=='BUGÜN tarafından eklenenler' && !managed) return false;
      if (_scope=='Dış kaynak etkinlikleri' && managed) return false;
      return q.isEmpty || [r['title'],r['city'],r['category'],r['venue_name'],r['venue_address']].whereType<Object>().join(' ').toLowerCase().contains(q);
    }).toList();
  }
  Future<void> _feature(Map<String,dynamic> r) async {
    final next=r['is_featured']!=true;
    try { await _db.from('events').update({'is_featured':next}).eq('id',r['id']); if(mounted) setState(()=>r['is_featured']=next); _msg(next?'Etkinlik öne çıkarıldı.':'Öne çıkarma kaldırıldı.'); }
    catch (_) { _msg('Öne çıkarma değiştirilemedi. Migration ve yönetici iznini kontrol et.'); }
  }
  String? _empty(String s)=>s.trim().isEmpty?null:s.trim();
  double? _num(String s)=>s.trim().isEmpty?null:double.tryParse(s.trim().replaceAll(',','.'));

  Future<void> _edit([Map<String,dynamic>? row]) async {
    final c=<String,TextEditingController>{
      'title':TextEditingController(text:row?['title']?.toString()??''),
      'category':TextEditingController(text:row?['category']?.toString()??'other'),
      'venue':TextEditingController(text:row?['venue_name']?.toString()??''),
      'address':TextEditingController(text:row?['venue_address']?.toString()??''),
      'description':TextEditingController(text:row?['description']?.toString()??''),
      'image':TextEditingController(text:row?['image_url']?.toString()??''),
      'ticket':TextEditingController(text:row?['ticket_url']?.toString()??''),
      'source':TextEditingController(text:row?['source_url']?.toString()??''),
      'lat':TextEditingController(text:row?['latitude']?.toString()??''),
      'lon':TextEditingController(text:row?['longitude']?.toString()??''),
      'min':TextEditingController(text:row?['price_min']?.toString()??''),
      'max':TextEditingController(text:row?['price_max']?.toString()??''),
    };
    final key=GlobalKey<FormState>();
    String city=row?['city']?.toString()??'Ankara';
    bool active=row?['is_active']!=false, featured=row?['is_featured']==true;
    DateTime start=DateTime.tryParse(row?['starts_at']?.toString()??'')?.toLocal()??DateTime.now().add(const Duration(days:1));
    DateTime? end=DateTime.tryParse(row?['ends_at']?.toString()??'')?.toLocal();
    final ok=await showDialog<bool>(context:context,builder:(dc)=>StatefulBuilder(builder:(context,ss)=>AlertDialog(
      title:Text(row==null?'Yeni etkinlik':'Etkinliği düzenle'),
      content:SizedBox(width:520,child:SingleChildScrollView(child:Form(key:key,child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextFormField(controller:c['title'],decoration:const InputDecoration(labelText:'Etkinlik adı *'),validator:(v)=>v==null||v.trim().length<3?'En az 3 karakter gir.':null),
        DropdownButtonFormField<String>(value:city,isExpanded:true,decoration:const InputDecoration(labelText:'Şehir'),items:_cities.map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v){if(v!=null)ss(()=>city=v);}),
        TextFormField(controller:c['category'],decoration:const InputDecoration(labelText:'Kategori *'),validator:(v)=>v==null||v.trim().isEmpty?'Kategori gerekli.':null),
        TextFormField(controller:c['venue'],decoration:const InputDecoration(labelText:'Mekân / yer adı')),
        TextFormField(controller:c['address'],decoration:const InputDecoration(labelText:'Adres')),
        ListTile(contentPadding:EdgeInsets.zero,title:const Text('Başlangıç tarihi'),subtitle:Text(_date(start.toIso8601String())),onTap:()async{final d=await showDatePicker(context:context,initialDate:start,firstDate:DateTime(2020),lastDate:DateTime(2100));if(d==null||!context.mounted)return;final t=await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(start));if(t!=null)ss(()=>start=DateTime(d.year,d.month,d.day,t.hour,t.minute));}),
        ListTile(contentPadding:EdgeInsets.zero,title:const Text('Bitiş tarihi (isteğe bağlı)'),subtitle:Text(end==null?'Belirtilmedi':_date(end!.toIso8601String())),onTap:()async{final d=await showDatePicker(context:context,initialDate:end??start,firstDate:DateTime(2020),lastDate:DateTime(2100));if(d==null||!context.mounted)return;final t=await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(end??start));if(t!=null)ss(()=>end=DateTime(d.year,d.month,d.day,t.hour,t.minute));}),
        TextFormField(controller:c['description'],decoration:const InputDecoration(labelText:'Açıklama'),maxLines:3),
        TextFormField(controller:c['image'],decoration:const InputDecoration(labelText:'Görsel URL'),keyboardType:TextInputType.url),
        TextFormField(controller:c['ticket'],decoration:const InputDecoration(labelText:'Bilet / kayıt URL'),keyboardType:TextInputType.url),
        TextFormField(controller:c['source'],decoration:const InputDecoration(labelText:'Kaynak URL'),keyboardType:TextInputType.url),
        Row(children:[Expanded(child:TextFormField(controller:c['lat'],decoration:const InputDecoration(labelText:'Enlem'),keyboardType:const TextInputType.numberWithOptions(decimal:true))),const SizedBox(width:8),Expanded(child:TextFormField(controller:c['lon'],decoration:const InputDecoration(labelText:'Boylam'),keyboardType:const TextInputType.numberWithOptions(decimal:true)))]),
        Row(children:[Expanded(child:TextFormField(controller:c['min'],decoration:const InputDecoration(labelText:'En düşük fiyat'),keyboardType:const TextInputType.numberWithOptions(decimal:true))),const SizedBox(width:8),Expanded(child:TextFormField(controller:c['max'],decoration:const InputDecoration(labelText:'En yüksek fiyat'),keyboardType:const TextInputType.numberWithOptions(decimal:true)))]),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Yayında'),value:active,onChanged:(v)=>ss(()=>active=v)),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Öne çıkar'),value:featured,onChanged:(v)=>ss(()=>featured=v)),
      ])))),
      actions:[TextButton(onPressed:()=>Navigator.pop(dc,false),child:const Text('VAZGEÇ')),FilledButton(onPressed:(){if(key.currentState?.validate()??false)Navigator.pop(dc,true);},child:const Text('KAYDET'))],
    )));
    if(ok==true && mounted){
      setState(()=>_saving=true);
      try{
        final payload=<String,dynamic>{'title':c['title']!.text.trim(),'category':c['category']!.text.trim(),'city':city,'description':_empty(c['description']!.text),'starts_at':start.toUtc().toIso8601String(),'ends_at':end?.toUtc().toIso8601String(),'venue_name':_empty(c['venue']!.text),'venue_address':_empty(c['address']!.text),'image_url':_empty(c['image']!.text),'ticket_url':_empty(c['ticket']!.text),'source_url':_empty(c['source']!.text),'latitude':_num(c['lat']!.text),'longitude':_num(c['lon']!.text),'price_min':_num(c['min']!.text),'price_max':_num(c['max']!.text),'is_active':active,'is_featured':featured};
        if(row==null){payload['admin_managed']=true;payload['external_source']='BUGÜN yönetici paneli';await _db.from('events').insert(payload);}
        else{await _db.from('events').update(payload).eq('id',row['id']).eq('admin_managed',true);}
        await _load();_msg(row==null?'Etkinlik eklendi.':'Etkinlik güncellendi.');
      }catch(_){_msg('Kaydedilemedi. 112 numaralı migration ve zorunlu alanları kontrol et.');}
      finally{if(mounted)setState(()=>_saving=false);}
    }
    for(final x in c.values){x.dispose();}
  }

  Future<void> _delete(Map<String,dynamic> row) async {
    final yes=await showDialog<bool>(context:context,builder:(dc)=>AlertDialog(title:const Text('Etkinlik silinsin mi?'),content:Text('"' + (row['title']?.toString()??'Etkinlik') + '" kalıcı olarak silinecek.'),actions:[TextButton(onPressed:()=>Navigator.pop(dc,false),child:const Text('VAZGEÇ')),FilledButton(onPressed:()=>Navigator.pop(dc,true),child:const Text('SİL'))]));
    if(yes!=true)return;
    try{await _db.from('events').delete().eq('id',row['id']).eq('admin_managed',true);await _load();_msg('Etkinlik silindi.');}catch(_){_msg('Etkinlik silinemedi.');}
  }

  @override
  Widget build(BuildContext context){
    if(!_admin)return Scaffold(appBar:AppBar(title:const Text('Etkinlik yönetimi')),body:const Center(child:Text('Bu ekran yalnızca yöneticilere açıktır.')));
    final rows=_visible;
    return Scaffold(appBar:AppBar(title:const Text('Etkinlik yönetimi'),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),
      floatingActionButton:FloatingActionButton.extended(onPressed:_saving?null:()=>_edit(),icon:const Icon(Icons.add),label:const Text('Etkinlik ekle')),
      body:Column(children:[
        Padding(padding:const EdgeInsets.all(14),child:Column(children:[
          TextField(controller:_search,decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Etkinlik, şehir veya mekân ara')),
          const SizedBox(height:8),
          Row(children:[
            Expanded(child:DropdownButtonFormField<String>(value:_city,isExpanded:true,decoration:const InputDecoration(labelText:'Şehir'),items:['Tüm şehirler',..._cities].map((v)=>DropdownMenuItem(value:v,child:Text(v,overflow:TextOverflow.ellipsis))).toList(),onChanged:(v)=>setState(()=>_city=v??'Tüm şehirler'))),
            const SizedBox(width:8),
            Expanded(child:DropdownButtonFormField<String>(value:_scope,isExpanded:true,decoration:const InputDecoration(labelText:'Kayıt türü'),items:['Tümü','BUGÜN tarafından eklenenler','Dış kaynak etkinlikleri'].map((v)=>DropdownMenuItem(value:v,child:Text(v,overflow:TextOverflow.ellipsis))).toList(),onChanged:(v)=>setState(()=>_scope=v??'Tümü'))),
          ]),
        ])),
        if(_error!=null)Padding(padding:const EdgeInsets.all(12),child:Text(_error!,style:const TextStyle(color:Colors.red))),
        if(_loading)const Expanded(child:Center(child:CircularProgressIndicator()))
        else Expanded(child:RefreshIndicator(onRefresh:_load,child:rows.isEmpty?ListView(children:const [SizedBox(height:100),Center(child:Text('Etkinlik bulunamadı.'))]):ListView.separated(padding:const EdgeInsets.fromLTRB(14,4,14,90),itemCount:rows.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(context,i){
          final r=rows[i], managed=r['admin_managed']==true, featured=r['is_featured']==true;
          return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[Expanded(child:Text(r['title']?.toString()??'Etkinlik',style:const TextStyle(fontWeight:FontWeight.w800))),if(featured)const Chip(label:Text('ÖNE ÇIKAN'),visualDensity:VisualDensity.compact)]),
            Text((r['city']?.toString()??'')+' · '+(r['category']?.toString()??''),style:Theme.of(context).textTheme.bodySmall),
            Text(_date(r['starts_at']),style:Theme.of(context).textTheme.bodySmall),
            Text(managed?'BUGÜN tarafından eklenen':'Dış kaynak · içerik alanları korunur',style:const TextStyle(fontSize:11,color:Colors.black54)),
            Wrap(spacing:4,children:[
              TextButton.icon(onPressed:()=>_feature(r),icon:Icon(featured?Icons.star:Icons.star_border),label:Text(featured?'Öne çıkarmayı kaldır':'Öne çıkar')),
              if(managed)TextButton.icon(onPressed:_saving?null:()=>_edit(r),icon:const Icon(Icons.edit_outlined),label:const Text('Düzenle')),
              if(managed)TextButton.icon(onPressed:()=>_delete(r),icon:const Icon(Icons.delete_outline),label:const Text('Sil')),
            ]),
          ])));
        }))),
      ]),
    );
  }
}
