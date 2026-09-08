import 'package:flutter/material.dart';

import '../models/place.dart';
import '../services/place_service.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({
    super.key,
  });

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final PlaceService _placeService = PlaceService();

  List<Place> _places = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _loading = true;
    });

    try {
      final places = await _placeService.getPlaces(
        city: 'Ankara',
        limit: 50,
      );

      if (!mounted) return;

      setState(() {
        _places = places;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _places = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Kayıt',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _places.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadPlaces,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _places.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _SavedPlaceCard(
                        place: _places[index],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 48,
            ),
            SizedBox(height: 14),
            Text(
              'Henüz kayıtlı yer yok.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Beğendiğin yerleri daha sonra kolayca bulmak için kaydedebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedPlaceCard extends StatelessWidget {
  final Place place;

  const _SavedPlaceCard({
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.place_outlined,
                size: 30,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
