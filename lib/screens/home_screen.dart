import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import 'event_detail_screen.dart';
import 'explore_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventService _service = EventService();
  late Future<List<Event>> _events;

  static const _categories = [
    _Category('🎵', 'Konser'),
    _Category('🎭', 'Tiyatro'),
    _Category('⚽', 'Maç'),
    _Category('🍔', 'Fırsat'),
    _Category('🖼', 'Sergi'),
    _Category('🌳', 'Doğa'),
    _Category('🆓', 'Ücretsiz'),
    _Category('✨', 'Yeni'),
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    _events = _service.getTodayEvents();
  }

  Future<void> _refresh() async {
    setState(_loadEvents);
    await _events;
  }

  Future<void> _openCategory(String category) async {
    final events = await _events;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExploreScreen(events: events, initialCategory: category),
      ),
    );
  }

  Future<void> _openExplore() async {
    final events = await _events;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExploreScreen(events: events)),
    );
  }

  void _openEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<Event>>(
            future: _events,
            builder: (context, snapshot) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    sliver: SliverToBoxAdapter(child: _buildHeader()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    sliver: const SliverToBoxAdapter(child: _WeatherCard()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    sliver: SliverToBoxAdapter(child: _buildCategories()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _sectionHeader('BUGÜNÜN ÖNERİSİ', 'Senin için seçtik'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildFeatured(snapshot),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _sectionHeader('SANA ÖZEL', 'Bugün sana uygun'),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildList(snapshot),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _featureCard(
                        Icons.local_offer_outlined,
                        'Bugünün fırsatları',
                        'Restoran, kafe ve mağazalardan kampanyalar',
                        () => _openCategory('Fırsat'),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _featureCard(
                        Icons.free_breakfast_outlined,
                        'Bugün ücretsiz',
                        'Ankara\'da para harcamadan yapabileceğin şeyler',
                        () => _openCategory('Ücretsiz'),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                    sliver: SliverToBoxAdapter(
                      child: _featureCard(
                        Icons.auto_awesome_outlined,
                        'Yeni açılanlar',
                        'Şehirde yeni keşfedilecek mekanlar',
                        () => _openCategory('Yeni'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 0,
        height: 70,
        onDestinationSelected: (index) {
          if (index == 1) _openExplore();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'BUGÜN'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Keşfet'),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'Kayıt'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BUGÜN', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.8)),
              SizedBox(height: 10),
              Text('Ankara\'da bugün ne var?', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline_rounded)),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BUGÜN NE VAR?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        const SizedBox(height: 13),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final c = _categories[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openCategory(c.name),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(children: [
                      Text(c.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 7),
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
        GestureDetector(
          onTap: _openExplore,
          child: const Text('TÜMÜ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  Widget _buildFeatured(AsyncSnapshot<List<Event>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return _loadingCard(220);
    if (snapshot.hasError) return _statusCard('İçerik yüklenemedi.');
    final events = snapshot.data ?? [];
    if (events.isEmpty) return _statusCard('Bugün için henüz içerik bulunamadı.');
    return _FeaturedEventCard(event: events.first, onTap: () => _openEvent(events.first));
  }

  Widget _buildList(AsyncSnapshot<List<Event>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Column(children: List.generate(3, (_) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _loadingCard(100))));
    }
    if (snapshot.hasError || snapshot.data == null) return const SizedBox.shrink();
    final events = snapshot.data!.skip(1).take(6).toList();
    return Column(
      children: events.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _EventCard(event: e, onTap: () => _openEvent(e)),
      )).toList(),
    );
  }

  Widget _featureCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: const Color(0xFFF2F2F0), borderRadius: BorderRadius.circular(16)), child: Icon(icon)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.25)),
            ])),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }

  Widget _loadingCard(double height) => Container(height: height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));

  Widget _statusCard(String text) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)));
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMMM EEEE', 'tr_TR').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(26)),
      child: Row(children: [
        const Text('☀️', style: TextStyle(fontSize: 38)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(date, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Bugün şehirde güzel bir gün.', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          const Text('Akşam için planını seç.', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ])),
        const Column(children: [Text('24°', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('Ankara', style: TextStyle(color: Colors.white60, fontSize: 11))]),
      ]),
    );
  }
}

class _FeaturedEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  const _FeaturedEventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 220,
          child: Stack(children: [
            Positioned.fill(child: event.imageUrl == null ? const ColoredBox(color: Colors.black) : Image.network(event.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black))),
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: .85)])))),
            Positioned(top: 16, right: 16, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Text('${event.recommendationScore.round()}% UYGUN', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)))),
            Positioned(left: 18, right: 18, bottom: 17, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event.category.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 5),
              Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.05)),
              const SizedBox(height: 7),
              Text(event.venueName == null ? 'Bugün · ${DateFormat('HH:mm').format(event.startsAt)}' : 'Bugün · ${DateFormat('HH:mm').format(event.startsAt)} · ${event.venueName}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(children: [
            Container(
              width: 76,
              height: 76,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: const Color(0xFFF0F0EE), borderRadius: BorderRadius.circular(17)),
              child: event.imageUrl == null ? const Icon(Icons.event_outlined, size: 28) : Image.network(event.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.event_outlined, size: 28)),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event.category.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .7, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, height: 1.1)),
              const SizedBox(height: 7),
              Text(event.venueName == null ? 'Bugün · ${DateFormat('HH:mm').format(event.startsAt)}' : 'Bugün · ${DateFormat('HH:mm').format(event.startsAt)} · ${event.venueName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ])),
            if (event.recommendationScore > 0) ...[
              const SizedBox(width: 8),
              Text('%${event.recommendationScore.round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Category {
  final String icon;
  final String name;
  const _Category(this.icon, this.name);
}
