import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CinemaScreen extends StatefulWidget {
  const CinemaScreen({super.key, required this.city});

  final String city;

  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen> {
  late Future<_CinemaData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant CinemaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city) {
      _future = _load();
    }
  }

  Future<_CinemaData> _load() async {
    final client = Supabase.instance.client;
    final venues = await client
        .from('cinema_venues')
        .select('id,name,city,address,website,source_url')
        .eq('is_active', true)
        .ilike('city', widget.city.trim())
        .order('name')
        .limit(100);

    final screenings = await client
        .from('cinema_screenings')
        .select('id,starts_at,language,format,ticket_url,source_url,cinema_venues!inner(name,city,address),cinema_movies!inner(title,poster_url,age_rating,overview)')
        .eq('is_active', true)
        .ilike('cinema_venues.city', widget.city.trim())
        .gte('starts_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at')
        .limit(100);

    return _CinemaData(
      venues: venues.whereType<Map<String, dynamic>>().toList(),
      screenings: screenings.whereType<Map<String, dynamic>>().toList(),
    );
  }

  Future<void> _openLink(dynamic raw) async {
    if (raw is! String || raw.trim().isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final next = _load();
        setState(() => _future = next);
        await next;
      },
      child: FutureBuilder<_CinemaData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 100),
                const Icon(Icons.movie_outlined, size: 52),
                const SizedBox(height: 12),
                const Text('Sinema bilgileri şu anda yüklenemiyor.', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('İnternet bağlantını kontrol edip ekranı yenileyebilirsin.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
              ],
            );
          }

          final data = snapshot.data!;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Text('${widget.city} sinemaları', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Salon ve seans bilgileri, yetkili veri sağlayıcıları bağlandığında burada güncel olarak gösterilir.', style: TextStyle(height: 1.4)),
              const SizedBox(height: 20),
              const Text('VİZYONDAKİ SEANSLAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 8),
              if (data.screenings.isEmpty)
                _empty('Bu şehir için henüz doğrulanmış seans verisi bulunmuyor.')
              else
                ...data.screenings.map((item) {
                  final movie = item['cinema_movies'] as Map<String, dynamic>? ?? {};
                  final venue = item['cinema_venues'] as Map<String, dynamic>? ?? {};
                  final date = DateTime.tryParse(item['starts_at']?.toString() ?? '')?.toLocal();
                  final dateText = date == null ? 'Saat bilgisi yok' : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.local_movies_outlined, size: 34),
                      title: Text(movie['title']?.toString() ?? 'Film', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${venue['name'] ?? 'Sinema salonu'}\n$dateText${item['format'] == null ? '' : ' • ${item['format']}'}${item['language'] == null ? '' : ' • ${item['language']}'}'),
                      isThreeLine: true,
                      trailing: item['ticket_url'] is String ? const Icon(Icons.open_in_new) : null,
                      onTap: () => _openLink(item['ticket_url'] ?? item['source_url']),
                    ),
                  );
                }),
              const SizedBox(height: 18),
              const Text('SİNEMA SALONLARI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 8),
              if (data.venues.isEmpty)
                _empty('Bu şehir için henüz doğrulanmış salon kaydı bulunmuyor.')
              else
                ...data.venues.map((venue) => Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.theaters_outlined),
                    title: Text(venue['name']?.toString() ?? 'Sinema', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(venue['address']?.toString() ?? venue['city']?.toString() ?? widget.city),
                    trailing: venue['website'] is String ? const Icon(Icons.open_in_new) : null,
                    onTap: () => _openLink(venue['website'] ?? venue['source_url']),
                  ),
                )),
            ],
          );
        },
      ),
    );
  }

  Widget _empty(String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.black12),
    ),
    child: Text(text, style: const TextStyle(height: 1.4)),
  );
}

class _CinemaData {
  const _CinemaData({required this.venues, required this.screenings});
  final List<Map<String, dynamic>> venues;
  final List<Map<String, dynamic>> screenings;
}
