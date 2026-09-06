import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../services/saved_event_service.dart';
import 'event_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  final List<Event> events;

  const SavedScreen({
    super.key,
    required this.events,
  });

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final SavedEventService _savedService = SavedEventService();

  Set<String> _savedIds = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final ids = await _savedService.getSavedIds();

    if (!mounted) return;

    setState(() {
      _savedIds = ids;
      _loading = false;
    });
  }

  Future<void> _remove(Event event) async {
    await _savedService.remove(event.id);

    if (!mounted) return;

    setState(() {
      _savedIds.remove(event.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedEvents = widget.events
        .where((event) => _savedIds.contains(event.id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F4),
        elevation: 0,
        title: const Text(
          'KAYITLARIM',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : savedEvents.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    30,
                  ),
                  itemCount: savedEvents.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final event = savedEvents[index];

                    return _SavedEventCard(
                      event: event,
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
                      onRemove: () => _remove(event),
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Henüz kayıt yok',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Beğendiğin etkinlikleri kaydettiğinde '
              'burada görebileceksin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedEventCard({
    required this.event,
    required this.onTap,
    required this.onRemove,
  });

  String _metaText() {
    final time = DateFormat('HH:mm').format(event.startsAt);

    if (event.venueName == null ||
        event.venueName!.trim().isEmpty) {
      return 'Bugün · $time';
    }

    return 'Bugün · $time · ${event.venueName}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 78,
                height: 78,
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
                        letterSpacing: .7,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
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
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.bookmark_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}