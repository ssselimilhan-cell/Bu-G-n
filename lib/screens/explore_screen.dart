import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event.dart';
import '../models/place.dart';
import '../services/event_service.dart';
import '../services/place_service.dart';
import '../services/city_preference_service.dart';
import 'event_detail_screen.dart';
import 'place_detail_screen.dart';
import 'cinema_screen.dart';
import '../widgets/city_picker_sheet.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialCategory;
  final bool initialMapView;

  const ExploreScreen({
    super.key,
    this.initialCategory,
    this.initialMapView = false,
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

  List<Event> _events = <Event>[];

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
    'Sinema',
  ];

  @override
  void initState() {
    super.initState();

    _selectedCategory = _normalizeInitialCategory(
      widget.initialCategory,
    );

    _tabController = TabController(
      length: 4,
      initialIndex: widget.initialMapView ? 3 : 0,
      vsync: this,
    );

    _searchController.addListener(
      _onSearchChanged,
    );

    _initialize();
  }

  Future<void> _initialize() async {
    final city = await CityPreferenceService().getSelectedCity();
    if (!mounted) return;
    setState(() => _selectedCity = city);
    await Future.wait([_loadPlaces(), _loadEvents()]);
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
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMapView != widget.initialMapView) {
      _tabController.animateTo(widget.initialMapView ? 3 : 0);
    }
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
    if (!mounted) return;
    setState(() {
      _placesLoading = true;
      _placesError = null;
    });

    try {
      final places = await _placeService.getPlaces(
        city: _selectedCity,
        // Load the city's full list once; category labels in the UI can differ
        // slightly from the source taxonomy, so filter locally below.
        category: null,
        limit: 1000,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _places = places;
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
    if (!mounted) return;
    setState(() {
      _eventsLoading = true;
      _eventsError = null;
    });

    try {
      final events = await _eventService.getUpcomingEvents(
        city: _selectedCity,
        days: 31,
        limit: 1000,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _events = events;
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

  Future<void> _chooseCity() async {
    final chosen = await showCityPickerSheet(context, _selectedCity);
    if (chosen == null || chosen == _selectedCity || !mounted) return;

    await CityPreferenceService().saveSelectedCity(chosen);
    if (!mounted) return;

    setState(() {
      _selectedCity = chosen;
      _searchController.clear();
    });

    await Future.wait([
      _loadPlaces(),
      _loadEvents(),
    ]);
  }

  Future<void> _selectCategory(
    String category,
  ) async {
    final newCategory = category == 'Tümü' ? null : category;

    setState(() {
      _selectedCategory = newCategory;
    });

    await _loadPlaces();
  }

  String _pageTitle() {
    if (_tabController.index == 1) {
      return '$_selectedCity etkinlikleri';
    }
    if (_tabController.index == 2) {
      return 'Sinema';
    }
    if (_tabController.index == 3) {
      return 'Haritada keşfet';
    }

    return _selectedCategory ?? '$_selectedCity’yi keşfet';
  }

  List<Place> get _filteredPlaces {
    final query = _normalizeSearch(_searchText);
    final selected = _selectedCategory == null
        ? ''
        : _normalizeSearch(_selectedCategory!);

    // Preserve the original fast path: when "Tümü" is selected and the
    // search field is empty, return the loaded list directly. In particular,
    // do not rebuild searchable text for every row unless the user is
    // actually searching.
    if (query.isEmpty && selected.isEmpty) return _places;

    return _places.where((place) {
      if (selected.isNotEmpty) {
        final category = _normalizeSearch(place.category);
        final matchesCategory = category == selected ||
            (selected == 'tarih' &&
                (category.contains('tarih') || category == 'gezi')) ||
            (selected == 'kultur' &&
                (category.contains('kultur') ||
                    category == 'sanat' ||
                    category == 'eglence')) ||
            (selected == 'doga' &&
                (category.contains('doga') || category == 'park')) ||
            (selected == 'sinema' && category.contains('sinema'));
        if (!matchesCategory) return false;
      }

      if (query.isEmpty) return true;

      final text = _normalizeSearch([
        place.name,
        place.category,
        place.placeType ?? '',
        place.shortDescription ?? '',
        place.address ?? '',
        ...place.tags,
      ].join(' '));
      return text.contains(query);
    }).toList();
  }

  String _normalizeSearch(String value) => value
      .toLowerCase()
      .replaceAll('İ', 'i')
      .replaceAll('ı', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .trim();

  List<Event> get _filteredEvents {
    final query = _normalizeSearch(_searchText);
    if (query.isEmpty) return _events;
    return _events.where((event) {
      final text = _normalizeSearch([
        event.title,
        event.category,
        event.description ?? '',
        event.venueName ?? '',
        event.address ?? '',
      ].join(' '));
      return text.contains(query);
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
        actions: [
          IconButton(
            tooltip: 'Şehir seç',
            onPressed: _chooseCity,
            icon: const Icon(Icons.location_city_outlined),
          ),
          const SizedBox(width: 4),
        ],
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _pageTitle(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          isScrollable: true,
          controller: _tabController,
          onTap: (_) {
            // A query typed in one tab must not silently hide all items in another.
            _searchController.clear();
            setState(() {});
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
            Tab(
              text: 'Sinema',
            ),
            Tab(text: 'Harita'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPlacesTab(),
            _buildEventsTab(),
            CinemaScreen(city: _selectedCity),
            _buildMapTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTab() {
    final mapped = _places.where((p) =>
        p.latitude != null &&
        p.longitude != null &&
        p.latitude! >= -90 && p.latitude! <= 90 &&
        p.longitude! >= -180 && p.longitude! <= 180).toList();
    final first = mapped.isEmpty ? null : mapped.first;
    final center = first == null
        ? const LatLng(39.9255, 32.8663)
        : LatLng(first.latitude!, first.longitude!);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              const Expanded(child: Text('Yakınındaki ve şehirdeki yerleri haritada keşfet')),
              IconButton(
                tooltip: 'Haritayı yenile',
                onPressed: _loadPlaces,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: _placesLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  options: MapOptions(initialCenter: center, initialZoom: 11),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'tr.bugun.app',
                    ),
                    MarkerLayer(
                      markers: mapped.map((place) => Marker(
                        point: LatLng(place.latitude!, place.longitude!),
                        width: 180,
                        height: 64,
                        child: GestureDetector(
                          onTap: () => _openPlace(place),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                                child: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                              const Icon(Icons.location_on, color: Colors.red, size: 27),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors', onTap: () => _openMapLink('https://www.openstreetmap.org/copyright')),
                      ],
                    ),
                  ],
                ),
        ),
        if (!_placesLoading && mapped.isEmpty)
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text('Bu şehirde koordinatı kayıtlı yer bulunamadı. Yer listesine bakabilirsin.', textAlign: TextAlign.center),
          ),
      ],
    );
  }

  Future<void> _openMapLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Nereye gitmek istersin?',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _tabController.animateTo(3),
                icon: const Icon(Icons.map_outlined, size: 19),
                label: const Text('Harita'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
        _buildSearchBox(
          hint: '$_selectedCity içinde yer ara...',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _categories.map(
                (category) {
                  final isSelected = selected == category;

                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => _selectCategory(category),
                    selectedColor: Colors.black,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: isSelected ? Colors.black : Colors.grey.shade300,
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ),
        Expanded(child: _buildPlacesContent()),
      ],
    );
  }

  Widget _buildPlacesContent() {
    if (_placesLoading) {
      return const Center(child: CircularProgressIndicator());
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 28),
            const Icon(Icons.explore_off_outlined, size: 48, color: Colors.black54),
            const SizedBox(height: 14),
            Text(
              _searchText.isNotEmpty
                  ? 'Aramana uygun yer bulunamadı.'
                  : _selectedCategory != null
                      ? '$_selectedCity için bu kategoride henüz yer bulunmuyor.'
                      : '$_selectedCity için yer bulunamadı.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aşağı çekerek yeniden deneyebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 18),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  _tabController.animateTo(1);
                  setState(() {});
                },
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('Etkinlikleri göster'),
              ),
            ),
          ],
        ),
      );
    }

    // Use Flutter's standard Card/ListTile layout here. It avoids the custom
    // stretch-row layout that could leave the Explore viewport visually empty
    // on some devices, while retaining place details and navigation.
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${places.length} yer bulundu',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPlaces,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              itemCount: places.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final place = places[index];
                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF0F0EE),
                      child: Icon(
                        Icons.place_outlined,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    title: Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        [
                          place.category,
                          if (place.shortDescription != null &&
                              place.shortDescription!.trim().isNotEmpty)
                            place.shortDescription!,
                          if (place.address != null &&
                              place.address!.trim().isNotEmpty)
                            place.address!,
                        ].join(' · '),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openPlace(place),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 2),
          child: Text(
            'Yakında ne var?',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _buildSearchBox(
          hint: '$_selectedCity etkinliklerinde ara...',
        ),
        Expanded(
          child: _buildEventsContent(),
        ),
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
              height: 32,
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
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24,
        ),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(
          height: 12,
        ),
        itemBuilder: (context, index) {
          final event = events[index];

          return _EventCard(
            event: event,
            onTap: () => _openEvent(
              event,
            ),
          );
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
                      if (event.venueName != null &&
                          event.venueName!.trim().isNotEmpty) ...[
                        const SizedBox(
                          height: 5,
                        ),
                        _EventInfoRow(
                          icon: Icons.location_on_outlined,
                          text: event.venueName!,
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
