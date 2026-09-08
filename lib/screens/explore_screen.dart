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
    } catch (_) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _selectedCategory ?? 'Ankara’yı keşfet',
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
    final selected = _selectedCategory ?? 'Tümü';

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

          return ChoiceChip(
            label: Text(category),
            selected: selected == category,
            onSelected: (_) => _selectCategory(category),
            selectedColor: Colors.black,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected == category
                  ? Colors.white
                  : Colors.black,
              fontWeight: FontWeight.w700,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadPlaces,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }

    if (_places.isEmpty) {
      return const Center(
        child: Text(
          'Bu kategoride henüz yer yok.',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
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
            onTap: () => _showDetails(place),
          );
        },
      ),
    );
  }

  void _showDetails(Place place) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                if (place.shortDescription != null)
                  Text(
                    place.shortDescription!,
                    style: const TextStyle(
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 16),
                if (place.address != null)
                  Text(place.address!),
                if (place.visitDurationMin != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Yaklaşık ${place.visitDurationMin} dakika',
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            '${place.name} için navigasyonu birazdan ekleyeceğiz.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.navigation_outlined,
                    ),
                    label: const Text('Rotayı oluştur'),
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconForCategory(place.category),
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      place.category,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    if (place.address != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        place.address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
