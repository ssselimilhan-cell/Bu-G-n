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

    List<Map<String, dynamic>> googleCinemas = [];
    String? googlePlacesMessage;
    try {
      final response = await client.functions.invoke(
        'google-cinemas',
        queryParameters: {'city': widget.city},
      );
      if (response.status == 200 && response.data is Map) {
        final results = (response.data as Map)['places'];
        if (results is List) {
          googleCinemas = results.whereType<Map<String, dynamic>>().toList();
        }
      } else {
        googlePlacesMessage = 'Google Places yanıtı alınamadı (HTTP ${response.status}).';
      }
    } catch (_) {
      googlePlacesMessage = 'Google Places API henüz yapılandırılmamış olabilir.';
    }

    List<Map<String, dynamic>> movies = [];
    String? tmdbMessage;
    try {
      final response = await client.functions.invoke(
        'tmdb-cinema',
        queryParameters: const {'category': 'now_playing', 'page': '1'},
      );
      if (response.status == 200 && response.data is Map) {
        final results = (response.data as Map)['results'];
        if (results is List) {
          movies = results.whereType<Map<String, dynamic>>().toList();
        }
      } else {
        tmdbMessage = 'TMDB yanıtı alınamadı (HTTP ${response.status}).';
      }
    } catch (_) {
      tmdbMessage = 'TMDB bağlantısı henüz yapılandırılmamış olabilir.';
    }

    return _CinemaData(
      venues: venues.whereType<Map<String, dynamic>>().toList(),
      googleCinemas: googleCinemas,
      googlePlacesMessage: googlePlacesMessage,
      screenings: screenings.whereType<Map<String, dynamic>>().toList(),
      movies: movies,
      tmdbMessage: tmdbMessage,
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
              const Text('Güncel seanslar için resmî sinema sağlayıcısının sayfasını açabilirsin. Uygulama, lisans sözleşmesi olmayan sitelerden seans verisi kopyalamaz.', style: TextStyle(height: 1.4)),
              const SizedBox(height: 12),
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.verified_outlined),
                  title: const Text('Paribu Cineverse — resmî seanslar'),
                  subtitle: const Text('Film, salon ve bilet bilgileri sağlayıcının kendi sitesinde'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openLink('https://www.paribucineverse.com/'),
                ),
              ),
              const SizedBox(height: 20),
              Text('${widget.city.toUpperCase()} SİNEMA SALONLARI', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 8),
              if (data.googlePlacesMessage != null)
                _empty('${data.googlePlacesMessage} Google Cloud Console üzerinden Places API (New) etkinleştirilmeli ve GOOGLE_PLACES_API_KEY Supabase Function Secret olarak eklenmeli.')
              else if (data.googleCinemas.isEmpty)
                _empty('Google Places bu şehir için sinema sonucu döndürmedi.')
              else
                ...data.googleCinemas.map((place) {
                  final displayName = place['displayName'];
                  final name = displayName is Map ? displayName['text']?.toString() : null;
                  final address = place['formattedAddress']?.toString() ?? '';
                  final mapUrl = place['googleMapsUri']?.toString();
                  final rating = place['rating']?.toString();
                  final website = place['websiteUri']?.toString();
                  final phone = place['nationalPhoneNumber']?.toString();
                  final hours = place['regularOpeningHours'];
                  final weekdayDescriptions = hours is Map ? hours['weekdayDescriptions'] : null;
                  final subtitleParts = <String>[
                    if (address.isNotEmpty) address,
                    if (rating != null) 'Google puanı: $rating',
                    if (phone != null && phone.isNotEmpty) phone,
                    if (weekdayDescriptions is List) weekdayDescriptions.whereType<String>().join(' • '),
                  ];
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.theaters_outlined),
                      title: Text(name ?? 'Sinema salonu', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(subtitleParts.join('\\n'), maxLines: 4, overflow: TextOverflow.ellipsis),
                      isThreeLine: subtitleParts.length > 1,
                      trailing: const Icon(Icons.map_outlined),
                      onTap: () => _openLink(mapUrl ?? website),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              const Text('TÜRKİYE’DE VİZYONDA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 8),
              if (data.tmdbMessage != null)
                _empty('${data.tmdbMessage} Yönetici TMDB API Read Access Token bilgisini Supabase Function Secret olarak eklemeli.')
              else if (data.movies.isEmpty)
                _empty('TMDB şu anda vizyondaki film listesini döndürmedi.')
              else
                ...data.movies.map((movie) {
                  final posterPath = movie['poster_path']?.toString();
                  final posterUrl = posterPath == null || posterPath.isEmpty
                      ? null
                      : 'https://image.tmdb.org/t/p/w342$posterPath';
                  final title = movie['title']?.toString() ?? 'İsimsiz film';
                  final release = movie['release_date']?.toString() ?? '';
                  final overview = movie['overview']?.toString() ?? '';
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: posterUrl == null
                          ? const SizedBox(width: 58, child: Icon(Icons.movie_outlined, size: 32))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                posterUrl,
                                width: 58,
                                height: 82,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(width: 58, child: Icon(Icons.movie_outlined)),
                              ),
                            ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text([
                        if (release.isNotEmpty) 'Vizyon tarihi: $release',
                        if (overview.isNotEmpty) overview,
                      ].join(' • '), maxLines: 3, overflow: TextOverflow.ellipsis),
                      isThreeLine: true,
                      onTap: () => _openLink('https://www.themoviedb.org/search?query=${Uri.encodeComponent(title)}'),
                    ),
                  );
                }),
              const SizedBox(height: 8),
              const Text(
                'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.35),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _openLink('https://www.themoviedb.org/'),
                  child: const Text('TMDB — The Movie Database'),
                ),
              ),
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
              const Text('KAYITLI SİNEMA SALONLARI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
  const _CinemaData({
    required this.venues,
    required this.googleCinemas,
    required this.googlePlacesMessage,
    required this.screenings,
    required this.movies,
    required this.tmdbMessage,
  });
  final List<Map<String, dynamic>> venues;
  final List<Map<String, dynamic>> googleCinemas;
  final String? googlePlacesMessage;
  final List<Map<String, dynamic>> screenings;
  final List<Map<String, dynamic>> movies;
  final String? tmdbMessage;
}
