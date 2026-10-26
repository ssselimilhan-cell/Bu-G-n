import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _SavedPlaceCard extends StatefulWidget {
  final Place place;
  const _SavedPlaceCard({required this.place});

  @override
  State<_SavedPlaceCard> createState() => _SavedPlaceCardState();
}

class _SavedPlaceCardState extends State<_SavedPlaceCard> {
  final TextEditingController _noteController = TextEditingController();
  bool _loadingNote = true;
  bool _savingNote = false;
  String get _noteKey => 'bugun_saved_place_note_${widget.place.id}';

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _noteController.text = prefs.getString(_noteKey) ?? '';
    setState(() => _loadingNote = false);
  }

  Future<void> _saveNote() async {
    setState(() => _savingNote = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_noteKey, _noteController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notun kaydedildi.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not kaydedilemedi. Tekrar dene.')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PlaceDetailScreen(place: place),
                ));
              },
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      place.category == 'Müze'
                          ? Icons.museum_outlined
                          : place.outdoor == true
                              ? Icons.landscape_outlined
                              : Icons.place_outlined,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(place.category, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(height: 3),
                        const Text('Yer detaylarını aç', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black45),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              enabled: !_loadingNote && !_savingNote,
              minLines: 1,
              maxLines: 3,
              maxLength: 240,
              decoration: const InputDecoration(
                labelText: 'Kişisel notun',
                hintText: 'Örn. ailemle git, otoparkı kontrol et…',
                border: OutlineInputBorder(),
                isDense: true,
                counterText: '',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _loadingNote || _savingNote ? null : _saveNote,
                icon: _savingNote
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_savingNote ? 'Kaydediliyor…' : 'Notu kaydet'),
              ),
            ),
          ],
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
