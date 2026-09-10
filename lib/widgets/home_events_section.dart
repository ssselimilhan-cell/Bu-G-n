import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../screens/event_detail_screen.dart';

class HomeEventsSection extends StatefulWidget {
  const HomeEventsSection({super.key});

  @override
  State<HomeEventsSection> createState() =>
      _HomeEventsSectionState();
}

class _HomeEventsSectionState extends State<HomeEventsSection> {
  final EventService _eventService = EventService();

  List<Event> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final events = await _eventService.getTodayEvents(
        city: 'Ankara',
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Bugünkü etkinlikler yüklenemedi.';
      });
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

  String _timeText(DateTime dateTime) {
    return DateFormat(
      'HH:mm',
      'tr_TR',
    ).format(dateTime.toLocal());
  }

  String _priceText(Event event) {
    final min = event.priceMin;
    final max = event.priceMax;

    if (min == null && max == null) {
      return '';
    }

    if (min == 0 && (max == null || max == 0)) {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'BUGÜN ANKARA\'DA',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const _AllEventsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Tümü',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return SizedBox(
        height: 178,
        child: ListView.separated(
          padding: const EdgeInsets.only(right: 20),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) =>
              const SizedBox(width: 12),
          itemBuilder: (_, __) {
            return Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
      );
    }

    if (_error != null) {
      return Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bugün için listelenmiş etkinlik bulunmuyor.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 178,
      child: ListView.separated(
        padding: const EdgeInsets.only(right: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _events.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _HomeEventCard(
            event: _events[index],
            onTap: () => _openEvent(_events[index]),
            timeText: _timeText(_events[index].startsAt),
            priceText: _priceText(_events[index]),
          );
        },
      ),
    );
  }
}

class _HomeEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final String timeText;
  final String priceText;

  const _HomeEventCard({
    required this.event,
    required this.onTap,
    required this.timeText,
    required this.priceText,
  });

  IconData _icon() {
    final value = event.category.toLowerCase();

    if (value.contains('music') ||
        value.contains('müzik')) {
      return Icons.music_note_outlined;
    }

    if (value.contains('sports') ||
        value.contains('spor')) {
      return Icons.sports_outlined;
    }

    if (value.contains('arts') ||
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 82,
                width: double.infinity,
                child: event.imageUrl == null
                    ? Container(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: Icon(
                            _icon(),
                            size: 34,
                          ),
                        ),
                      )
                    : Image.network(
                        event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: Center(
                              child: Icon(
                                _icon(),
                                size: 34,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    10,
                    14,
                    10,
                  ),
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
                                  TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.w900,
                                letterSpacing: 0.7,
                                color:
                                    Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Text(
                            timeText,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          if (event.venueName != null &&
                              event.venueName!
                                  .trim()
                                  .isNotEmpty) ...[
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.venueName!,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors
                                      .grey.shade700,
                                ),
                              ),
                            ),
                          ] else
                            const Spacer(),
                          if (priceText.isNotEmpty)
                            Text(
                              priceText,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.w800,
                              ),
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

class _AllEventsScreen extends StatefulWidget {
  const _AllEventsScreen();

  @override
  State<_AllEventsScreen> createState() =>
      _AllEventsScreenState();
}

class _AllEventsScreenState
    extends State<_AllEventsScreen> {
  final EventService _eventService = EventService();

  List<Event> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final events =
          await _eventService.getUpcomingEvents(
        city: 'Ankara',
        days: 14,
        limit: 100,
      );

      if (!mounted) return;

      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Etkinlikler yüklenemedi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Ankara Etkinlikleri',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
                _error!,
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Önümüzdeki 14 gün içinde Ankara için etkinlik bulunamadı.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
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

          return _AllEventListCard(
            event: event,
          );
        },
      ),
    );
  }
}

class _AllEventListCard extends StatelessWidget {
  final Event event;

  const _AllEventListCard({
    required this.event,
  });

  String _dateText() {
    return DateFormat(
      'd MMM · HH:mm',
      'tr_TR',
    ).format(event.startsAt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(
                event: event,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 82,
                height: 92,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: event.imageUrl == null
                    ? const Icon(
                        Icons.event_outlined,
                        size: 30,
                      )
                    : Image.network(
                        event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.event_outlined,
                            size: 30,
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
                      _dateText(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.title,
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    if (event.venueName != null &&
                        event.venueName!
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        event.venueName!,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
