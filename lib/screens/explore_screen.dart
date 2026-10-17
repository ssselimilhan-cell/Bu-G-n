import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/place.dart';
import '../services/event_service.dart';
import '../services/place_service.dart';
import '../services/city_preference_service.dart';
import 'event_detail_screen.dart';
import 'map_explore_screen.dart';
import 'community_activities_screen.dart';
import 'place_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialCategory;

  const ExploreScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final PlaceService _placeService = PlaceService();

  final EventService _eventService = EventService();

  String _selectedCity = CityPreferenceService.defaultCity;

  late final TabController _tabController;

  final TextEditingController _searchController = TextEditingController();

  List<Place> _places = <Place>[];
  List<Place> _allPlacesForSearch = <Place>[];

  List<Event> _events = <Event>[];
  List<Event> _allEventsForSearch = <Event>[];
  String _selectedEventCategory = 'Tümü';

  bool _placesLoading = true;
  bool _eventsLoading = true;

  String? _placesError;
  String? _eventsError;

  late String? _selectedCategory;

  String _searchText = '';

  final List<String> _categories = const [
    'Tümü',
    'Doğa',
    'Park',
    'Tarih',
    'Müze',
    'Kültür',
    'Sanat',
    'Aile',
    'Ücretsiz',
    'Açık hava',
  ];

  final List<String> _eventCategories = const [
    'Tümü',
    'Müzik',
    'Sahne',
    'Spor',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();

    _selectedCategory = _normalizeInitialCategory(
      widget.initialCategory,
    );

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _searchController.addListener(
      _onSearchChanged,
    );

    _loadPlaces();
    _loadEvents();
  }

  String? _normalizeInitialCategory(
    String? category,
  ) {
    if (category == null) {
      return null;
    }

    if (_categories.contains(category)) {
      return category == 'Tümü' ? null : category;
    }

    return null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(
      _onSearchChanged,
    );
    _searchController.dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _searchText = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _loadPlaces() async {
    _selectedCity = await CityPreferenceService().getSelectedCity();
    setState(() {
      _placesLoading = true;
      _placesError = null;
    });

    try {
      final localPlaces = await _placeService.getPlaces(
        city: _selectedCity,
        limit: 300,
      );
      List<Place> allPlaces;
      try {
        allPlaces = await _placeService.getPlaces(city: null, limit: 500);
      } catch (_) {
        allPlaces = localPlaces;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _places = localPlaces;
        _allPlacesForSearch = allPlaces;
        _placesLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _placesLoading = false;
        _placesError = 'Yerler yüklenemedi.';
      });
    }
  }

  Future<void> _loadEvents() async {
    _selectedCity = await CityPreferenceService().getSelectedCity();
    setState(() {
      _eventsLoading = true;
      _eventsError = null;
    });

    try {
      final localEvents = await _eventService.getUpcomingEvents(
        city: _selectedCity,
        days: 31,
        limit: 250,
      );
      List<Event> allEvents;
      try {
        allEvents = await _eventService.getUpcomingEvents(
          city: null,
          days: 31,
          limit: 500,
        );
      } catch (_) {
        allEvents = localEvents;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _events = localEvents;
        _allEventsForSearch = allEvents;
        _eventsLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _eventsLoading = false;
        _eventsError = 'Etkinlikler yüklenemedi.';
      });
    }
  }

  Future<void> _selectCategory(String category) async {
    setState(() {
      _selectedCategory = category == 'Tümü' ? null : category;
    });
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .trim();
  }

  bool _matchesPlaceCategory(Place place) {
    final category = _selectedCategory;
    if (category == null || category == 'Tümü') return true;

    final value = _normalizeText([
      place.category,
      place.placeType ?? '',
      ...place.tags,
    ].join(' '));

    switch (category) {
      case 'Doğa':
        return place.outdoor == true ||
            value.contains('doga') ||
            value.contains('nature') ||
            value.contains('waterfall') ||
            value.contains('selale') ||
            value.contains('plaj') ||
            value.contains('gol') ||
            value.contains('dag');
      case 'Park':
        return value.contains('park') || value.contains('bahce') || value.contains('garden');
      case 'Tarih':
        return value.contains('tarih') ||
            value.contains('historic') ||
            value.contains('history') ||
            value.contains('castle') ||
            value.contains('anıt') ||
            value.contains('anit');
      case 'Müze':
        return value.contains('muze') || value.contains('museum');
      case 'Kültür':
        return value.contains('kultur') ||
            value.contains('culture') ||
            value.contains('tiyatro') ||
            value.contains('theatre');
      case 'Sanat':
        return value.contains('sanat') ||
            value.contains('art') ||
            value.contains('gallery') ||
            value.contains('galeri');
      case 'Aile':
        return place.kidsFriendly == true;
      case 'Ücretsiz':
        return place.isFree == true;
      case 'Açık hava':
        return place.outdoor == true || value.contains('acik hava') || value.contains('outdoor');
      default:
        return true;
    }
  }

  bool _matchesEventCategory(Event event) {
    switch (_selectedEventCategory) {
      case 'Müzik':
        return _normalizeText(event.category).contains('music') ||
            _normalizeText(event.category).contains('muzik') ||
            _normalizeText(event.title).contains('konser');
      case 'Sahne':
        final value = _normalizeText('${event.category} ${event.title}');
        return value.contains('theatre') ||
            value.contains('theater') ||
            value.contains('tiyatro') ||
            value.contains('opera') ||
            value.contains('stand up');
      case 'Spor':
        final value = _normalizeText('${event.category} ${event.title}');
        return value.contains('sport') || value.contains('spor') || value.contains('mac');
      case 'Diğer':
        final value = _normalizeText(event.category);
        return !value.contains('music') &&
            !value.contains('muzik') &&
            !value.contains('theatre') &&
            !value.contains('theater') &&
            !value.contains('sport');
      default:
        return true;
    }
  }

  String _pageTitle() {
    if (_tabController.index == 1) {
      return '$_selectedCity etkinlikleri';
    }

    return _selectedCategory ?? '$_selectedCity’yi keşfet';
  }

  List<Place> get _filteredPlaces {
    final source = _searchText.isNotEmpty
        ? _allPlacesForSearch
        : (_places.isNotEmpty ? _places : _allPlacesForSearch);
    return source.where((place) {
      if (!_matchesPlaceCategory(place)) return false;
      if (_searchText.isEmpty) return true;
      final text = _normalizeText([
        place.name,
        place.category,
        place.placeType ?? '',
        place.shortDescription ?? '',
        place.address ?? '',
        place.city,
        ...place.tags,
      ].join(' '));
      return text.contains(_normalizeText(_searchText));
    }).toList();
  }

  List<Event> get _filteredEvents {
    final source = _searchText.isNotEmpty ? _allEventsForSearch : _events;
    return source.where((event) {
      if (!_matchesEventCategory(event)) return false;
      if (_searchText.isEmpty) return true;
      final text = _normalizeText([
        event.title,
        event.category,
        event.description ?? '',
        event.venueName ?? '',
        event.address ?? '',
        event.city,
      ].join(' '));
      return text.contains(_normalizeText(_searchText));
    }).toList();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _pageTitle(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Haritada keşfet',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapExploreScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Birlikte etkinlik oluştur',
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CommunityActivitiesScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) {
            _searchController.clear();
            setState(() {
              _selectedEventCategory = 'Tümü';
            });
          },
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(
              text: 'Yerler',
            ),
            Tab(
              text: 'Etkinlikler',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPlacesTab(),
            _buildEventsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox({
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        6,
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(
            Icons.search_rounded,
          ),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  onPressed: _searchController.clear,
                  icon: const Icon(
                    Icons.clear,
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              16,
            ),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              16,
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              16,
            ),
            borderSide: const BorderSide(
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlacesTab() {
    final selected = _selectedCategory ?? 'Tümü';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nereye gitmek istersin?',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _places.isNotEmpty
                          ? '$_selectedCity ve çevresindeki yerleri keşfet'
                          : 'Şehirdeki ve Türkiye genelindeki yerleri keşfet',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Haritada keşfet',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapExploreScreen()),
                ),
                icon: const Icon(Icons.map_outlined),
              ),
            ],
          ),
        ),
        _buildSearchBox(hint: 'Yer, ilçe veya şehir ara'),
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = selected == category;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) => _selectCategory(category),
                selectedColor: Colors.black,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(color: isSelected ? Colors.black : Colors.grey.shade300),
              );
            },
          ),
        ),
        Expanded(child: _buildPlacesContent()),
      ],
    );
  }

  Widget _buildPlacesContent() {
    if (_placesLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_placesError != null) {
      return _buildErrorState(
        message: _placesError!,
        onRetry: _loadPlaces,
      );
    }

    final places = _filteredPlaces;

    if (places.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPlaces,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(
              height: 150,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                ),
                child: Text(
                  _searchText.isNotEmpty
                      ? 'Aramana uygun yer bulunamadı.'
                      : 'Bu kategoride henüz yer yok.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlaces,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: places.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2, top: 2),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Keşfedilecek yerler',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '${places.length} sonuç',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }
          final place = places[index - 1];
          return _PlaceCard(place: place, onTap: () => _openPlace(place));
        },
      ),
    );
  }

  Widget _buildEventsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Yakında ne var?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                '$_selectedCity için yaklaşan etkinlikler; arama Türkiye genelinde yapılır.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        _buildSearchBox(hint: 'Etkinlik, sanatçı veya mekân ara'),
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            scrollDirection: Axis.horizontal,
            itemCount: _eventCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final category = _eventCategories[index];
              final isSelected = _selectedEventCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedEventCategory = category),
                selectedColor: Colors.black,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(color: isSelected ? Colors.black : Colors.grey.shade300),
              );
            },
          ),
        ),
        Expanded(child: _buildEventsContent()),
      ],
    );
  }

  Widget _buildEventsContent() {
    if (_eventsLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_eventsError != null) {
      return _buildErrorState(
        message: _eventsError!,
        onRetry: _loadEvents,
      );
    }

    final events = _filteredEvents;

    if (events.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(
              height: 150,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                ),
                child: Text(
                  _searchText.isNotEmpty
                      ? 'Aramana uygun etkinlik bulunamadı.'
                      : 'Önümüzdeki 31 gün içinde $_selectedCity için etkinlik bulunamadı.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: events.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 2, top: 2),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Yaklaşan etkinlikler',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                  Text(
                    '${events.length} sonuç',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }
          final event = events[index - 1];
          return _EventCard(event: event, onTap: () => _openEvent(event));
        },
      ),
    );
  }

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 12,
            ),
            FilledButton(
              onPressed: onRetry,
              child: const Text(
                'Tekrar dene',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPlace(
    Place place,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlaceDetailScreen(
          place: place,
        ),
      ),
    );
  }

  void _openEvent(
    Event event,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => EventDetailScreen(
          event: event,
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.place,
    required this.onTap,
  });

  IconData _iconForCategory() {
    final category = place.category.toLowerCase();

    if (category.contains(
          'doğa',
        ) ||
        category.contains(
          'nature',
        )) {
      return Icons.park_outlined;
    }

    if (category.contains(
          'park',
        ) ||
        category.contains(
          'bahçe',
        )) {
      return Icons.grass_outlined;
    }

    if (category.contains(
          'müze',
        ) ||
        category.contains(
          'museum',
        )) {
      return Icons.museum_outlined;
    }

    if (category.contains(
          'tarih',
        ) ||
        category.contains(
          'history',
        )) {
      return Icons.account_balance_outlined;
    }

    if (category.contains(
          'kültür',
        ) ||
        category.contains(
          'culture',
        )) {
      return Icons.theater_comedy_outlined;
    }

    if (category.contains(
          'sinema',
        ) ||
        category.contains(
          'cinema',
        )) {
      return Icons.movie_outlined;
    }

    return Icons.place_outlined;
  }

  Widget _buildImage() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(
        _iconForCategory(),
        size: 31,
        color: Colors.black54,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        20,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          20,
        ),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 92,
                height: 118,
                child: _buildImage(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(
                    14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              place.category.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          if (place.verified)
                            const Icon(
                              Icons.verified_outlined,
                              size: 16,
                            ),
                        ],
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade600),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              place.address?.trim().isNotEmpty == true
                                  ? '${place.city} · ${place.address}'
                                  : place.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                      if (place.shortDescription != null) ...[
                        const SizedBox(
                          height: 7,
                        ),
                        Text(
                          place.shortDescription!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(
                        height: 8,
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          if (place.isFree == true)
                            const _SmallPill(
                              icon: Icons.local_offer_outlined,
                              text: 'Ücretsiz',
                            ),
                          if (place.visitDurationMin != null)
                            _SmallPill(
                              icon: Icons.schedule_outlined,
                              text: '${place.visitDurationMin} dk',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              const Padding(
                padding: EdgeInsets.only(
                  right: 10,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.onTap,
  });

  String _dateText() {
    final value = event.startsAt.toLocal();

    final day = value.day.toString().padLeft(
          2,
          '0',
        );

    final month = value.month.toString().padLeft(
          2,
          '0',
        );

    final year = value.year.toString();

    final hour = value.hour.toString().padLeft(
          2,
          '0',
        );

    final minute = value.minute.toString().padLeft(
          2,
          '0',
        );

    return '$day.$month.$year · '
        '$hour:$minute';
  }

  String _priceText() {
    final min = event.priceMin;

    final max = event.priceMax;

    if (min == null && max == null) {
      return '';
    }

    if ((min == null || min == 0) && (max == null || max == 0)) {
      return 'Ücretsiz';
    }

    if (min != null && max != null && min != max) {
      return '${min.round()}-${max.round()} TL';
    }

    final price = min ?? max;

    if (price == null) {
      return '';
    }

    return '${price.round()} TL';
  }

  IconData _iconForCategory() {
    final value = event.category.toLowerCase();

    if (value.contains('music') ||
        value.contains('müzik') ||
        value.contains('konser')) {
      return Icons.music_note_outlined;
    }

    if (value.contains('sport') || value.contains('spor')) {
      return Icons.sports_basketball_outlined;
    }

    if (value.contains('theatre') ||
        value.contains('theater') ||
        value.contains('tiyatro') ||
        value.contains('culture') ||
        value.contains('kültür')) {
      return Icons.theater_comedy_outlined;
    }

    if (value.contains('film') ||
        value.contains('movie') ||
        value.contains('sinema')) {
      return Icons.movie_outlined;
    }

    return Icons.event_outlined;
  }

  Widget _buildImage() {
    final imageUrl = event.imageUrl;

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Center(
        child: Icon(
          _iconForCategory(),
          size: 34,
          color: Colors.black54,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: Icon(
          _iconForCategory(),
          size: 34,
          color: Colors.black54,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final price = _priceText();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        20,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          20,
        ),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 92,
                height: 132,
                color: Colors.grey.shade100,
                child: _buildImage(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(
                    14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.category.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                          if (price.isNotEmpty)
                            Text(
                              price,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        event.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(
                        height: 9,
                      ),
                      _EventInfoRow(
                        icon: Icons.schedule_outlined,
                        text: _dateText(),
                      ),
                      if ((event.venueName != null && event.venueName!.trim().isNotEmpty) ||
                          event.city.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        _EventInfoRow(
                          icon: Icons.location_on_outlined,
                          text: [
                            if (event.venueName?.trim().isNotEmpty == true) event.venueName!,
                            if (event.city.trim().isNotEmpty) event.city,
                          ].join(' · '),
                        ),
                      ],
                      const SizedBox(
                        height: 9,
                      ),
                      const Row(
                        children: [
                          Text(
                            'DETAYLAR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 13,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(
                  right: 10,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F1),
        borderRadius: BorderRadius.circular(
          15,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.black54,
          ),
          const SizedBox(
            width: 3,
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EventInfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: Colors.black54,
        ),
        const SizedBox(
          width: 5,
        ),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
