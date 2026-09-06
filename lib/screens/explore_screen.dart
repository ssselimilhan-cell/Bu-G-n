import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import 'event_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  final List<Event> events;
  final String? initialCategory;

  const ExploreScreen({super.key, required this.events, this.initialCategory});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String? _category;

  static const _categories = [
    'Tümü', 'Konser', 'Tiyatro', 'Maç', 'Fırsat', 'Sergi', 'Doğa', 'Ücretsiz', 'Yeni'
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? 'Tümü';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F4),
        title: const Text('Keşfet', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = category == _category;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = category),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Bu kategoride bugün için içerik yok.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = filtered[index];
                      return _ExploreEventCard(
                        event: event,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Event> get _filteredEvents {
    final events = List<Event>.from(widget.events);
    if (_category == null || _category == 'Tümü') return events;

    return events.where((event) {
      final value = event.category.toLowerCase();
      return value == _category!.toLowerCase() || value.contains(_category!.toLowerCase());
    }).toList();
  }
}

class _ExploreEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _ExploreEventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(event.startsAt);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 84,
                height: 84,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: event.imageUrl == null
                    ? const Icon(Icons.event_outlined, size: 30)
                    : Image.network(
                        event.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.event_outlined, size: 30),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.category.toUpperCase(),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .7),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, height: 1.1),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      event.venueName == null ? 'Bugün · $time' : 'Bugün · $time · ${event.venueName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
