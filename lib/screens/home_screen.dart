import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import 'event_detail_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';
import 'saved_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventService _service = EventService();

  late Future<List<Event>> _events;

  static const List<_Category> _categories = [
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

  void _openExplore({
    String? category,
    List<Event>? events,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExploreScreen(
          events: events ?? const [],
          initialCategory: category,
        ),
      ),
    );
  }

  Future<void> _openCategory(String category) async {
    try {
      final events = await _events;

      if (!mounted) return;

      _openExplore(
        category: category,
        events: events,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'İçerikler yüklenemedi. Lütfen tekrar deneyin.',
          ),
        ),
      );
    }
  }

  void _openEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: event),
      ),
    );
  }

  Future<void> _openExploreAll() async {
    try {
      final events = await _events;

      if (!mounted) return;

      _openExplore(events: events);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'İçerikler yüklenemedi.',
          ),
        ),
      );
    }
  }

  Future<void> _openSaved() async {
    try {
      final events = await _events;

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SavedScreen(
            events: events,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SavedScreen(
            events: [],
          ),
        ),
      );
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  String _formattedDate() {
    return DateFormat(
      'd MMMM EEEE',
      'tr_TR',
    ).format(DateTime.now());
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
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildHeader(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildWeatherCard(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      28,
                      20,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildCategories(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      30,
                      20,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        'BUGÜNÜN ÖNERİSİ',
                        'Senin için seçtik',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildFeaturedEvent(snapshot),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      30,
                      20,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        'SANA ÖZEL',
                        'Bugün sana uygun',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildEventList(snapshot),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      30,
                      20,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildSpecialCard(
                        icon: Icons.local_offer_outlined,
                        title: 'Bugünün fırsatları',
                        subtitle:
                            'Restoran, kafe ve mağazalardan kampanyalar',
                        buttonText: 'KEŞFET',
                        category: 'Fırsat',
                        snapshot: snapshot,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildSpecialCard(
                        icon: Icons.free_breakfast_outlined,
                        title: 'Bugün ücretsiz',
                        subtitle:
                            'Ankara\'da para harcamadan yapabileceklerin',
                        buttonText: 'GÖR',
                        category: 'Ücretsiz',
                        snapshot: snapshot,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      30,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _buildSpecialCard(
                        icon: Icons.auto_awesome_outlined,
                        title: 'Yeni açılanlar',
                        subtitle:
                            'Şehirde yeni keşfedilecek mekanlar',
                        buttonText: 'KEŞFET',
                        category: 'Yeni',
                        snapshot: snapshot,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
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
              Text(
                'BUGÜN',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.8,
                  height: 0.95,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Ankara\'da bugün ne var?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconButton(
            onPressed: _openProfile,
            icon: const Icon(
              Icons.person_outline_rounded,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const Text(
            '☀️',
            style: TextStyle(fontSize: 38),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formattedDate(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bugün şehirde güzel bir gün.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Akşam için planını seç.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Column(
            children: [
              Text(
                '24°',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Ankara',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BUGÜN NE VAR?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final category = _categories[index];

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    _openCategory(category.name);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    child: Row(
                      children: [
                        Text(
                          category.icon,
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _openExploreAll,
          child: const Text(
            'TÜMÜ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedEvent(
    AsyncSnapshot<List<Event>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingCard(height: 220);
    }

    if (snapshot.hasError) {
      return _buildErrorCard();
    }

    final events = snapshot.data ?? const [];

    if (events.isEmpty) {
      return _buildEmptyCard();
    }

    return GestureDetector(
      onTap: () => _openEvent(events.first),
      child: _FeaturedEventCard(
        event: events.first,
      ),
    );
  }

  Widget _buildEventList(
    AsyncSnapshot<List<Event>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLoadingCard(height: 100),
          ),
        ),
      );
    }

    if (snapshot.hasError || snapshot.data == null) {
      return const SizedBox.shrink();
    }

    final events = snapshot.data!.skip(1).take(6).toList();

    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: events
          .map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _openEvent(event),
                child: _EventCard(event: event),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSpecialCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required String category,
    required AsyncSnapshot<List<Event>> snapshot,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          _openExplore(
            category: category,
            events: snapshot.data ?? const [],
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard({
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 30,
          ),
          SizedBox(height: 10),
          Text(
            'İçerik şu anda yüklenemedi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Sayfayı aşağı çekip tekrar deneyebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.explore_outlined,
            size: 34,
          ),
          SizedBox(height: 12),
          Text(
            'Bugün için henüz içerik bulunamadı.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Yeni içerikler geldiğinde burada görünecek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return NavigationBar(
      backgroundColor: Colors.white,
      elevation: 0,
      height: 70,
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 1:
            _openExploreAll();
            break;
          case 2:
            _openSaved();
            break;
          case 3:
            _openProfile();
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.today_outlined),
          selectedIcon: Icon(Icons.today),
          label: 'BUGÜN',
        ),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Keşfet',
        ),
        NavigationDestination(
          icon: Icon(Icons.bookmark_outline),
          selectedIcon: Icon(Icons.bookmark),
          label: 'Kayıt',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}

class _FeaturedEventCard extends StatelessWidget {
  final Event event;

  const _FeaturedEventCard({
    required this.event,
  });

  String _eventMeta() {
    final time = DateFormat(
      'HH:mm',
    ).format(event.startsAt);

    if (event.venueName == null ||
        event.venueName!.isEmpty) {
      return 'Bugün · $time';
    }

    return 'Bugün · $time · ${event.venueName}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          if (event.imageUrl != null)
            Positioned.fill(
              child: Image.network(
                event.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const ColoredBox(
                    color: Colors.black,
                  );
                },
              ),
            )
          else
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black,
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black87,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${event.recommendationScore.round()}% UYGUN',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 17,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _eventMeta(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;

  const _EventCard({
    required this.event,
  });

  String get _subtitle {
    final time = DateFormat(
      'HH:mm',
    ).format(event.startsAt);

    if (event.venueName == null ||
        event.venueName!.isEmpty) {
      return 'Bugün · $time';
    }

    return 'Bugün · $time · ${event.venueName}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0EE),
              borderRadius: BorderRadius.circular(17),
            ),
            child: event.imageUrl == null
                ? const Icon(
                    Icons.event_outlined,
                    size: 28,
                  )
                : Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.event_outlined,
                        size: 28,
                      );
                    },
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  event.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (event.recommendationScore > 0)
            Text(
              '%${event.recommendationScore.round()}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _Category {
  final String icon;
  final String name;

  const _Category(
    this.icon,
    this.name,
  );
}