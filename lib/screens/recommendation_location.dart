part of 'recommendation_screen.dart';

extension _RecommendationLocationMethods on _RecommendationScreenState {
  Future<void> _tryGetLocationSilently() async {
    try {
      final position =
          await _getLocation(
        requestPermission: false,
      );

      if (!mounted) {
        return;
      }

      if (position != null) {
        setState(() {
          _userPosition = position;
        });
      }
    } catch (_) {}
  }

  Future<Position?> _getLocation({
    required bool requestPermission,
  }) async {
    final enabled =
        await Geolocator
            .isLocationServiceEnabled();

    if (!enabled) {
      return null;
    }

    var permission =
        await Geolocator
            .checkPermission();

    if (permission ==
        LocationPermission.denied) {
      if (!requestPermission) {
        return null;
      }

      permission =
          await Geolocator
              .requestPermission();
    }

    if (permission ==
            LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator
        .getCurrentPosition(
      locationSettings:
          const LocationSettings(
        accuracy:
            LocationAccuracy.medium,
      ),
    );
  }

  Future<void> _refreshLocation() async {
    if (_locationLoading) {
      return;
    }

    try {
      final currentPermission = await Geolocator.checkPermission();
      if (currentPermission == LocationPermission.denied ||
          currentPermission == LocationPermission.deniedForever) {
        if (!mounted) return;
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konum neden gerekli?'),
            content: const Text(
              'Konumun, etkinlikleri sana olan uzaklığına göre sıralamak için kullanılır. '
              'İsteğe bağlıdır. İzin vermezsen de seçtiğin şehirdeki etkinlikleri ve gezilecek yerleri görebilirsin.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ŞİMDİ DEĞİL'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DEVAM ET'),
              ),
            ],
          ),
        );
        if (shouldContinue != true) return;
        if (currentPermission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
          return;
        }
      }
    } catch (_) {
      // Permission explanation is best-effort; discovery remains usable
      // without location.
    }

    if (!mounted) return;
    setState(() {
      _locationLoading = true;
    });

    try {
      final position =
          await _getLocation(
        requestPermission: true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _userPosition = position;
        _locationLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _locationLoading = false;
      });
    }
  }


  double _locationScore(
    double? latitude,
    double? longitude,
  ) {
    final position =
        _userPosition;

    if (position == null ||
        latitude == null ||
        longitude == null) {
      return 0;
    }

    final distance =
        Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          latitude,
          longitude,
        ) /
            1000;

    if (distance <= 2) {
      return 40;
    }

    if (distance <= 5) {
      return 30;
    }

    if (distance <= 10) {
      return 20;
    }

    if (distance <= 15) {
      return 10;
    }

    if (distance <= 25) {
      return 0;
    }

    return -15;
  }

  double? _distanceFromUser(
    double? latitude,
    double? longitude,
  ) {
    final position =
        _userPosition;

    if (position == null ||
        latitude == null ||
        longitude == null) {
      return null;
    }

    return Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          latitude,
          longitude,
        ) /
        1000;
  }

  String _distanceLabel(
    double? distanceKm,
  ) {
    if (distanceKm == null) {
      return '';
    }

    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }

    return '${distanceKm.toStringAsFixed(1)} km';
  }


  Widget _buildLocationStatus() {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        border:
            Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child:
          Row(
        children: [
          Icon(
            _userPosition != null
                ? Icons
                    .my_location_rounded
                : Icons
                    .location_off_outlined,
            size: 18,
          ),
          const SizedBox(
            width: 7,
          ),
          Expanded(
            child:
                Text(
              _userPosition != null
                  ? 'Konumuna göre sıralanıyor.'
                  : 'Konum olmadan Ankara geneli sıralanıyor.',
              style:
                  const TextStyle(
                fontSize:
                    12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed:
                _locationLoading
                    ? null
                    : _refreshLocation,
            child:
                const Text(
              'KONUM',
              style:
                  TextStyle(
                fontSize:
                    10,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }


}
