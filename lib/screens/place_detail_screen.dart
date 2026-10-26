import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/place.dart';
import '../services/saved_place_service.dart';

class PlaceDetailScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailScreen({
    super.key,
    required this.place,
  });

  @override
  State<PlaceDetailScreen> createState() =>
      _PlaceDetailScreenState();
}

class _PlaceDetailScreenState
    extends State<PlaceDetailScreen> {
  final SavedPlaceService _savedService =
      SavedPlaceService();

  bool _isSaved = false;
  bool _loadingSaved = true;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final saved =
          await _savedService.isSaved(
        widget.place.id,
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
        widget.place.id,
      );

      if (!mounted) return;

      setState(() {
        _isSaved = !_isSaved;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSaved
                ? 'Yer kayıtlarına eklendi.'
                : 'Yer kayıtlardan çıkarıldı.',
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

  Future<void> _openMaps() async {
    final place = widget.place;

    Uri? uri;

    if (place.latitude != null &&
        place.longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}',
      );
    } else if (place.address != null &&
        place.address!.trim().isNotEmpty) {
      final query =
          Uri.encodeComponent(
        '${place.name}, ${place.address}',
      );

      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query',
      );
    }

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bu yer için konum bilgisi bulunamadı.',
          ),
        ),
      );
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google Haritalar açılamadı.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

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
          'YER',
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
                  ? Icons.bookmark
                  : Icons.bookmark_border,
            ),
          ),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          6,
          16,
          16,
        ),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(24),
              border: Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),
            child: Icon(
              place.category == 'Müze'
                  ? Icons.museum_outlined
                  : place.outdoor == true
                      ? Icons.landscape_outlined
                      : Icons.place_outlined,
              size: 68,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            place.category.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            place.name,
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),

          if (place.shortDescription != null &&
              place.shortDescription!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              place.shortDescription!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],

          if (place.longDescription != null &&
              place.longDescription!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              place.longDescription!,
              style: const TextStyle(fontSize: 14, height: 1.55),
            ),
          ],

          const SizedBox(height: 12),

          _InfoRow(
            icon: Icons.location_on_outlined,
            title: 'Adres',
            value: _displayValue(place.address),
          ),

          _InfoRow(
            icon: Icons.schedule_outlined,
            title: 'Tahmini süre',
            value: place.visitDurationMin == null ? 'Veri yok' : '${place.visitDurationMin} dakika',
          ),

          _InfoRow(
            icon: Icons.payments_outlined,
            title: 'Ücret',
            value: place.isFree == null ? 'Veri yok' : (place.isFree! ? 'Ücretsiz' : 'Ücretli'),
          ),

          _InfoRow(
            icon: Icons.local_parking_outlined,
            title: 'Otopark',
            value: place.parkingAvailable == null ? 'Veri yok' : (place.parkingAvailable! ? 'Var' : 'Yok'),
          ),

          _InfoRow(
            icon: Icons.child_friendly_outlined,
            title: 'Çocuklar için',
            value: place.kidsFriendly == null ? 'Veri yok' : (place.kidsFriendly! ? 'Uygun' : 'Uygun değil'),
          ),

          _InfoRow(
            icon: Icons.pets_outlined,
            title: 'Evcil hayvan',
            value: place.petFriendly == null ? 'Veri yok' : (place.petFriendly! ? 'Uygun' : 'Uygun değil'),
          ),

          _InfoRow(
            icon: Icons.wb_sunny_outlined,
            title: 'En iyi zaman',
            value: _displayValue(place.bestTime),
          ),

          _InfoRow(
            icon: Icons.home_work_outlined,
            title: 'Alan türü',
            value: place.indoor == true && place.outdoor == true
                ? 'Kapalı ve açık alan'
                : place.indoor == true
                    ? 'Kapalı alan'
                    : place.outdoor == true
                        ? 'Açık alan'
                        : 'Veri yok',
          ),

          if (place.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: place.tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor:
                          Colors.white,
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: _openMaps,
            icon: const Icon(
              Icons.navigation_outlined,
            ),
            label: const Text(
              'YOL TARİFİ',
            ),
            style: FilledButton.styleFrom(
              minimumSize:
                  const Size.fromHeight(46),
              backgroundColor:
                  Colors.black,
              foregroundColor:
                  Colors.white,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(17),
              ),
            ),
          ),

        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: OutlinedButton.icon(
          onPressed: _loadingSaved ? null : _toggleSaved,
          icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
          label: Text(_isSaved ? 'KAYITLARDAN ÇIKAR' : 'KAYDET'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            foregroundColor: Colors.black,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}

String _displayValue(String? value) => value == null || value.trim().isEmpty ? 'Veri yok' : value.trim();

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
      margin:
          const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                const SizedBox(height: 3),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
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
