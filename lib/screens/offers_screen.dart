import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/place.dart';
import '../services/city_preference_service.dart';
import '../services/place_service.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  final PlaceService _placeService = PlaceService();

  String _city = CityPreferenceService.defaultCity;
  List<Map<String, dynamic>> _offers = [];
  Map<String, Place> _placesById = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final cityService = CityPreferenceService();
      final city = await cityService.getSelectedCity();
      final places = await _placeService.getPlaces(city: city, limit: 500);
      final placesById = <String, Place>{
        for (final place in places) place.id: place,
      };
      final placeIds = placesById.keys.toList();

      List<Map<String, dynamic>> offers = [];
      if (placeIds.isNotEmpty) {
        final rows = await _client
            .from('offers')
            .select('id, title, description, starts_at, ends_at, discount_text, source_url, price_before, price_after, conditions, redemption_text, featured, place_id')
            .eq('is_active', true)
            .inFilter('place_id', placeIds)
            .order('featured', ascending: false)
            .order('starts_at', ascending: true)
            .limit(100);

        final now = DateTime.now();
        offers = rows
            .whereType<Map<String, dynamic>>()
            .where((offer) {
              final start = DateTime.tryParse(offer['starts_at']?.toString() ?? '');
              final end = DateTime.tryParse(offer['ends_at']?.toString() ?? '');
              return (start == null || !start.isAfter(now)) &&
                  (end == null || !end.isBefore(now));
            })
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _city = city;
        _placesById = placesById;
        _offers = offers;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Kampanyalar yüklenemedi. Bağlantını kontrol edip tekrar deneyebilirsin.';
      });
    }
  }

  Future<void> _openOffer(Map<String, dynamic> offer) async {
    final rawUrl = offer['source_url']?.toString();
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu kampanya için dış bağlantı eklenmemiş.')),
        );
      }
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kampanya bağlantısı açılamadı.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kampanya bağlantısı açılamadı.')),
        );
      }
    }
  }

  String _priceText(Map<String, dynamic> offer) {
    final before = (offer['price_before'] as num?)?.toDouble();
    final after = (offer['price_after'] as num?)?.toDouble();
    if (before == null && after == null) return '';
    if (before != null && after != null) {
      return '${before.toStringAsFixed(0)} TL → ${after.toStringAsFixed(0)} TL';
    }
    return '${(after ?? before)!.toStringAsFixed(0)} TL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        surfaceTintColor: Colors.transparent,
        title: Text('$_city fırsatları', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: _loadOffers, icon: const Icon(Icons.refresh), tooltip: 'Yenile'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _MessageState(message: _error!, onRetry: _loadOffers)
              : _offers.isEmpty
                  ? const _MessageState(
                      message: 'Seçtiğin şehirde şu anda listelenecek aktif kampanya bulunamadı.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOffers,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _offers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final offer = _offers[index];
                          final place = _placesById[offer['place_id']?.toString()];
                          final discount = offer['discount_text']?.toString();
                          final price = _priceText(offer);
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _openOffer(offer),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.local_offer_outlined, size: 26),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            offer['title']?.toString() ?? 'Kampanya',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                        if (offer['featured'] == true)
                                          const Icon(Icons.star_rounded, size: 20),
                                      ],
                                    ),
                                    if (discount != null && discount.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(discount, style: const TextStyle(fontWeight: FontWeight.w800)),
                                    ],
                                    if (price.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    ],
                                    if ((offer['description'] ?? '').toString().trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(offer['description'].toString(), style: const TextStyle(height: 1.4)),
                                    ],
                                    if (place != null) ...[
                                      const SizedBox(height: 10),
                                      Text(place.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      if ((place.address ?? '').trim().isNotEmpty)
                                        Text(place.address!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    ],
                                    if ((offer['conditions'] ?? '').toString().trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text('Koşullar: ${offer['conditions']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    ],
                                    if ((offer['redemption_text'] ?? '').toString().trim().isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Text('Kullanım: ${offer['redemption_text']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    ],
                                    const SizedBox(height: 12),
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('KAMPANYAYA GİT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                                        SizedBox(width: 5),
                                        Icon(Icons.open_in_new, size: 15),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _MessageState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_offer_outlined, size: 44),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.4)),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onRetry, child: const Text('Tekrar dene')),
            ],
          ],
        ),
      ),
    );
  }
}
