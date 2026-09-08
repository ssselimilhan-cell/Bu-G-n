import 'package:flutter/material.dart';

import '../models/place.dart';
import '../services/place_service.dart';

class ExploreScreen extends StatefulWidget {
  final String? initialCategory;

  const ExploreScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PlaceService _placeService = PlaceService();

  List<Place> _places = [];
  bool _loading = true;
  String? _error;

  late String? _selectedCategory;

  final List<String> _categories = const [
    'Tümü',
    'Doğa',
    'Park',
    'Tarih',
    'Müze',
    'Kültür',
  ];

  @override
  void initState() {
    super.initState();

    _selectedCategory = widget.initialCategory;

    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final places = await _placeService.getPlaces(
        city: 'Ankara',
        category: _selectedCategory,
        limit: 100,
      );

      if (!mounted) return;

      setState(() {
        _places = places;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Yerler yüklenemedi.';
      });
    }
  }

  Future<void> _selectCategory(String category) async {
    setState(() {
      _selectedCategory =
          category == 'Tümü' ? null : category;
    });

    await _loadPlaces();
  }

  String _title() {
    if (_selectedCategory == null) {
      return 'Ankara’yı keşfet';
    }

    return _selectedCategory!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _title(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildCategories(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final activeCategory =
        _selectedCategory ?? 'Tümü';

    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected =
              category == activeCategory;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) {
              _selectCategory(category);
            },
            selectedColor: Colors.black,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: Colors.grey.shade200,
            ),
            labelStyle: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 44,
              ),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _loadPlaces,
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_places.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPlaces,
        child: ListView(
          children: const [
            SizedBox(height: 150),
            Center(
              child: Text(
                'Bu kategoride henüz yer yok.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlaces,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24,
        ),
        itemCount: _places.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final place = _places[index];

          return _PlaceCard(
            place: place,
            onTap: () {
              _showPlaceDetails(place);
            },
          );
        },
      ),
    );
  }

  void _showPlaceDetails(Place place) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  place.category,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (place.shortDescription != null)
                  Text(
                    place.shortDescription!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                const SizedBox(height: 16),
                if (place.address != null)
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: place.address!,
                  ),
                if (place.visitDurationMin != null)
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    text:
                        'Yaklaşık ${place.visitDurationMin} dk.',
                  ),
                if (place.isFree != null)
                  _InfoRow(
                    icon: place.isFree!
                        ? Icons.money_off
                        : Icons.payments_outlined,
                    text: place.isFree!
                        ? 'Ücretsiz'
                        : 'Ücretli olabilir',
                  ),
                if (place.kidsFriendly == true)
                  const _InfoRow(
                    icon: Icons.child_friendly_outlined,
                    text: 'Çocuklarla uygun',
                  ),
                if (place.parkingAvailable == true)
                  const _InfoRow(
                    icon: Icons.local_parking_outlined,
                    text: 'Otopark bilgisi mevcut',
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${place.name} için navigasyon özelliğini ekliyoruz.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.navigation_outlined,
                    ),
                    label: const Text(
                      'Rotayı oluştur',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: Icon(
                  _iconForCategory(place.category),
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                        if (place.verified)
                          const Icon(
                            Icons.verified,
                            size: 17,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      place.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (place.address != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        place.address!,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        if (place.isFree == true)
                          const _MiniLabel(
                            icon: Icons.money_off,
                            text: 'Ücretsiz',
                          ),
                        if (place.visitDurationMin != null)
                          _MiniLabel(
                            icon: Icons.schedule_outlined,
                            text:
                                '${place.visitDurationMin} dk',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Doğa':
        return Icons.park_outlined;
      case 'Park':
        return Icons.grass_outlined;
      case 'Tarih':
        return Icons.account_balance_outlined;
      case 'Müze':
        return Icons.museum_outlined;
      case 'Kültür':
        return Icons.theater_comedy_outlined;
      default:
        return Icons.place_outlined;
    }
  }
}

class _MiniLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniLabel({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
