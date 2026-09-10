import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../models/place.dart';
import '../services/event_service.dart';
import '../services/place_service.dart';
import '../services/saved_event_service.dart';
import '../services/saved_place_service.dart';
import 'event_detail_screen.dart';
import 'place_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({
    super.key,
  });

  @override
  State<SavedScreen> createState() =>
      _SavedScreenState();
}

class _SavedScreenState
    extends State<SavedScreen>
    with SingleTickerProviderStateMixin {
  final SavedEventService _savedEventService =
      SavedEventService();

  final SavedPlaceService _savedPlaceService =
      SavedPlaceService();

  final EventService _eventService =
      EventService();

  final PlaceService _placeService =
      PlaceService();

  late final TabController _tabController;

  List<Event> _events = [];
  List<Place> _places = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _loadSaved();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final savedEventIds =
          await _savedEventService.getSavedIds();

      final savedPlaceIds =
          await _savedPlaceService.getSavedIds();

      final results = await Future.wait([
        _eventService.getEventsByIds(
          savedEventIds,
        ),
        _placeService.getPlacesByIds(
          savedPlaceIds,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _events = results[0] as List<Event>;
        _places = results[1] as List<Place>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _events = [];
        _places = [];
        _loading = false;
        _error =
            'Kayıtlar yüklenemedi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF7F7F5),
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        title: const Text(
          'Kayıtlarım',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor:
              Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(
              text: 'Etkinlikler',
            ),
            Tab(
              text: 'Yerler',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEvents(),
          _buildPlaces(),
        ],
      ),
    );
  }

  Widget _buildEvents() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _ErrorState(
        text: _error!,
        onRetry: _loadSaved,
      );
    }

    if (_events.isEmpty) {
      return const _EmptyState(
        icon:
            Icons.event_outlined,
        title:
            'Kayıtlı etkinlik yok',
        description:
            'Beğendiğin etkinlikleri kaydettiğinde burada göreceksin.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSaved,
      child: ListView.separated(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        itemCount:
            _events.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          height: 12,
        ),
        itemBuilder:
            (context, index) {
          return _SavedEventCard(
            event: _events[index],
          );
        },
      ),
    );
  }

  Widget _buildPlaces() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _ErrorState(
        text: _error!,
        onRetry: _loadSaved,
      );
    }

    if (_places.isEmpty) {
      return const _EmptyState(
        icon:
            Icons.place_outlined,
        title:
            'Kayıtlı yer yok',
        description:
            'Beğendiğin yerleri kaydettiğinde burada göreceksin.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSaved,
      child: ListView.separated(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        itemCount:
            _places.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          height: 12,
        ),
        itemBuilder:
            (context, index) {
          return _SavedPlaceCard(
            place: _places[index],
          );
        },
      ),
    );
  }
}

class _SavedEventCard
    extends StatelessWidget {
  final Event event;

  const _SavedEventCard({
    required this.event,
  });

  String _dateText() {
    return DateFormat(
      'd MMM · HH:mm',
      'tr_TR',
    ).format(
      event.startsAt.toLocal(),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(20),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  EventDetailScreen(
                event: event,
              ),
            ),
          ).then(
            (_) {
              if (context.mounted) {
                // Ekran geri döndüğünde kayıt durumu
                // yeniden okunacak.
                // ignore: invalid_use_of_protected_member
              }
            },
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 88,
                clipBehavior:
                    Clip.antiAlias,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child:
                    event.imageUrl == null ||
                            event.imageUrl!
                                .trim()
                                .isEmpty
                        ? const Icon(
                            Icons
                                .event_outlined,
                            size: 32,
                          )
                        : Image.network(
                            event.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) {
                              return const Icon(
                                Icons
                                    .event_outlined,
                                size: 32,
                              );
                            },
                          ),
              ),
              const SizedBox(
                width: 13,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateText(),
                      style:
                          const TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      event.title,
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    if (event.venueName !=
                            null &&
                        event.venueName!
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        event.venueName!,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            TextStyle(
                          fontSize: 11,
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color:
                    Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedPlaceCard
    extends StatelessWidget {
  final Place place;

  const _SavedPlaceCard({
    required this.place,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(20),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PlaceDetailScreen(
                place: place,
              ),
            ),
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: Icon(
                  place.category ==
                          'Müze'
                      ? Icons
                          .museum_outlined
                      : place.outdoor ==
                              true
                          ? Icons
                              .landscape_outlined
                          : Icons
                              .place_outlined,
                  size: 30,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      place.category,
                      style:
                          TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color:
                    Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 52,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              title,
              style:
                  const TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 9,
            ),
            Text(
              description,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Colors.grey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.text,
    required this.onRetry,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              text,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(
              height: 12,
            ),
            FilledButton(
              onPressed:
                  onRetry,
              child:
                  const Text(
                'Tekrar dene',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
