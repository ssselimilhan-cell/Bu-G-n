import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CityOffersAdminScreen extends StatefulWidget {
  const CityOffersAdminScreen({super.key});

  @override
  State<CityOffersAdminScreen> createState() => _CityOffersAdminScreenState();
}

class _CityOffersAdminScreenState extends State<CityOffersAdminScreen> {
  final _client = Supabase.instance.client;
  static const _cities = ["Adana","Adıyaman","Afyonkarahisar","Ağrı","Aksaray","Amasya","Ankara","Antalya","Ardahan","Artvin","Aydın","Balıkesir","Bartın","Batman","Bayburt","Bilecik","Bingöl","Bitlis","Bolu","Burdur","Bursa","Çanakkale","Çankırı","Çorum","Denizli","Diyarbakır","Düzce","Edirne","Elazığ","Erzincan","Erzurum","Eskişehir","Gaziantep","Giresun","Gümüşhane","Hakkâri","Hatay","Iğdır","Isparta","İstanbul","İzmir","Kahramanmaraş","Karabük","Karaman","Kars","Kastamonu","Kayseri","Kırıkkale","Kırklareli","Kırşehir","Kilis","Kocaeli","Konya","Kütahya","Malatya","Manisa","Mardin","Mersin","Muğla","Muş","Nevşehir","Niğde","Ordu","Osmaniye","Rize","Sakarya","Samsun","Şanlıurfa","Siirt","Sinop","Sivas","Şırnak","Tekirdağ","Tokat","Trabzon","Tunceli","Uşak","Van","Yalova","Yozgat","Zonguldak"];
  String _city = 'Ankara';
  String _filter = 'Tümü';
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];

  bool get _isAdmin => _client.auth.currentUser?.appMetadata['role'] == 'admin';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isAdmin) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      var query = _client.from('offers').select(
        'id,city,title,description,discount_text,source_url,image_url,advertiser_name,starts_at,ends_at,is_active,featured'
      ).eq('city', _city);
      if (_filter == 'Aktif') {
        query = query.eq('is_active', true);
      }
      if (_filter == 'Pasif') {
        query = query.eq('is_active', false);
      }
      final data = await query.order('created_at', ascending: false).limit(200);
      if (mounted) setState(() {
        _rows = data.whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _message('Fırsatlar yüklenemedi. Veritabanı güncellemesini kontrol et.');
      }
    }
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    final title = TextEditingController(text: row?['title']?.toString() ?? '');
    final advertiser = TextEditingController(text: row?['advertiser_name']?.toString() ?? '');
    final description = TextEditingController(text: row?['description']?.toString() ?? '');
    final discount = TextEditingController(text: row?['discount_text']?.toString() ?? '');
    final url = TextEditingController(text: row?['source_url']?.toString() ?? '');
    final image = TextEditingController(text: row?['image_url']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    var city = row?['city']?.toString() ?? _city;
    var featured = row?['featured'] == true;
    var active = row?['is_active'] != false;
    DateTime? starts = DateTime.tryParse(row?['starts_at']?.toString() ?? '')?.toLocal();
    DateTime? ends = DateTime.tryParse(row?['ends_at']?.toString() ?? '')?.toLocal();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text(row == null ? 'Yeni şehir fırsatı' : 'Fırsatı düzenle'),
        content: SizedBox(width: 520, child: SingleChildScrollView(child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(value: city, isExpanded: true, decoration: const InputDecoration(labelText: 'Şehir'), items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) { if (v != null) setDialogState(() => city = v); }),
            TextFormField(controller: advertiser, decoration: const InputDecoration(labelText: 'İşletme / reklamveren')),
            TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Fırsat başlığı *'), validator: (v) => (v == null || v.trim().length < 3) ? 'En az 3 karakter gir.' : null),
            TextFormField(controller: discount, decoration: const InputDecoration(labelText: 'İndirim / kampanya metni')),
            TextFormField(controller: description, decoration: const InputDecoration(labelText: 'Açıklama'), maxLines: 3),
            TextFormField(controller: url, decoration: const InputDecoration(labelText: 'Kampanya bağlantısı (isteğe bağlı, https:// önerilir)'), keyboardType: TextInputType.url),
            TextFormField(controller: image, decoration: const InputDecoration(labelText: 'Görsel bağlantısı (isteğe bağlı, https:// önerilir)'), keyboardType: TextInputType.url),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(context: context, initialDate: starts ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2100));
                if (picked != null) setDialogState(() => starts = DateTime(picked.year, picked.month, picked.day));
              },
              icon: const Icon(Icons.calendar_today), label: Text(starts == null ? 'Başlangıç tarihi seç (hemen)' : 'Başlangıç: ${_date(starts!)}'),
            )),
            Align(alignment: Alignment.centerLeft, child: TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(context: context, initialDate: ends ?? (starts ?? DateTime.now()).add(const Duration(days: 7)), firstDate: DateTime(2024), lastDate: DateTime(2100));
                if (picked != null) setDialogState(() => ends = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
              },
              icon: const Icon(Icons.event_busy), label: Text(ends == null ? 'Bitiş tarihi seç (süresiz)' : 'Bitiş: ${_date(ends!)}'),
            )),
            SwitchListTile(title: const Text('Yayında'), value: active, onChanged: (v) => setDialogState(() => active = v), contentPadding: EdgeInsets.zero),
            SwitchListTile(title: const Text('Öne çıkar'), subtitle: const Text('Şehir listesinin üstünde gösterilecek şekilde işaretler'), value: featured, onChanged: (v) => setDialogState(() => featured = v), contentPadding: EdgeInsets.zero),
          ]),
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('İPTAL')),
          FilledButton(onPressed: () {
            if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true);
          }, child: const Text('KAYDET')),
        ],
      )),
    );
    if (result == true && mounted) {
      try {
        final campaignUrl = url.text.trim();
        final imageUrl = image.text.trim();
        for (final link in [campaignUrl, imageUrl]) {
          if (link.isNotEmpty && !['http', 'https'].contains(Uri.tryParse(link)?.scheme)) {
            _message('Bağlantılar http:// veya https:// ile başlamalı.');
            return;
          }
        }
        final payload = {
          'city': city,
          'advertiser_name': advertiser.text.trim().isEmpty ? null : advertiser.text.trim(),
          'title': title.text.trim(),
          'description': description.text.trim().isEmpty ? null : description.text.trim(),
          'discount_text': discount.text.trim().isEmpty ? null : discount.text.trim(),
          'source_url': campaignUrl.isEmpty ? null : campaignUrl,
          'image_url': imageUrl.isEmpty ? null : imageUrl,
          'starts_at': starts?.toUtc().toIso8601String(),
          'ends_at': ends?.toUtc().toIso8601String(),
          'is_active': active,
          'featured': featured,
          'trust_score': 100,
        };
        if (row == null) {
          payload['created_by'] = _client.auth.currentUser!.id;
          await _client.from('offers').insert(payload);
        } else {
          payload['updated_at'] = DateTime.now().toUtc().toIso8601String();
          await _client.from('offers').update(payload).eq('id', row['id']);
        }
        _message('Fırsat kaydedildi.');
        await _load();
      } catch (_) {
        _message('Kaydedilemedi. Yönetici rolünü ve 012 numaralı veritabanı güncellemesini kontrol et.');
      }
    }
    title.dispose(); advertiser.dispose(); description.dispose(); discount.dispose(); url.dispose(); image.dispose();
  }

  Future<void> _deleteOffer(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Şehir fırsatı silinsin mi?'),
      content: Text('“${row['title'] ?? 'Fırsat'}” kalıcı olarak silinecek. Bu işlem geri alınamaz.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('VAZGEÇ')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('KALICI OLARAK SİL'))],
    ));
    if (confirmed != true || !mounted) return;
    try {
      await _client.from('offers').delete().eq('id', row['id']);
      _message('Şehir fırsatı silindi.');
      await _load();
    } catch (_) {
      _message('Silinemedi. Yönetici yetkisini ve veritabanı silme politikasını kontrol et.');
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> row) async {
    try {
      await _client.from('offers').update({
        'is_active': row['is_active'] != true,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', row['id']);
      await _load();
    } catch (_) {
      _message('Yayın durumu değiştirilemedi.');
    }
  }

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  void _message(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) return Scaffold(appBar: AppBar(title: const Text('Yönetici paneli')), body: const SafeArea(child: Center(child: Text('Bu bölüm yalnızca yöneticilere açıktır.'))));
    return Scaffold(
      appBar: AppBar(title: const Text('Şehir fırsatları yönetimi'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Yenile')]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Fırsat ekle')),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: DropdownButtonFormField<String>(
          value: _city, decoration: const InputDecoration(labelText: 'Yönetilecek şehir', border: OutlineInputBorder()),
          items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) { if (v != null) setState(() => _city = v); _load(); },
        )),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'Tümü', label: Text('Tümü')), ButtonSegment(value: 'Aktif', label: Text('Yayında')), ButtonSegment(value: 'Pasif', label: Text('Pasif'))],
          selected: {_filter}, onSelectionChanged: (s) { setState(() => _filter = s.first); _load(); },
        )),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _rows.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Bu şehir için henüz fırsat yok. Sağ alttaki düğmeyle ekleyebilirsin.', textAlign: TextAlign.center)))
          : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), itemCount: _rows.length, itemBuilder: (context, index) {
            final row = _rows[index];
            final active = row['is_active'] == true;
            final end = DateTime.tryParse(row['ends_at']?.toString() ?? '')?.toLocal();
            final expired = end != null && end.isBefore(DateTime.now());
            return Card(child: ListTile(
              leading: Icon(active && !expired ? Icons.campaign_outlined : Icons.pause_circle_outline, color: active && !expired ? Colors.green : Colors.grey),
              title: Text(row['title']?.toString() ?? 'Fırsat', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${row['advertiser_name'] ?? 'Reklamveren belirtilmedi'} · ${row['city']}\n${row['discount_text'] ?? ''}\n${expired ? 'Süresi dolmuş' : active ? 'Yayında / planlı' : 'Pasif'}'),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') _edit(row); if (v == 'toggle') _toggleActive(row); if (v == 'delete') _deleteOffer(row); }, itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Düzenle')), PopupMenuItem(value: 'toggle', child: Text(active ? 'Yayından kaldır' : 'Yayımla')), const PopupMenuItem(value: 'delete', child: Text('Sil'))]),
            ));
          })),
      ])),
    );
  }
}
