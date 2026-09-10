import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../models/place.dart';
import '../services/event_service.dart';
import '../services/place_service.dart';
import 'event_detail_screen.dart';

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

  late final TabController _tabController;

  List<Place> _places = [];
  List<Event> _events = [];

  bool _placesLoading = true;
  bool _eventsLoading = true;

  String? _placesError;
  String? _eventsError;

  late String? _selectedCategory;

  final List<String> _categories = const [
    'Tümü',
    'Doğa',
    'Park',
    'Tarih',
    'Müze',
    'Kültür',
  ];

  @override
  void initState() {
    super.initState();

    _selectedCategory = widget.initialCategory;

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _loadPlaces();
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _placesLoading = true;
      _placesError = null;
    });

    try {
      final places = await _placeService.getPlaces(
        city: 'Ankara',
        category: _selectedCategory,
        limit: 100,
      );

      if (!mounted) return;

      setState(() {
        _places = places;
        _placesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _placesLoading = false;
        _placesError = 'Yerler yüklenemedi.';
      });
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _eventsLoading = true;
      _eventsError = null;
    });

    try {
      final events = await _eventService.getUpcomingEvents(
        city: 'Ankara',
        days: 14,
        limit: 100,
      );

      if (!mounted) return;

      setState(() {
        _events = events;
        _eventsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _eventsLoading = false;
        _eventsError = 'Etkinlikler yüklenemedi.';
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadPlaces(),
      _loadEvents(),
    ]);
  }

  Future<void> _selectCategory(String category) async {
    setState(() {
      _selectedCategory =
          category == 'Tümü' ? null : category;
    });

    await _loadPlaces();
  }

  String _pageTitle() {
    if (_tabController.index == 1) {
      return 'Ankara etkinlikleri';
    }

    return _selectedCategory ?? 'Ankara’yı keşfet';
  }

  @override
  Widget build(BuildContext context) {
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
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) {
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlacesTab(),
          _buildEventsTab(),
        ],
      ),
    );
  }

  Widget _buildPlacesTab() {
    final selected = _selectedCategory ?? 'Tümü';

    return Column(
      children: [
        SizedBox(
          height: 58,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];

              return ChoiceChip(
                label: Text(category),
                selected: selected == category,
                onSelected: (_) =>
                    _selectCategory(category),
                selectedColor: Colors.black,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected == category
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _buildPlacesContent(),
        ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                _placesError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadPlaces,
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_places.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPlaces,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(
              child: Text(
                'Bu kategoride henüz yer yok.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
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
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24,
        ),
        itemCount: _places.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final place = _places[index];

          return _PlaceCard(
            place: place,
            onTap: () => _showPlaceDetails(place),
          );
        },
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_eventsLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_eventsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                _eventsError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadEvents,
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_events.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 32,
                ),
                child: Text(
                  'Önümüzdeki günlerde Ankara için etkinlik bulunamadı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
        padding: const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          24,
        ),
        itemCount: _events.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final event = _events[index];

          return _EventCard(
            event: event,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EventDetailScreen(
                    event: event,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPlaceDetails(Place place) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  place.category,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                if (place.shortDescription != null)
                  Text(
                    place.shortDescription!,
                    style: const TextStyle(
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 16),
                if (place.address != null)
                  Text(place.address!),
                if (place.visitDurationMin != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Yaklaşık ${place.visitDurationMin} dakika',
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            '${place.name} için navigasyonu birazdan ekleyeceğiz.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.navigation_outlined,
                    ),
                    label: const Text(
                      'Yol tarifi',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: Icon(
                  place.category == 'Doğa'
                      ? Icons.park_outlined
                      : place.category == 'Müze'
                          ? Icons.museum_outlined
                          : place.category == 'Tarih'
                              ? Icons.account_balance_outlined
                              : Icons.place_outlined,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (place.shortDescription !=
                        null) ...[
                      const SizedBox(height: 6),
                      Text(
                        place.shortDescription!,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: Colors.black54,
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
    return DateFormat(
      'd MMM · HH:mm',
      'tr_TR',
    ).format(event.startsAt.toLocal());
  }

  String _priceText() {
    final min = event.priceMin;
    final max = event.priceMax;

    if (min == null && max == null) {
      return '';
    }

    if (min == 0 &&
        (max == null || max == 0)) {
      return 'Ücretsiz';
    }

    if (min != null &&
        max != null &&
        min != max) {
      return '${min.round()}-${max.round()} TL';
    }

    final price = min ?? max;

    if (price == null) {
      return '';
    }

    return '${price.round()} TL';
  }

  IconData _categoryIcon() {
    final value = event.category.toLowerCase();

    if (value.contains('music') ||
        value.contains('müzik')) {
      return Icons.music_note_outlined;
    }

    if (value.contains('sports') ||
        value.contains('spor')) {
      return Icons.sports_basketball_outlined;
    }

    if (value.contains('arts') ||
        value.contains('kültür') ||
        value.contains('theatre') ||
        value.contains('tiyatro')) {
      return Icons.theater_comedy_outlined;
    }

    if (value.contains('film') ||
        value.contains('movie')) {
      return Icons.local_movies_outlined;
    }

    return Icons.event_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final priceText = _priceText();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 92,
                height: 126,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft:
                        Radius.circular(20),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: event.imageUrl == null
                    ? Center(
                        child: Icon(
                          _categoryIcon(),
                          size: 34,
                        ),
                      )
                    : Image.network(
                        event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) {
                          return Center(
                            child: Icon(
                              _categoryIcon(),
                              size: 34,
                            ),
                          );
                        },
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.category
                                  .toUpperCase(),
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors
                                    .grey.shade600,
                                fontWeight:
                                    FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                          if (priceText.isNotEmpty)
                            Text(
                              priceText,
                              style:
                                  const TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.title,
                        maxLines: 3,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _dateText(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors
                                    .grey.shade700,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (event.venueName != null &&
                          event.venueName!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Icon(
                              Icons
                                  .location_on_outlined,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                event.venueName!,
                                maxLines: 2,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors
                                      .grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Text(
                            'DETAYLAR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                          SizedBox(width: 4),
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
            ],
          ),
        ),
      ),
    );
  }
}
