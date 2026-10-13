import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event.dart';
import '../models/place.dart';
import '../services/city_preference_service.dart';
import '../services/event_service.dart';
import '../services/place_service.dart';
import 'event_detail_screen.dart';
import 'place_detail_screen.dart';

class MapExploreScreen extends StatefulWidget {
  const MapExploreScreen({super.key});

  @override
  State<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends State<MapExploreScreen> {
  final _placesService = PlaceService();
  final _eventsService = EventService();
  final _mapController = MapController();
  String _city = CityPreferenceService.defaultCity;
  List<Place> _places = [];
  List<Event> _events = [];
  bool _loading = true;
  String? _error;
  bool _showEvents = true;
  bool _showPlaces = true;

  static const Map<String, LatLng> _cityCenters = {
    'Adana': LatLng(37.0000, 35.3213),
    'Adıyaman': LatLng(37.7648, 38.2786),
    'Afyonkarahisar': LatLng(38.7507, 30.5567),
    'Ağrı': LatLng(39.7191, 43.0506),
    'Amasya': LatLng(40.6499, 35.8353),
    'Ankara': LatLng(39.9334, 32.8597),
    'Antalya': LatLng(36.8969, 30.7133),
    'Artvin': LatLng(41.1828, 41.8183),
    'Aydın': LatLng(37.8560, 27.8416),
    'Balıkesir': LatLng(39.6484, 27.8826),
    'Bilecik': LatLng(40.0567, 30.0665),
    'Bingöl': LatLng(38.8854, 40.4966),
    'Bitlis': LatLng(38.4006, 42.1095),
    'Bolu': LatLng(40.7350, 31.6061),
    'Burdur': LatLng(37.7203, 30.2908),
    'Bursa': LatLng(40.1885, 29.0610),
    'Çanakkale': LatLng(40.1553, 26.4142),
    'Çankırı': LatLng(40.6013, 33.6134),
    'Çorum': LatLng(40.5506, 34.9556),
    'Denizli': LatLng(37.7765, 29.0864),
    'Diyarbakır': LatLng(37.9144, 40.2306),
    'Edirne': LatLng(41.6818, 26.5623),
    'Elazığ': LatLng(38.6748, 39.2225),
    'Erzincan': LatLng(39.7500, 39.5000),
    'Erzurum': LatLng(39.9055, 41.2658),
    'Eskişehir': LatLng(39.7667, 30.5256),
    'Gaziantep': LatLng(37.0662, 37.3833),
    'Giresun': LatLng(40.9128, 38.3895),
    'Gümüşhane': LatLng(40.4603, 39.4814),
    'Hakkâri': LatLng(37.5744, 43.7408),
    'Hatay': LatLng(36.2021, 36.1600),
    'Isparta': LatLng(37.7648, 30.5566),
    'Mersin': LatLng(36.8121, 34.6415),
    'İstanbul': LatLng(41.0082, 28.9784),
    'İzmir': LatLng(38.4237, 27.1428),
    'Kars': LatLng(40.6013, 43.0975),
    'Kastamonu': LatLng(41.3887, 33.7827),
    'Kayseri': LatLng(38.7205, 35.4826),
    'Kırklareli': LatLng(41.7351, 27.2252),
    'Kırşehir': LatLng(39.1425, 34.1709),
    'Kocaeli': LatLng(40.8533, 29.8815),
    'Konya': LatLng(37.8746, 32.4932),
    'Kütahya': LatLng(39.4167, 29.9833),
    'Malatya': LatLng(38.3552, 38.3095),
    'Manisa': LatLng(38.6191, 27.4289),
    'Kahramanmaraş': LatLng(37.5753, 36.9228),
    'Mardin': LatLng(37.3212, 40.7245),
    'Muğla': LatLng(37.2153, 28.3636),
    'Muş': LatLng(38.9462, 41.7539),
    'Nevşehir': LatLng(38.6244, 34.7239),
    'Niğde': LatLng(37.9698, 34.6766),
    'Ordu': LatLng(40.9839, 37.8764),
    'Rize': LatLng(41.0201, 40.5234),
    'Sakarya': LatLng(40.6940, 30.4358),
    'Samsun': LatLng(41.2867, 36.3300),
    'Siirt': LatLng(37.9333, 41.9500),
    'Sinop': LatLng(42.0268, 35.1551),
    'Sivas': LatLng(39.7477, 37.0179),
    'Tekirdağ': LatLng(40.9780, 27.5110),
    'Tokat': LatLng(40.3167, 36.5500),
    'Trabzon': LatLng(41.0027, 39.7168),
    'Tunceli': LatLng(39.1079, 39.5401),
    'Şanlıurfa': LatLng(37.1674, 38.7955),
    'Uşak': LatLng(38.6823, 29.4082),
    'Van': LatLng(38.5012, 43.3730),
    'Yozgat': LatLng(39.8181, 34.8147),
    'Zonguldak': LatLng(41.4564, 31.7987),
    'Aksaray': LatLng(38.3687, 34.0370),
    'Bayburt': LatLng(40.2552, 40.2249),
    'Karaman': LatLng(37.1759, 33.2287),
    'Kırıkkale': LatLng(39.8468, 33.5153),
    'Batman': LatLng(37.8812, 41.1351),
    'Şırnak': LatLng(37.5164, 42.4611),
    'Bartın': LatLng(41.6344, 32.3375),
    'Ardahan': LatLng(41.1105, 42.7022),
    'Iğdır': LatLng(39.9237, 44.0450),
    'Yalova': LatLng(40.6500, 29.2667),
    'Karabük': LatLng(41.2061, 32.6204),
    'Kilis': LatLng(36.7184, 37.1212),
    'Osmaniye': LatLng(37.0742, 36.2478),
    'Düzce': LatLng(40.8438, 31.1565),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final city = await CityPreferenceService().getSelectedCity();
      final results = await Future.wait([
        _placesService.getPlaces(city: city, limit: 300),
        _eventsService.getUpcomingEvents(city: city, days: 90, limit: 300),
      ]);
      if (!mounted) return;
      setState(() {
        _city = city;
        _places = results[0] as List<Place>;
        _events = results[1] as List<Event>;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(_cityCenters[_city] ?? const LatLng(39.0, 35.0), 11);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Harita verileri yüklenemedi.'; });
    }
  }

  List<Marker> get _markers {
    final markers = <Marker>[];
    if (_showPlaces) {
      for (final place in _places) {
        if (place.latitude == null || place.longitude == null) continue;
        markers.add(Marker(
          point: LatLng(place.latitude!, place.longitude!),
          width: 54,
          height: 58,
          child: GestureDetector(
            onTap: () => _showPlace(place),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
                  ),
                  child: Icon(_placeIcon(place), size: 20),
                ),
                const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black),
              ],
            ),
          ),
        ));
      }
    }
    if (_showEvents) {
      for (final event in _events) {
        if (event.latitude == null || event.longitude == null) continue;
        markers.add(Marker(
          point: LatLng(event.latitude!, event.longitude!),
          width: 48,
          height: 52,
          child: GestureDetector(
            onTap: () => _showEvent(event),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.deepOrange,
                  child: Icon(Icons.event, color: Colors.white, size: 19),
                ),
                Icon(Icons.arrow_drop_down, size: 15, color: Colors.deepOrange),
              ],
            ),
          ),
        ));
      }
    }
    return markers;
  }

  IconData _placeIcon(Place place) {
    final category = place.category.toLowerCase();
    if (category.contains('müze')) return Icons.museum_outlined;
    if (category.contains('park') || category.contains('doğa')) return Icons.park_outlined;
    if (category.contains('hayvan')) return Icons.pets_outlined;
    if (category.contains('tarih')) return Icons.account_balance_outlined;
    return Icons.place_outlined;
  }

  void _showPlace(Place place) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.category.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(place.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              if (place.shortDescription?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(place.shortDescription!, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)));
                },
                child: const Text('YER DETAYINI AÇ'),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showEvent(Event event) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ETKİNLİK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(event.venueName ?? event.category),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)));
                },
                child: const Text('ETKİNLİĞİ AÇ'),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = _cityCenters[_city] ?? const LatLng(39.0, 35.0);
    return Scaffold(
      appBar: AppBar(
        title: Text('$_city haritası', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: _load, tooltip: 'Yenile', icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: _load, child: const Text('Tekrar dene')),
                ]))
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(initialCenter: center, initialZoom: 11),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.bugun.app',
                          maxZoom: 19,
                        ),
                        MarkerLayer(markers: _markers),
                        RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              '© OpenStreetMap contributors',
                              onTap: () => launchUrl(
                                Uri.parse('https://www.openstreetmap.org/copyright'),
                                mode: LaunchMode.externalApplication,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            selected: _showPlaces,
                            avatar: const Icon(Icons.place_outlined, size: 18),
                            label: Text('Yerler (${_places.where((p) => p.latitude != null && p.longitude != null).length})'),
                            onSelected: (v) => setState(() => _showPlaces = v),
                            backgroundColor: Colors.white,
                          ),
                          FilterChip(
                            selected: _showEvents,
                            avatar: const Icon(Icons.event_outlined, size: 18),
                            label: Text('Etkinlikler (${_events.where((e) => e.latitude != null && e.longitude != null).length})'),
                            onSelected: (v) => setState(() => _showEvents = v),
                            backgroundColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    if (_markers.isEmpty)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 20,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              'Bu şehir için harita işaretleri henüz yok. Yer verileri eklendikçe müze, park, hayvanat bahçesi ve etkinlikler burada işaretlenecek.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
