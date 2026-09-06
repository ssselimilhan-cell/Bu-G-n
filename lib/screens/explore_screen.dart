import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import 'event_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  final List<Event> events;
  final String? initialCategory;

  const ExploreScreen({
    super.key,
    required this.events,
    this.initialCategory,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late String _category;

  static const List<String> _categories = [
    'Tümü',
    'Konser',
    'Tiyatro',
    'Maç',
    'Fırsat',
    'Sergi',
    'Doğa',
    'Ücretsiz',
    'Yeni',
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? 'Tümü';
  }

  List<Event> get _filteredEvents {
    if (_category == 'Tümü') {
      return widget.events;
    }

    final searchText = _category.toLowerCase();

    return widget.events.where((event) {
      final category = event.category.toLowerCase();

      return category == searchText || category.contains(searchText);
    }).toList();
  }

  void _openEvent(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = _filteredEvents;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F4),
        elevation: 0,
        title: const Text(
          'KEŞFET',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = category == _category;

                return ChoiceChip(
                  label: Text(
                    category,
                    style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _category = category;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: events.isEmpty
                ? _EmptyState(category: _category)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                    itemCount: events.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = events[index];

                      return _ExploreEventCard(
                        event: event,
                        onTap: () => _openEvent(event),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String category;

  const _EmptyState({
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.explore_outlined,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              category == 'Tümü'
                  ? 'Bugün için henüz etkinlik bulunamadı.'
                  : '$category kategorisinde bugün içerik yok.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Daha sonra tekrar kontrol edebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _ExploreEventCard({
    required this.event,
    required this.onTap,
  });

  String _timeText() {
    return DateFormat('HH:mm').format(event.startsAt);
  }

  String _metaText() {
    final time = _timeText();

    if (event.venueName == null || event.venueName!.trim().isEmpty) {
      return 'Bugün · $time';
    }

    return 'Bugün · $time · ${event.venueName}';
  }

  String _priceText() {
    if (event.priceMin == null && event.priceMax == null) {
      return 'Fiyat bilgisi yok';
    }

    if (event.priceMin != null &&
        event.priceMax != null &&
        event.priceMin != event.priceMax) {
      return '${event.priceMin!.round()} - ${event.priceMax!.round()} TL';
    }

    final price = event.priceMin ?? event.priceMax;

    if (price == null) {
      return 'Fiyat bilgisi yok';
    }

    if (price == 0) {
      return 'Ücretsiz';
    }

    return '${price.round()} TL';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildImage(),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _metaText(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _priceText(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (event.recommendationScore > 0)
                    Text(
                      '%${event.recommendationScore.round()}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 86,
      height: 86,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEC),
        borderRadius: BorderRadius.circular(17),
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
    );
  }
}