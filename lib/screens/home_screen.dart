import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = EventService();
  late Future<List<Event>> _events;

  @override
  void initState() {
    super.initState();
    _events = _service.getTodayEvents();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateText = DateFormat('d MMMM EEEE', 'tr_TR').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BUGÜN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1)),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.person_outline))],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _events = _service.getTodayEvents()),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text('Ankara · $dateText', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            const Text('Ankara\'da bugün ne var?', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.05)),
            const SizedBox(height: 20),
            _WeatherCard(),
            const SizedBox(height: 24),
            const Text('BUGÜN NE VAR?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              '🎵 Konser','🎭 Tiyatro','⚽ Maç','🍔 Fırsat','🖼 Sergi','🌳 Doğa','🆓 Ücretsiz','✨ Yeni'
            ].map((x) => Chip(label: Text(x))).toList()),
            const SizedBox(height: 28),
            const Text('SANA ÖZEL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 12),
            FutureBuilder<List<Event>>(
              future: _events,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Text('İçerik yüklenemedi: ${snapshot.error}');
                }
                final events = snapshot.data ?? [];
                if (events.isEmpty) return const Text('Bugün için henüz içerik bulunamadı.');
                return Column(children: events.take(10).map((e) => _EventCard(event: e)).toList());
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(selectedIndex: 0, destinations: const [
        NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'BUGÜN'),
        NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Keşfet'),
        NavigationDestination(icon: Icon(Icons.bookmark_border), label: 'Kayıt'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
      ]),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.white),
    child: const Row(children: [
      Text('☀️', style: TextStyle(fontSize: 34)),
      SizedBox(width: 14),
      Expanded(child: Text('Bugün şehirde güzel bir gün var.\nAkşam için planını seç.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
    ]),
  );
}

class _EventCard extends StatelessWidget {
  final Event event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: Container(width: 60, height: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.black12), child: event.imageUrl == null ? const Icon(Icons.event) : null),
      title: Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text('${event.category} · ${DateFormat('HH:mm').format(event.startsAt)}${event.venueName == null ? '' : ' · ${event.venueName}'}'),
      trailing: event.recommendationScore > 0 ? Text('%${event.recommendationScore.round()}', style: const TextStyle(fontWeight: FontWeight.w900)) : null,
    ),
  );
}
