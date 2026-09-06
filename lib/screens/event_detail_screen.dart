import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../services/saved_event_service.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final SavedEventService _savedService = SavedEventService();

  bool _isSaved = false;
  bool _loadingSaved = true;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final saved = await _savedService.isSaved(widget.event.id);

    if (!mounted) return;

    setState(() {
      _isSaved = saved;
      _loadingSaved = false;
    });
  }

  Future<void> _toggleSaved() async {
    await _savedService.toggleSaved(widget.event.id);

    if (!mounted) return;

    setState(() {
      _isSaved = !_isSaved;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSaved
              ? 'Etkinlik kayıtlarına eklendi.'
              : 'Etkinlik kayıtlardan çıkarıldı.',
        ),
      ),
    );
  }

  String _dateText() {
    return DateFormat(
      'd MMMM EEEE · HH:mm',
      'tr_TR',
    ).format(widget.event.startsAt);
  }

  String _priceText() {
    final min = widget.event.priceMin;
    final max = widget.event.priceMax;

    if (min == null && max == null) {
      return 'Fiyat bilgisi yok';
    }

    if (min == 0 && (max == null || max == 0)) {
      return 'Ücretsiz';
    }

    if (min != null && max != null && min != max) {
      return '${min.round()} - ${max.round()} TL';
    }

    final price = min ?? max;

    if (price == null) {
      return 'Fiyat bilgisi yok';
    }

    return '${price.round()} TL';
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F4),
        elevation: 0,
        title: const Text(
          'ETKİNLİK',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadingSaved ? null : _toggleSaved,
            icon: Icon(
              _isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        children: [
          Container(
            height: 230,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(26),
            ),
            child: event.imageUrl == null
                ? const Center(
                    child: Icon(
                      Icons.event_outlined,
                      color: Colors.white,
                      size: 60,
                    ),
                  )
                : Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Center(
                        child: Icon(
                          Icons.event_outlined,
                          color: Colors.white,
                          size: 60,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 22),
          Text(
            event.category.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 18),
          _InfoRow(
            icon: Icons.schedule_outlined,
            title: 'Tarih',
            value: _dateText(),
          ),
          if (event.venueName != null &&
              event.venueName!.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.location_on_outlined,
              title: 'Mekan',
              value: event.venueName!,
            ),
          if (event.address != null &&
              event.address!.trim().isNotEmpty)
            _InfoRow(
              icon: Icons.place_outlined,
              title: 'Adres',
              value: event.address!,
            ),
          _InfoRow(
            icon: Icons.payments_outlined,
            title: 'Fiyat',
            value: _priceText(),
          ),
          if (event.description != null &&
              event.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'HAKKINDA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              event.description!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.black87,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _toggleSaved,
            icon: Icon(
              _isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
            label: Text(
              _isSaved ? 'KAYITLARDAN ÇIKAR' : 'KAYDET',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}