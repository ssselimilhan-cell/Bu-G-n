import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityEventsAdminScreen extends StatefulWidget {
  const CommunityEventsAdminScreen({super.key});
  @override
  State<CommunityEventsAdminScreen> createState() => _CommunityEventsAdminScreenState();
}

class _CommunityEventsAdminScreenState extends State<CommunityEventsAdminScreen> {
  final _client = Supabase.instance.client;
  final _searchController = TextEditingController();
  static const _allCities = 'Tüm şehirler';
  String _cityFilter = _allCities;
  bool _loading = true;
  String? _error;
  bool _saving = false;
  List<Map<String, dynamic>> _events = [];
  bool get _isAdmin => _client.auth.currentUser?.appMetadata['role'] == 'admin';

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }
  void _message(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    if (!_isAdmin) return;
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await _client.from('community_events')
          .select('id,creator_id,title,city,starts_at,meeting_point,description,invite_code,created_at')
          .order('starts_at', ascending: false).limit(500);
      if (!mounted) return;
      setState(() {
        _events = rows.whereType<Map<String, dynamic>>().toList();
        _loading = false;
        if (_cityFilter != _allCities && !_events.any((event) => event['city'] == _cityFilter)) {
          _cityFilter = _allCities;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Kullanıcı etkinlikleri yüklenemedi. 110 numaralı Supabase yönetici yetkileri migration kontrol edilmeli.';
      });
    }
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return date == null ? 'Tarih belirtilmemiş' : DateFormat('d MMM yyyy · HH:mm', 'tr_TR').format(date);
  }

  List<String> get _cities {
    final values = _events.map((event) => event['city']?.toString() ?? '').where((city) => city.isNotEmpty).toSet().toList()..sort();
    return [_allCities, ...values];
  }

  List<Map<String, dynamic>> get _visible {
    final query = _searchController.text.trim().toLowerCase();
    return _events.where((event) {
      if (_cityFilter != _allCities && event['city'] != _cityFilter) return false;
      if (query.isEmpty) return true;
      final searchable = [event['title'], event['city'], event['meeting_point'], event['description'], event['invite_code'], event['creator_id']]
          .whereType<Object>().join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  Future<void> _edit(Map<String, dynamic> event) async {
    final title = TextEditingController(text: event['title']?.toString() ?? '');
    final city = TextEditingController(text: event['city']?.toString() ?? '');
    final meeting = TextEditingController(text: event['meeting_point']?.toString() ?? '');
    final description = TextEditingController(text: event['description']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    DateTime startsAt = DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Kullanıcı etkinliğini düzenle'),
        content: SizedBox(width: 520, child: SingleChildScrollView(child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Etkinlik adı'),
            validator: (value) => value == null || value.trim().length < 3 || value.trim().length > 100 ? 'Etkinlik adı 3–100 karakter olmalı.' : null),
          TextFormField(controller: city, decoration: const InputDecoration(labelText: 'Şehir'),
            validator: (value) => value == null || value.trim().isEmpty ? 'Şehir boş bırakılamaz.' : null),
          TextFormField(controller: meeting, decoration: const InputDecoration(labelText: 'Buluşma noktası')),
          TextFormField(controller: description, decoration: const InputDecoration(labelText: 'Açıklama'), maxLines: 4),
          const SizedBox(height: 8),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Etkinlik tarihi ve saati'), subtitle: Text(_date(startsAt.toIso8601String())),
            onTap: () async {
              final date = await showDatePicker(context: context, initialDate: startsAt, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 3650)));
              if (date == null || !context.mounted) return;
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(startsAt));
              if (time == null) return;
              setDialogState(() => startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
            }),
          const SizedBox(height: 4),
          const Text('Davet kodu ve etkinlik sahibi bu ekrandan değiştirilemez.', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ])))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('VAZGEÇ')),
          FilledButton(onPressed: () { if (formKey.currentState?.validate() ?? false) Navigator.pop(dialogContext, true); }, child: const Text('KAYDET')),
        ],
      )),
    );
    if (saved != true || !mounted) {
      title.dispose(); city.dispose(); meeting.dispose(); description.dispose();
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await _client.from('community_events').update({
        'title': title.text.trim(), 'city': city.text.trim(),
        'starts_at': startsAt.toUtc().toIso8601String(),
        'meeting_point': meeting.text.trim().isEmpty ? null : meeting.text.trim(),
        'description': description.text.trim().isEmpty ? null : description.text.trim(),
      }).eq('id', event['id']).select('id');
      if (!mounted) return;
      if (updated.isEmpty) {
        _message('Etkinlik güncellenmedi. Yönetici UPDATE politikası ve izinleri kontrol edilmeli.');
      } else {
        _message('Kullanıcı etkinliği güncellendi.');
        await _load();
      }
    } catch (_) {
      _message('Etkinlik güncellenemedi. 110 numaralı Supabase migration ve RLS izinlerini kontrol et.');
    } finally {
      title.dispose(); city.dispose(); meeting.dispose(); description.dispose();
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> event) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Kullanıcı etkinliği silinsin mi?'),
      content: Text('" ${event['title']} " etkinliği kalıcı olarak silinecek. Bu etkinliğe verilmiş katılım yanıtları da silinir. Bu işlem geri alınamaz.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('VAZGEÇ')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(dialogContext, true), child: const Text('ETKİNLİĞİ SİL')),
      ],
    ));
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _client.from('community_events').delete().eq('id', event['id']);
      if (!mounted) return;
      setState(() { _events.removeWhere((item) => item['id'] == event['id']); _saving = false; });
      _message('Kullanıcı etkinliği silindi.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message('Etkinlik silinemedi. 110 numaralı Supabase migration ve RLS izinlerini kontrol et.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) return Scaffold(appBar: AppBar(title: const Text('Kullanıcı etkinlikleri')), body: const Center(child: Text('Bu alan yalnızca yöneticilere açıktır.')));
    final visible = _visible;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(title: const Text('KULLANICI ETKİNLİKLERİ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFF7F7F5), surfaceTintColor: Colors.transparent,
        actions: [IconButton(onPressed: _loading || _saving ? null : _load, icon: const Icon(Icons.refresh))]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: TextField(controller: _searchController,
          decoration: InputDecoration(labelText: 'Etkinlik, davet kodu veya kullanıcı ara', prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close)),
            border: const OutlineInputBorder(), filled: true, fillColor: Colors.white),
          onChanged: (_) => setState(() {}))),
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: DropdownButtonFormField<String>(
          value: _cityFilter, isExpanded: true, decoration: const InputDecoration(labelText: 'Şehir filtresi', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
          items: _cities.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: (value) { if (value != null) setState(() => _cityFilter = value); })),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator())
          : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
          : visible.isEmpty ? const Center(child: Text('Bu filtrede kullanıcı etkinliği bulunamadı.'))
          : ListView.separated(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final event = visible[index];
              final code = event['invite_code']?.toString() ?? '';
              return Card(color: Colors.white, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE8E8E5))),
                child: ExpansionTile(leading: const Icon(Icons.groups_outlined),
                  title: Text(event['title']?.toString() ?? 'İsimsiz etkinlik', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${event['city'] ?? 'Şehir yok'} · ${_date(event['starts_at'])}'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((event['meeting_point']?.toString() ?? '').isNotEmpty) Text('Buluşma noktası: ${event['meeting_point']}'),
                    if ((event['description']?.toString() ?? '').isNotEmpty) ...[const SizedBox(height: 6), Text(event['description'].toString())],
                    const SizedBox(height: 8),
                    SelectableText('Davet kodu: $code'),
                    const SizedBox(height: 4),
                    SelectableText('Oluşturan kullanıcı: ${event['creator_id']}'),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 4, alignment: WrapAlignment.end, children: [
                      OutlinedButton.icon(onPressed: _saving ? null : () => _edit(event), icon: const Icon(Icons.edit_outlined), label: const Text('Düzenle')),
                      TextButton.icon(onPressed: _saving ? null : () => _delete(event), icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Sil', style: TextStyle(color: Colors.red))),
                    ]),
                  ]));
            })),
        if (!_loading && _error == null) Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Text('${visible.length} etkinlik gösteriliyor', style: const TextStyle(fontSize: 11, color: Colors.black54))),
      ]),
    );
  }
}
