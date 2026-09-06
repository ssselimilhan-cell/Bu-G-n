import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('d MMMM · HH:mm', 'tr_TR').format(event.startsAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _heroImage(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _InfoRow(icon: Icons.schedule, text: time),
                  if (event.venueName != null) ...[
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.place_outlined, text: event.venueName!),
                  ],
                  if (event.address != null) ...[
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.location_on_outlined, text: event.address!),
                  ],
                  if (event.priceMin != null || event.priceMax != null) ...[
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.payments_outlined, text: _priceText()),
                  ],
                  if (event.description != null && event.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'DETAYLAR',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.description!,
                      style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                    ),
                  ],
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.bookmark_border),
                          label: const Text('KAYDET'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('HARİTADA'),
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
    );
  }

  Widget _heroImage() {
    if (event.imageUrl == null || event.imageUrl!.trim().isEmpty) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: Icon(Icons.event_outlined, color: Colors.white70, size: 56)),
      );
    }

    return Image.network(
      event.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: Colors.black,
        child: Center(child: Icon(Icons.event_outlined, color: Colors.white70, size: 56)),
      ),
    );
  }

  String _priceText() {
    if (event.priceMin != null && event.priceMax != null && event.priceMin != event.priceMax) {
      return '${event.priceMin!.round()}–${event.priceMax!.round()} TL';
    }
    final price = event.priceMin ?? event.priceMax;
    if (price == null || price == 0) return 'Ücretsiz';
    return '${price.round()} TL';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: Colors.black54),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.25),
          ),
        ),
      ],
    );
  }
}
