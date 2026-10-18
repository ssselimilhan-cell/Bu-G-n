import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/city_preference_service.dart';

class CommunityActivitiesScreen extends StatefulWidget {
  const CommunityActivitiesScreen({super.key});
  @override
  State<CommunityActivitiesScreen> createState() => _CommunityActivitiesScreenState();
}

class _CommunityActivitiesScreenState extends State<CommunityActivitiesScreen> {
  final _client = Supabase.instance.client;
  String _city = CityPreferenceService.defaultCity;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final city = await CityPreferenceService().getSelectedCity();
      final cutoff = DateTime.now().subtract(const Duration(hours: 2)).toUtc().toIso8601String();
      final cityRows = await _client.from('community_activities').select()
          .eq('city', city).eq('status', 'open')
          .gte('starts_at', cutoff)
          .order('starts_at').limit(100);

      final byId = <String, Map<String, dynamic>>{
        for (final row in cityRows.whereType<Map<String, dynamic>>())
          row['id'].toString(): row,
      };

      // Keep the user's own open activities visible even after they change
      // their selected city, so their invitation code remains accessible.
      final user = _client.auth.currentUser;
      if (user != null) {
        final ownRows = await _client.from('community_activities').select()
            .eq('host_user_id', user.id).eq('status', 'open')
            .gte('starts_at', cutoff)
            .order('starts_at').limit(100);
        for (final row in ownRows.whereType<Map<String, dynamic>>()) {
          byId[row['id'].toString()] = row;
        }
      }

      final mergedRows = byId.values.toList()
        ..sort((a, b) => (a['starts_at']?.toString() ?? '')
            .compareTo(b['starts_at']?.toString() ?? ''));
      if (!mounted) return;
      setState(() { _city = city; _items = mergedRows; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Topluluk etkinlikleri yüklenemedi. Veritabanı geçişi uygulanmış olmalı.'; });
    }
  }


  Future<void> _joinActivity(String activityId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _message('Etkinliğe katılmak için önce profilinden giriş yap.');
      return;
    }
    try {
      final existing = await _client.from('activity_participants')
          .select('status')
          .eq('activity_id', activityId)
          .eq('user_id', user.id)
          .maybeSingle();
      if (existing != null && existing['status'] == 'going') {
        _message('Bu etkinliğe zaten katılıyorsun.');
        return;
      }
      if (existing != null) {
        await _client.from('activity_participants').update({'status': 'going'})
            .eq('activity_id', activityId).eq('user_id', user.id);
      } else {
        await _client.from('activity_participants').insert({
          'activity_id': activityId,
          'user_id': user.id,
          'status': 'going',
        });
      }
      _message('Etkinliğe katılımın kaydedildi.');
    } catch (_) {
      _message('Katılım kaydedilemedi. Etkinlik başlamış veya kapanmış olabilir.');
    }
  }

  Future<void> _joinByCode() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _message('Davet kodunu kullanmak için önce profilinden giriş yap.');
      return;
    }
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Davet koduyla katıl'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            labelText: 'Etkinlik kodu',
            hintText: 'Arkadaşının paylaştığı kod',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('VAZGEÇ')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('BUL')),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.trim().isEmpty) return;
    try {
      final activity = await _client.from('community_activities')
          .select('id, title, city, status, starts_at')
          .eq('invite_code', code.trim().toLowerCase())
          .eq('status', 'open')
          .maybeSingle();
      if (activity == null) {
        _message('Bu davet koduyla açık bir etkinlik bulunamadı.');
        return;
      }
      await _joinActivity(activity['id'].toString());
      await _load();
    } catch (_) {
      _message('Davet kodu kontrol edilemedi. Tekrar dene.');
    }
  }

  Future<void> _create() async {
    final user = _client.auth.currentUser;
    if (user == null) { _message('Etkinlik oluşturmak için önce profilinden giriş yap.'); return; }
    final title = TextEditingController();
    final description = TextEditingController();
    final venue = TextEditingController();
    final address = TextEditingController();
    final cost = TextEditingController();
    final capacity = TextEditingController(text: '8');
    String type = 'Spor';
    bool free = false;
    DateTime date = DateTime.now().add(const Duration(days: 1));
    TimeOfDay time = const TimeOfDay(hour: 18, minute: 30);
    bool busy = false;

    final created = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.of(context).viewInsets.bottom + 18),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Birlikte bir şey yapalım', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text('$_city içinde bowling, yürüyüş, oyun veya başka bir buluşma oluştur.'),
              const SizedBox(height: 14),
              TextField(controller: title, maxLength: 120, decoration: const InputDecoration(labelText: 'Etkinlik adı *', hintText: 'Bowling akşamı', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type, decoration: const InputDecoration(labelText: 'Etkinlik türü', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Spor', child: Text('Spor / oyun')),
                  DropdownMenuItem(value: 'Doğa', child: Text('Doğa / yürüyüş')),
                  DropdownMenuItem(value: 'Yeme-İçme', child: Text('Yeme-içme')),
                  DropdownMenuItem(value: 'Kültür', child: Text('Kültür / sanat')),
                  DropdownMenuItem(value: 'Aile', child: Text('Aile etkinliği')),
                  DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
                ],
                onChanged: (v) { if (v != null) setSheet(() => type = v); },
              ),
              const SizedBox(height: 8),
              TextField(controller: description, maxLines: 3, maxLength: 3000, decoration: const InputDecoration(labelText: 'Açıklama', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: venue, decoration: const InputDecoration(labelText: 'Mekân / işletme', hintText: 'Bowling salonu', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Adres (isteğe bağlı)', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(DateFormat('d MMM yyyy', 'tr_TR').format(date)),
                  onPressed: () async {
                    final v = await showDatePicker(context: context, initialDate: date.isBefore(DateTime.now()) ? DateTime.now().add(const Duration(days: 1)) : date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (v != null) setSheet(() => date = DateTime(v.year, v.month, v.day, time.hour, time.minute));
                  },
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule), label: Text(time.format(context)),
                  onPressed: () async {
                    final v = await showTimePicker(context: context, initialTime: time);
                    if (v != null) setSheet(() { time = v; date = DateTime(date.year, date.month, date.day, v.hour, v.minute); });
                  },
                )),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kişi sınırı', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: cost, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Kişi başı ücret (₺)', border: OutlineInputBorder()))),
              ]),
              CheckboxListTile(contentPadding: EdgeInsets.zero, value: free, onChanged: (v) => setSheet(() => free = v ?? false), title: const Text('Ücretsiz etkinlik'), controlAffinity: ListTileControlAffinity.leading),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                icon: const Icon(Icons.group_add_outlined), label: Text(busy ? 'OLUŞTURULUYOR…' : 'OLUŞTUR VE DAVET ET'),
                onPressed: busy ? null : () async {
                  if (title.text.trim().length < 3) { _message('Etkinlik adına en az 3 karakter yaz.'); return; }
                  if (!date.isAfter(DateTime.now())) { _message('Etkinlik zamanı gelecekte olmalı.'); return; }
                  setSheet(() => busy = true);
                  try {
                    final row = await _client.from('community_activities').insert({
                      'host_user_id': user.id, 'title': title.text.trim(), 'description': description.text.trim(),
                      'city': _city, 'venue': venue.text.trim().isEmpty ? null : venue.text.trim(),
                      'address': address.text.trim().isEmpty ? null : address.text.trim(),
                      'activity_type': type, 'starts_at': date.toUtc().toIso8601String(),
                      'capacity': int.tryParse(capacity.text.trim()),
                      'estimated_cost': free ? 0 : num.tryParse(cost.text.trim().replaceAll(',', '.')),
                      'is_free': free,
                    }).select().single();
                    if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                    final venueText = venue.text.trim();
                    final addressText = address.text.trim();
                    await Share.share(
                      'Seni BUGÜN üzerinden bir etkinliğe davet ediyorum!\n\n'
                      '${row['title']}\n${row['city']} · ${DateFormat('d MMM yyyy · HH:mm', 'tr_TR').format(date)}\n'
                      '${venueText.isEmpty ? '' : '$venueText\n'}${addressText.isEmpty ? '' : '$addressText\n'}'
                      '${description.text.trim()}\n\nEtkinlik kodu: ${row['invite_code']}\n'
                      'BUGÜN uygulamasındaki “Birlikte yapalım” bölümünden buluşalım.',
                      subject: title.text.trim(),
                    );
                  } catch (_) {
                    setSheet(() => busy = false);
                    _message('Etkinlik kaydedilemedi. Girişini ve veritabanı geçişini kontrol et.');
                  }
                },
              )),
            ],
          )),
        ),
      ),
    );
    title.dispose(); description.dispose(); venue.dispose(); address.dispose(); cost.dispose(); capacity.dispose();
    if (created == true && mounted) { _message('Etkinlik oluşturuldu. Davet metnini paylaşabilirsin.'); await _load(); }
  }

  Future<void> _share(Map<String, dynamic> item) async {
    final rawDate = DateTime.tryParse(item['starts_at']?.toString() ?? '')?.toLocal();
    await Share.share(
      'Seni BUGÜN üzerinden bir etkinliğe davet ediyorum!\n\n'
      '${item['title']}\n${item['city']} · ${rawDate == null ? '' : DateFormat('d MMM yyyy · HH:mm', 'tr_TR').format(rawDate)}\n'
      '${item['venue'] ?? ''}\n${item['address'] ?? ''}\n${item['description'] ?? ''}\n\n'
      'Etkinlik kodu: ${item['invite_code']}\nBUGÜN uygulamasındaki “Birlikte yapalım” bölümünden buluşalım.',
      subject: item['title']?.toString() ?? 'BUGÜN etkinliği',
    );
  }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Birlikte yapalım', style: TextStyle(fontWeight: FontWeight.w800)),
      actions: [IconButton(tooltip: 'Davet koduyla katıl', onPressed: _joinByCode, icon: const Icon(Icons.vpn_key_outlined))],
    ),
    floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Etkinlik oluştur')),
    body: _loading ? const Center(child: CircularProgressIndicator())
      : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('Tekrar dene'))])))
      : RefreshIndicator(onRefresh: _load, child: _items.isEmpty
        ? ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(28), children: [
            const SizedBox(height: 70), const Icon(Icons.groups_2_outlined, size: 58), const SizedBox(height: 16),
            const Text('Henüz topluluk etkinliği yok', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8), Text('$_city içinde bowling, yürüyüş veya oyun buluşması başlat. İlk etkinliği sen oluşturup arkadaşlarını davet edebilirsin.', textAlign: TextAlign.center),
            const SizedBox(height: 18), Center(child: FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('İlk etkinliği oluştur'))),
          ])
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _items[index];
              final start = DateTime.tryParse(item['starts_at']?.toString() ?? '')?.toLocal();
              return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['activity_type']?.toString().toUpperCase() ?? 'TOPLULUK', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54)),
                const SizedBox(height: 5), Text(item['title']?.toString() ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                if ((item['description']?.toString() ?? '').trim().isNotEmpty) ...[const SizedBox(height: 8), Text(item['description'].toString())],
                const SizedBox(height: 8), Text('📅 ${start == null ? 'Tarih belirtilmedi' : DateFormat('EEEE d MMMM · HH:mm', 'tr_TR').format(start)}'),
                if ((item['venue']?.toString() ?? '').isNotEmpty) Text('📍 ${item['venue']}'),
                if ((item['address']?.toString() ?? '').isNotEmpty) Text(item['address'].toString()),
                if (_client.auth.currentUser?.id == item['host_user_id'] &&
                    (item['invite_code']?.toString() ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3EF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE1E3DC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.key_outlined, size: 17),
                        const SizedBox(width: 8),
                        const Text('Davet kodun', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(
                            item['invite_code'].toString().toUpperCase(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Davet kodunu kopyala',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.copy_outlined, size: 19),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: item['invite_code'].toString()));
                            _message('Davet kodu kopyalandı.');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(item['is_free'] == true ? 'Ücretsiz' : (item['estimated_cost'] == null ? 'Ücret belirtilmedi' : 'Tahmini kişi başı: ₺${item['estimated_cost']}'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    OutlinedButton.icon(onPressed: () => _joinActivity(item['id'].toString()), icon: const Icon(Icons.check_circle_outline, size: 17), label: const Text('Katıl')),
                    OutlinedButton.icon(onPressed: () => _share(item), icon: const Icon(Icons.share_outlined, size: 17), label: const Text('Davet et')),
                  ],
                ),
              ]));
            },
          )),
  );
}
