import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../services/saved_event_service.dart';
import 'event_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _client = Supabase.instance.client;
  final _savedEvents = SavedEventService();
  final _eventService = EventService();

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  List<Event> _events = [];
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _responses = [];
  List<Map<String, dynamic>> _notes = [];
  late final StreamSubscription<AuthState> _authSubscription;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  bool get _signedIn => _client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.signedOut) {
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ids = await _savedEvents.getSavedIds();
      final eventsFuture = _eventService.getEventsByIds(ids);
      final userId = _client.auth.currentUser?.id;
      final plansFuture = userId != null
          ? _client.from('community_events')
              .select('id,title,city,starts_at,meeting_point,description,creator_id')
              .eq('creator_id', userId)
              .order('starts_at')
              .limit(200)
          : Future.value(<Map<String, dynamic>>[]);
      final responsesFuture = userId != null
          ? _client.from('community_event_responses')
              .select('status,community_events!community_event_responses_event_id_fkey(id,title,city,starts_at,meeting_point,description,creator_id)')
              .eq('user_id', userId)
              .order('updated_at', ascending: false)
              .limit(200)
          : Future.value(<Map<String, dynamic>>[]);
      final notesFuture = userId != null
          ? _client.from('calendar_notes')
              .select('id,title,details,starts_at,ends_at,all_day')
              .eq('user_id', userId)
              .order('starts_at')
              .limit(500)
          : Future.value(<Map<String, dynamic>>[]);
      final results = await Future.wait<dynamic>([
        eventsFuture,
        plansFuture,
        responsesFuture,
        notesFuture,
      ]);
      if (!mounted) return;
      setState(() {
        _events = results[0] as List<Event>;
        _plans = (results[1] as List).whereType<Map<String, dynamic>>().toList();
        _responses = (results[2] as List).whereType<Map<String, dynamic>>().toList();
        _notes = (results[3] as List).whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Takvim verileri yüklenemedi. Bağlantını kontrol edip tekrar dene.';
      });
    }
  }

  DateTime? _eventDate(Event event) => event.startsAt.toLocal();
  DateTime? _planDate(Map<String, dynamic> plan) =>
      DateTime.tryParse(plan['starts_at']?.toString() ?? '')?.toLocal();
  DateTime? _noteDate(Map<String, dynamic> note) =>
      DateTime.tryParse(note['starts_at']?.toString() ?? '')?.toLocal();
  DateTime? _responseDate(Map<String, dynamic> response) {
    final event = response['community_events'];
    if (event is! Map<String, dynamic>) return null;
    return DateTime.tryParse(event['starts_at']?.toString() ?? '')?.toLocal();
  }

  String _responseLabel(String? status) => switch (status) {
        'yes' => 'Evet, katılacağım',
        'no' => 'Hayır, katılmayacağım',
        'maybe' => 'Belki katılacağım',
        _ => 'Yanıt kaydedildi',
      };

  bool _hasItems(DateTime day) {
    return _events.any((e) => _eventDate(e) != null && _sameDay(_eventDate(e)!, day)) ||
        _plans.any((p) => _planDate(p) != null && _sameDay(_planDate(p)!, day)) ||
        _responses.any((r) => _responseDate(r) != null && _sameDay(_responseDate(r)!, day)) ||
        _notes.any((n) => _noteDate(n) != null && _sameDay(_noteDate(n)!, day));
  }

  List<_CalendarEntry> _entriesForSelectedDay() {
    final entries = <_CalendarEntry>[];
    for (final event in _events) {
      final date = _eventDate(event);
      if (date != null && _sameDay(date, _selected)) {
        entries.add(_CalendarEntry(
          date: date,
          title: event.title,
          subtitle: event.venueName ?? event.category,
          kind: 'event',
          event: event,
        ));
      }
    }
    for (final plan in _plans) {
      final date = _planDate(plan);
      if (date != null && _sameDay(date, _selected)) {
        entries.add(_CalendarEntry(
          date: date,
          title: plan['title']?.toString() ?? 'Birlikte plan',
          subtitle: 'Birlikte plan · ${plan['city'] ?? ''}',
          kind: 'plan',
        ));
      }
    }
    for (final response in _responses) {
      final event = response['community_events'];
      if (event is! Map<String, dynamic>) continue;
      final date = _responseDate(response);
      if (date == null || !_sameDay(date, _selected)) continue;
      if (event['creator_id']?.toString() == _client.auth.currentUser?.id) continue;
      entries.add(_CalendarEntry(
        date: date,
        title: event['title']?.toString() ?? 'Davet etkinliği',
        subtitle: '${event['city'] ?? ''} · ${_responseLabel(response['status']?.toString())}',
        kind: 'response',
      ));
    }
    for (final note in _notes) {
      final date = _noteDate(note);
      if (date != null && _sameDay(date, _selected)) {
        entries.add(_CalendarEntry(
          date: date,
          title: note['title']?.toString() ?? 'Kişisel not',
          subtitle: note['details']?.toString() ?? '',
          kind: 'note',
          note: note,
        ));
      }
    }
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  void _changeMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _selected = DateTime(_month.year, _month.month, 1);
    });
  }

  Future<void> _editNote([Map<String, dynamic>? existing]) async {
    if (!_signedIn) {
      _message('Kişisel takvim notu eklemek için Profil bölümünden giriş yapmalısın.');
      return;
    }
    final title = TextEditingController(text: existing?['title']?.toString() ?? '');
    final details = TextEditingController(text: existing?['details']?.toString() ?? '');
    var startsAt = existing == null
        ? DateTime(_selected.year, _selected.month, _selected.day, 12)
        : DateTime.tryParse(existing['starts_at']?.toString() ?? '')?.toLocal() ?? _selected;
    var allDay = existing?['all_day'] == true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Takvim notu ekle' : 'Takvim notunu düzenle'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: title,
                autofocus: true,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Başlık *'),
              ),
              TextField(
                controller: details,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'Not / açıklama'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tüm gün'),
                value: allDay,
                onChanged: (value) => setDialogState(() => allDay = value),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Tarih'),
                subtitle: Text(DateFormat('d MMMM yyyy', 'tr_TR').format(startsAt)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startsAt,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() {
                    startsAt = DateTime(picked.year, picked.month, picked.day, startsAt.hour, startsAt.minute);
                  });
                },
              ),
              if (!allDay)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text('Saat'),
                  subtitle: Text(DateFormat('HH:mm').format(startsAt)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(startsAt),
                    );
                    if (picked != null) setDialogState(() {
                      startsAt = DateTime(startsAt.year, startsAt.month, startsAt.day, picked.hour, picked.minute);
                    });
                  },
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('İPTAL')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(existing == null ? 'KAYDET' : 'GÜNCELLE'),
            ),
          ],
        ),
      ),
    );

    final titleText = title.text.trim();
    final detailsText = details.text.trim();
    title.dispose();
    details.dispose();
    if (result != true || !mounted) return;
    if (titleText.isEmpty) {
      _message('Not başlığı boş bırakılamaz.');
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'user_id': _client.auth.currentUser!.id,
        'title': titleText,
        'details': detailsText.isEmpty ? null : detailsText,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'all_day': allDay,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (existing == null) {
        await _client.from('calendar_notes').insert(payload);
      } else {
        await _client.from('calendar_notes')
            .update(payload)
            .eq('id', existing['id'])
            .eq('user_id', _client.auth.currentUser!.id);
      }
      await _load();
      _message(existing == null ? 'Takvim notu eklendi.' : 'Takvim notu güncellendi.');
    } catch (_) {
      _message('Not kaydedilemedi. Takvim migration dosyasının uygulanması ve giriş durumu kontrol edilmeli.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteNote(Map<String, dynamic> note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not silinsin mi?'),
        content: Text('${note['title'] ?? 'Bu not'} silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('VAZGEÇ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('SİL')),
        ],
      ),
    );
    if (confirmed != true || !_signedIn) return;
    try {
      await _client.from('calendar_notes')
          .delete()
          .eq('id', note['id'])
          .eq('user_id', _client.auth.currentUser!.id);
      await _load();
      _message('Not silindi.');
    } catch (_) {
      _message('Not silinemedi.');
    }
  }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entriesForSelectedDay();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('TAKVİMİM', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'Not ekle',
            onPressed: _saving ? null : () => _editNote(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: const Text('TEKRAR DENE')),
                  ]),
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _buildMonthPicker(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, d MMMM', 'tr_TR').format(_selected),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (_signedIn)
                            TextButton.icon(
                              onPressed: _saving ? null : () => _editNote(),
                              icon: const Icon(Icons.note_add_outlined, size: 18),
                              label: const Text('Not ekle'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (!_signedIn)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text('Oluşturduğun planları ve kişisel notları hesabınla senkronize görmek için giriş yap.'),
                        ),
                      if (entries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(child: Text('Bu gün için takvim kaydı yok.')),
                        )
                      else
                        ...entries.map(_buildEntryCard),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMonthPicker() {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final offset = firstDay.weekday - DateTime.monday;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = ((offset + daysInMonth + 6) ~/ 7) * 7;
    const weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: [
        Row(children: [
          IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy', 'tr_TR').format(_month).toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5),
            ),
          ),
          IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
        ]),
        const SizedBox(height: 6),
        Row(children: weekdays.map((d) => Expanded(
          child: Center(child: Text(d, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade600))),
        )).toList()),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 1.05),
          itemBuilder: (context, index) {
            final dayNumber = index - offset + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox.shrink();
            final date = DateTime(_month.year, _month.month, dayNumber);
            final selected = _sameDay(date, _selected);
            final hasItems = _hasItems(date);
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _selected = date),
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$dayNumber', style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w900 : FontWeight.w600, color: selected ? Colors.white : Colors.black)),
                  const SizedBox(height: 3),
                  Container(
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      color: hasItems ? (selected ? Colors.white : const Color(0xFF2875B8)) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildEntryCard(_CalendarEntry entry) {
    final icon = entry.kind == 'event'
        ? Icons.event_outlined
        : entry.kind == 'plan' || entry.kind == 'response'
            ? Icons.groups_outlined
            : Icons.sticky_note_2_outlined;
    final label = entry.kind == 'event'
        ? 'KAYITLI ETKİNLİK'
        : entry.kind == 'plan'
            ? 'OLUŞTURDUĞUN PLAN'
            : entry.kind == 'response'
                ? 'KATILIM YANITI'
                : 'KİŞİSEL NOT';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9, letterSpacing: .7, fontWeight: FontWeight.w900, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(entry.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          if (entry.subtitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(entry.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
          const SizedBox(height: 5),
          Text(entry.note?['all_day'] == true ? 'Tüm gün' : DateFormat('HH:mm').format(entry.date),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ])),
        if (entry.event != null)
          IconButton(
            tooltip: 'Etkinlik detayını aç',
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
              builder: (_) => EventDetailScreen(event: entry.event!),
            )),
            icon: const Icon(Icons.chevron_right),
          ),
        if (entry.note != null)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _editNote(entry.note);
              if (value == 'delete') _deleteNote(entry.note!);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Düzenle')),
              PopupMenuItem(value: 'delete', child: Text('Sil')),
            ],
          ),
      ]),
    );
  }
}

class _CalendarEntry {
  final DateTime date;
  final String title;
  final String subtitle;
  final String kind;
  final Event? event;
  final Map<String, dynamic>? note;

  const _CalendarEntry({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.event,
    this.note,
  });
}
