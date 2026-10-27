import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TogetherEventScreen extends StatefulWidget {
  const TogetherEventScreen({super.key, required this.city});
  final String city;

  @override
  State<TogetherEventScreen> createState() => _TogetherEventScreenState();
}

class _TogetherEventScreenState extends State<TogetherEventScreen> {
  final _client = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;
  bool _saving = false;
  bool get _signedIn => _client.auth.currentUser != null;

  @override
  void initState() { super.initState(); _future = _load(); }
  @override
  void didUpdateWidget(covariant TogetherEventScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city) _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    if (!_signedIn) return [];
    final rows = await _client.from('community_events').select(
      'id,title,city,starts_at,meeting_point,description,invite_code,creator_id'
    ).eq('city', widget.city).eq('creator_id', _client.auth.currentUser!.id).order('starts_at').limit(100);
    return rows.whereType<Map<String, dynamic>>().toList();
  }

  String _newCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(7, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _deleteEvent(Map<String, dynamic> row) async {
    final id = row['id'];
    if (id == null) {
      _message('Etkinlik silinemedi: kayıt kimliği bulunamadı.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Etkinlik silinsin mi?'),
        content: Text('${row['title'] ?? 'Etkinlik'} etkinliğini ve davet kodunu silmek istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('VAZGEÇ')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('SİL')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _client.from('community_events')
          .delete()
          .eq('id', id)
          .eq('creator_id', _client.auth.currentUser!.id);
      if (!mounted) return;
      setState(() {
        _future = _load();
        _saving = false;
      });
      _message('Etkinlik silindi.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message('Etkinlik silinemedi. Bağlantını ve silme izinlerini kontrol et.');
    }
  }

  Future<void> _create([Map<String, dynamic>? existing]) async {
    if (!_signedIn) { _message('Etkinlik oluşturmak için Profil bölümünden giriş yapmalısın.'); return; }
    final key = GlobalKey<FormState>();
    final title = TextEditingController(text: existing?['title']?.toString() ?? '');
    final meeting = TextEditingController(text: existing?['meeting_point']?.toString() ?? '');
    final description = TextEditingController(text: existing?['description']?.toString() ?? '');
    DateTime startsAt = DateTime.tryParse(existing?['starts_at']?.toString() ?? '')?.toLocal() ?? DateTime.now().add(const Duration(days: 1));
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Birlikte etkinlik oluştur' : 'Etkinliği güncelle'),
        content: Form(key: key, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Etkinlik adı *'), validator: (v) => (v == null || v.trim().length < 3) ? 'En az 3 karakter gir.' : null),
          TextFormField(controller: meeting, decoration: const InputDecoration(labelText: 'Buluşma noktası')),
          TextFormField(controller: description, decoration: const InputDecoration(labelText: 'Açıklama'), maxLines: 3),
          const SizedBox(height: 10),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_month_outlined), title: const Text('Tarih ve saat'), subtitle: Text('${startsAt.day.toString().padLeft(2, '0')}.${startsAt.month.toString().padLeft(2, '0')}.${startsAt.year}  ${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}'), onTap: () async {
            final date = await showDatePicker(context: context, initialDate: startsAt, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (date == null || !context.mounted) return;
            final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(startsAt));
            if (time == null) return;
            setDialogState(() => startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
          }),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İPTAL')),
          FilledButton(onPressed: () { if (key.currentState!.validate()) Navigator.pop(dialogContext, {'title': title.text.trim(), 'meeting': meeting.text.trim(), 'description': description.text.trim(), 'starts_at': startsAt.toUtc().toIso8601String()}); }, child: Text(existing == null ? 'OLUŞTUR' : 'GÜNCELLE')),
        ],
      )),
    );
    title.dispose(); meeting.dispose(); description.dispose();
    if (values == null || !mounted) return;
    setState(() => _saving = true);
    final code = existing?['invite_code']?.toString() ?? _newCode();
    try {
      final payload = {
        'title': values['title'], 'city': widget.city,
        'starts_at': values['starts_at'],
        'meeting_point': (values['meeting'] as String).isEmpty ? null : values['meeting'],
        'description': (values['description'] as String).isEmpty ? null : values['description'],
      };
      if (existing == null) {
        payload['creator_id'] = _client.auth.currentUser!.id;
        payload['invite_code'] = code;
        await _client.from('community_events').insert(payload);
      } else {
        await _client.from('community_events').update(payload).eq('id', existing['id']).eq('creator_id', _client.auth.currentUser!.id);
      }
      if (!mounted) return;
      setState(() => _future = _load());
      if (existing == null) await showDialog<void>(context: context, builder: (context) => AlertDialog(
        title: const Text('Etkinlik oluşturuldu'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Davet kodun:'),
          const SizedBox(height: 10),
          SelectableText(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text('Kodu arkadaşlarına gönder. Kodu daha sonra bu listeden de görebilirsin.'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('KAPAT')),
          FilledButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: code)); Navigator.pop(context); _message('Davet kodu kopyalandı.'); }, icon: const Icon(Icons.copy), label: const Text('KODU KOPYALA')),
        ],
      ));
    } catch (_) {
      _message('Etkinlik oluşturulamadı. Girişini ve 011 numaralı Supabase migration\'ını kontrol et.');
    } finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _shareEvent(Map<String, dynamic> row) async {
    final code = row['invite_code']?.toString() ?? '';
    final date = DateTime.tryParse(row['starts_at']?.toString() ?? '')?.toLocal();
    final dateText = date == null ? 'Tarih belirtilmedi' : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final message = 'Seni BUGÜN uygulamasında oluşturduğum "${row['title']}" etkinliğine davet ediyorum! Cevap vermek için BUGÜN uygulamasında daveti aç.\\n\\nŞehir: ${row['city']}\\nTarih: $dateText\\nBuluşma noktası: ${row['meeting_point'] ?? 'Belirtilmedi'}\\nDavet kodu: $code\\n\\nUygulama: https://play.google.com/store/apps/details?id=tr.bugun.app';
    try {
      await Share.share(message, subject: 'BUGÜN etkinlik daveti');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: message));
      _message('Davet metni kopyalandı. İstediğin uygulamada paylaşabilirsin.');
    }
  }

  Future<void> _respondToEvent(Map<String, dynamic> row, String status) async {
    if (!_signedIn) {
      _message('Yanıt vermek için Profil bölümünden giriş yapmalısın.');
      return;
    }
    try {
      await _client.from('community_event_responses').upsert({
        'event_id': row['id'],
        'user_id': _client.auth.currentUser!.id,
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'event_id,user_id');
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).maybePop();
      _message('Katılım yanıtın kaydedildi.');
    } catch (_) {
      _message('Yanıt kaydedilemedi. Girişini ve bağlantını kontrol et.');
    }
  }

  Future<void> _findByCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Davet koduyla bul'),
      content: TextField(controller: controller, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Davet kodu')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('İPTAL')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim().toUpperCase()), child: const Text('BUL'))],
    ));
    controller.dispose();
    if (code == null || code.isEmpty || !mounted) return;
    try {
      final row = await _client.from('community_events').select('id,creator_id,title,city,starts_at,meeting_point,description,invite_code').eq('invite_code', code).maybeSingle();
      if (!mounted) return;
      if (row == null) { _message('Bu davet koduyla etkinlik bulunamadı.'); return; }
      await showDialog<void>(context: context, builder: (context) {
        final date = DateTime.tryParse(row['starts_at']?.toString() ?? '')?.toLocal();
        return AlertDialog(
          title: Text(row['title']?.toString() ?? 'Etkinlik'),
          content: Text('${row['city']}\\n${date == null ? '' : date.toString()}\\n${row['meeting_point'] ?? 'Buluşma noktası belirtilmemiş'}\\n\\n${row['description'] ?? ''}\\n\\nDavet kodu: ${row['invite_code']}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('KAPAT')),
            if (row['creator_id'] != _client.auth.currentUser?.id) ...[
              TextButton(onPressed: () => _respondToEvent(row, 'no'), child: const Text('HAYIR')),
              TextButton(onPressed: () => _respondToEvent(row, 'maybe'), child: const Text('BELKİ')),
              FilledButton(onPressed: () => _respondToEvent(row, 'yes'), child: const Text('EVET')),
            ],
          ],
        );
      });
    } catch (_) { _message('Davet aranamadı. Giriş yapıp tekrar dene.'); }
  }

  void _message(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
        Text('${widget.city} · Birlikte planla', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Arkadaşlarınla bir etkinlik planla, davet kodunu paylaş ve kodu daha sonra tekrar görüntüle.', style: TextStyle(height: 1.4)),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: _saving ? null : _create, icon: const Icon(Icons.group_add_outlined), label: Text(_saving ? 'Oluşturuluyor…' : 'Birlikte etkinlik oluştur / davet et')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _signedIn ? _findByCode : () => _message('Davet kodunu aramak için Profil bölümünden giriş yap.'), icon: const Icon(Icons.confirmation_number_outlined), label: const Text('Davet koduyla etkinlik bul')),
        const SizedBox(height: 22),
        const Text('ETKİNLİKLERİM VE DAVETLER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        if (!_signedIn)
          const Padding(padding: EdgeInsets.all(16), child: Text('Etkinlik oluşturmak ve davetlerini görmek için Profil bölümünden giriş yap.'))
        else
          FutureBuilder<List<Map<String, dynamic>>>(future: _future, builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
            if (snapshot.hasError) return const Text('Etkinlikler yüklenemedi. Aşağı çekerek yenileyebilirsin.');
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(12), child: Text('Henüz birlikte planladığın etkinlik yok.'));
            return Column(children: rows.map((row) {
              final date = DateTime.tryParse(row['starts_at']?.toString() ?? '')?.toLocal();
              final code = row['invite_code']?.toString() ?? '';
              return Card(color: Colors.white, child: ListTile(
                title: Text(row['title']?.toString() ?? 'Etkinlik', style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${date ?? ''}\nDavet kodu: $code\n${row['meeting_point'] ?? ''}'),
                isThreeLine: true,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(tooltip: 'Davet et', icon: const Icon(Icons.share_outlined), onPressed: () => _shareEvent(row)),
                IconButton(tooltip: 'Etkinliği güncelle', icon: const Icon(Icons.edit_outlined), onPressed: _saving ? null : () => _create(row)),
                IconButton(tooltip: 'Davet kodunu kopyala', icon: const Icon(Icons.copy), onPressed: () { Clipboard.setData(ClipboardData(text: code)); _message('Davet kodu kopyalandı.'); }),
                IconButton(tooltip: 'Etkinliği sil', icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _saving ? null : () => _deleteEvent(row)),
              ]),
              ));
            }).toList());
          }),
        ]),
      ),
    );
  }
}
