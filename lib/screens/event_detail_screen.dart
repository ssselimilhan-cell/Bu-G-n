import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event.dart';
import '../services/saved_event_service.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() =>
      _EventDetailScreenState();
}

class _EventDetailScreenState
    extends State<EventDetailScreen> {
  final SavedEventService _savedService =
      SavedEventService();

  bool _isSaved = false;
  bool _loadingSaved = true;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    try {
      final saved = await _savedService.isSaved(
        widget.event.id,
      );

      if (!mounted) return;

      setState(() {
        _isSaved = saved;
        _loadingSaved = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingSaved = false;
      });
    }
  }

  Future<void> _toggleSaved() async {
    try {
      await _savedService.toggleSaved(
        widget.event.id,
      );

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
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kayıt işlemi gerçekleştirilemedi.',
          ),
        ),
      );
    }
  }

  Future<void> _openTicketPage() async {
    final ticketUrl = widget.event.ticketUrl;

    if (ticketUrl == null ||
        ticketUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bu etkinlik için bilet bağlantısı bulunamadı.',
          ),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(ticketUrl);

    if (uri == null ||
        !(uri.scheme == 'http' ||
            uri.scheme == 'https')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bilet bağlantısı geçerli değil.',
          ),
        ),
      );
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bilet sayfası açılamadı.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bilet sayfası açılamadı.',
          ),
        ),
      );
    }
  }

  Future<void> _openNavigation() async {
    final address = widget.event.address;

    if (address == null ||
        address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bu etkinlik için adres bilgisi bulunamadı.',
          ),
        ),
      );
      return;
    }

    final encodedAddress =
        Uri.encodeComponent(address);

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Harita açılamadı.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harita açılamadı.',
          ),
        ),
      );
    }
  }

  String _dateText() {
    return DateFormat(
      'd MMMM yyyy, EEEE · HH:mm',
      'tr_TR',
    ).format(
      widget.event.startsAt.toLocal(),
    );
  }

  String _priceText() {
    final min = widget.event.priceMin;
    final max = widget.event.priceMax;

    if (min == null && max == null) {
      return 'Fiyat bilgisi bulunmuyor';
    }

    if (min == 0 &&
        (max == null || max == 0)) {
      return 'Ücretsiz';
    }

    if (min != null &&
        max != null &&
        min != max) {
      return '${min.round()} - ${max.round()} TL';
    }

    final price = min ?? max;

    if (price == null) {
      return 'Fiyat bilgisi bulunmuyor';
    }

    return '${price.round()} TL';
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    final hasImage =
        event.imageUrl != null &&
        event.imageUrl!.trim().isNotEmpty;

    final hasVenue =
        event.venueName != null &&
        event.venueName!.trim().isNotEmpty;

    final hasAddress =
        event.address != null &&
        event.address!.trim().isNotEmpty;

    final hasDescription =
        event.description != null &&
        event.description!.trim().isNotEmpty;

    final hasTicketUrl =
        event.ticketUrl != null &&
        event.ticketUrl!.trim().isNotEmpty;

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
          'ETKİNLİK',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            onPressed:
                _loadingSaved
                    ? null
                    : _toggleSaved,
            icon: Icon(
              _isSaved
                  ? Icons.bookmark_rounded
                  : Icons
                      .bookmark_border_rounded,
            ),
          ),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        children: [
          Container(
            height: 235,
            clipBehavior:
                Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius:
                  BorderRadius.circular(26),
            ),
            child: hasImage
                ? Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) {
                      return const Center(
                        child: Icon(
                          Icons
                              .event_outlined,
                          color:
                              Colors.white,
                          size: 64,
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Icon(
                      Icons
                          .event_outlined,
                      color:
                          Colors.white,
                      size: 64,
                    ),
                  ),
          ),

          const SizedBox(height: 22),

          Text(
            event.category
                .toUpperCase(),
            style:
                const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: 1,
              color:
                  Colors.black54,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            event.title,
            style:
                const TextStyle(
              fontSize: 29,
              fontWeight:
                  FontWeight.w900,
              height: 1.05,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 20),

          _InfoCard(
            icon:
                Icons.calendar_month_outlined,
            title: 'Tarih ve saat',
            value: _dateText(),
          ),

          if (hasVenue)
            _InfoCard(
              icon:
                  Icons.location_on_outlined,
              title: 'Mekan',
              value:
                  event.venueName!,
            ),

          if (hasAddress)
            _InfoCard(
              icon:
                  Icons.place_outlined,
              title: 'Adres',
              value:
                  event.address!,
            ),

          _InfoCard(
            icon:
                Icons.payments_outlined,
            title: 'Bilet fiyatı',
            value:
                _priceText(),
          ),

          if (hasDescription) ...[
            const SizedBox(height: 20),
            const Text(
              'ETKİNLİK HAKKINDA',
              style:
                  TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              event.description!,
              style:
                  const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 24),

          if (hasTicketUrl)
            FilledButton.icon(
              onPressed:
                  _openTicketPage,
              icon: const Icon(
                Icons
                    .confirmation_number_outlined,
              ),
              label: const Text(
                'BİLET AL',
              ),
              style:
                  FilledButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(
                  56,
                ),
                backgroundColor:
                    Colors.black,
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    17,
                  ),
                ),
              ),
            ),

          if (hasTicketUrl)
            const SizedBox(height: 10),

          if (hasAddress)
            OutlinedButton.icon(
              onPressed:
                  _openNavigation,
              icon: const Icon(
                Icons.navigation_outlined,
              ),
              label: const Text(
                'YOL TARİFİ',
              ),
              style:
                  OutlinedButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(
                  56,
                ),
                foregroundColor:
                    Colors.black,
                side:
                    const BorderSide(
                  color:
                      Colors.black12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    17,
                  ),
                ),
              ),
            ),

          if (hasAddress)
            const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed:
                _toggleSaved,
            icon: Icon(
              _isSaved
                  ? Icons.bookmark_rounded
                  : Icons
                      .bookmark_border_rounded,
            ),
            label: Text(
              _isSaved
                  ? 'KAYITLARDAN ÇIKAR'
                  : 'KAYDET',
            ),
            style:
                OutlinedButton.styleFrom(
              minimumSize:
                  const Size.fromHeight(
                56,
              ),
              foregroundColor:
                  Colors.black,
              side:
                  const BorderSide(
                color:
                    Colors.black12,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  17,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Bu etkinlik Ticketmaster üzerinden sağlanmaktadır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color:
                  Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  Colors.grey.shade100,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                    color:
                        Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    height: 1.3,
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
