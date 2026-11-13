import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/event.dart';
import '../models/place.dart';
import '../services/event_service.dart';
import '../services/place_service.dart';
import '../services/saved_event_service.dart';
import '../services/saved_place_service.dart';
import '../services/saved_place_note_service.dart';
import '../services/city_preference_service.dart';
import '../widgets/city_picker_sheet.dart';
import 'event_detail_screen.dart';
import 'place_detail_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import '../widgets/bugun_brand_logo.dart';

class _SavedTabLabel extends StatelessWidget {
  final String label;
  final bool selected;

  const _SavedTabLabel({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFF8A3D) : const Color(0xFF1268B3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }
}

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
  String _selectedCity = CityPreferenceService.defaultCity;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );

    _tabController.addListener(_handleTabChange);
    _loadSelectedCity();
    _loadSaved();
  }

  void _handleTabChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSelectedCity() async {
    final city = await CityPreferenceService().getSelectedCity();
    if (mounted) setState(() => _selectedCity = city);
  }

  Future<void> _chooseCity() async {
    final city = await showCityPickerSheet(context, _selectedCity);
    if (city == null || !mounted || city == _selectedCity) return;
    await CityPreferenceService().saveSelectedCity(city);
    if (mounted) setState(() => _selectedCity = city);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
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
          const Color(0xFFFFF0DF),
      appBar: BugunMainAppBar(
        backgroundColor:
            const Color(0xFFFFF0DF),
actions: [
          BugunHeaderActionButton(
            tooltip: 'Şehir seç',
            icon: Icons.location_city_outlined,
            onPressed: _chooseCity,
          ),
          BugunHeaderActionButton(
            tooltip: 'Profil',
            icon: Icons.person_outline_rounded,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BugunBrandLogo(fontSize: 32),
            const SizedBox(width: 10),
            const Text('Kayıtlarım', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FA),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                indicator: const BoxDecoration(color: Colors.transparent),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(child: _SavedTabLabel(label: 'Etkinlikler', selected: _tabController.index == 0)),
                  Tab(child: _SavedTabLabel(label: 'Yerler', selected: _tabController.index == 1)),
                  Tab(child: _SavedTabLabel(label: 'Takvimim', selected: _tabController.index == 2)),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEvents(),
          _buildPlaces(),
          const CalendarScreen(embedded: true),
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
  final SavedPlaceNoteService _noteService = SavedPlaceNoteService();
  late final StreamSubscription<AuthState> _authSubscription;
  bool _loadingNote = true;
  bool _savingNote = false;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.signedOut) {
        _loadNote();
      }
    });
    _loadNote();
  }

  Future<void> _loadNote() async {
    setState(() => _loadingNote = true);
    try {
      final note = await _noteService.getNote(widget.place.id);
      if (!mounted) return;
      _noteController.text = note;
      setState(() => _loadingNote = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingNote = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kişisel not yüklenemedi. Tekrar deneyebilirsin.')),
      );
    }
  }

  Future<void> _saveNote() async {
    setState(() => _savingNote = true);
    try {
      await _noteService.saveNote(widget.place.id, _noteController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Supabase.instance.client.auth.currentUser == null
            ? 'Notun bu cihaza kaydedildi.'
            : 'Notun hesabına kaydedildi.')),
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
    _authSubscription.cancel();
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
