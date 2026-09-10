import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event.dart';
import '../models/place.dart';
import '../services/event_service.dart';
import '../services/place_service.dart';
import 'event_detail_screen.dart';
import 'place_detail_screen.dart';

enum CompanionType {
  solo,
  couple,
  family,
  any,
}

enum BudgetType {
  free,
  low,
  medium,
  any,
}

enum DurationType {
  short,
  medium,
  fullDay,
  any,
}

enum InterestType {
  event,
  music,
  cinema,
  nature,
  park,
  culture,
  history,
  museum,
  any,
}

enum _ActivityType {
  event,
  place,
}

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({
    super.key,
  });

  @override
  State<RecommendationScreen> createState() =>
      _RecommendationScreenState();
}

class _RecommendationScreenState
    extends State<RecommendationScreen> {
  final EventService _eventService = EventService();
  final PlaceService _placeService = PlaceService();

  Set<CompanionType> _companions = {
    CompanionType.any,
  };

  Set<BudgetType> _budgets = {
    BudgetType.any,
  };

  Set<DurationType> _durations = {
    DurationType.any,
  };

  Set<InterestType> _interests = {
    InterestType.any,
  };

  Position? _userPosition;

  bool _loading = false;
  bool _locationLoading = false;
  bool _hasSearched = false;

  String? _error;

  List<_Activity> _results = <_Activity>[];
  final List<_Activity> _queue = <_Activity>[];

  @override
  void initState() {
    super.initState();
    _tryGetLocationSilently();
  }

  Future<void> _tryGetLocationSilently() async {
    try {
      final position = await _getLocation(
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
        await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      return null;
    }

    var permission =
        await Geolocator.checkPermission();

    if (permission ==
        LocationPermission.denied) {
      if (!requestPermission) {
        return null;
      }

      permission =
          await Geolocator.requestPermission();
    }

    if (permission ==
            LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
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

  void _toggleCompanion(
    CompanionType value,
  ) {
    setState(() {
      if (value ==
          CompanionType.any) {
        _companions = {
          CompanionType.any,
        };
        return;
      }

      _companions.remove(
        CompanionType.any,
      );

      if (_companions.contains(value)) {
        _companions.remove(value);
      } else {
        _companions.add(value);
      }

      if (_companions.isEmpty) {
        _companions = {
          CompanionType.any,
        };
      }
    });
  }

  void _toggleBudget(
    BudgetType value,
  ) {
    setState(() {
      if (value ==
          BudgetType.any) {
        _budgets = {
          BudgetType.any,
        };
        return;
      }

      _budgets.remove(
        BudgetType.any,
      );

      if (_budgets.contains(value)) {
        _budgets.remove(value);
      } else {
        _budgets.add(value);
      }

      if (_budgets.isEmpty) {
        _budgets = {
          BudgetType.any,
        };
      }
    });
  }

  void _toggleDuration(
    DurationType value,
  ) {
    setState(() {
      if (value ==
          DurationType.any) {
        _durations = {
          DurationType.any,
        };
        return;
      }

      _durations.remove(
        DurationType.any,
      );

      if (_durations.contains(value)) {
        _durations.remove(value);
      } else {
        _durations.add(value);
      }

      if (_durations.isEmpty) {
        _durations = {
          DurationType.any,
        };
      }
    });
  }

  void _toggleInterest(
    InterestType value,
  ) {
    setState(() {
      if (value ==
          InterestType.any) {
        _interests = {
          InterestType.any,
        };
        return;
      }

      _interests.remove(
        InterestType.any,
      );

      if (_interests.contains(value)) {
        _interests.remove(value);
      } else {
        _interests.add(value);
      }

      if (_interests.isEmpty) {
        _interests = {
          InterestType.any,
        };
      }
    });
  }

  Future<void> _generateRecommendations() async {
    setState(() {
      _loading = true;
      _hasSearched = true;
      _error = null;
      _results = <_Activity>[];
    });

    await _refreshLocation();

    try {
      final response =
          await Future.wait<Object>([
        _eventService.getUpcomingEvents(
          city: 'Ankara',
          days: 31,
          limit: 200,
        ),
        _placeService.getPlaces(
          city: 'Ankara',
          limit: 100,
        ),
      ]);

      final events =
          response[0] as List<Event>;

      final places =
          response[1] as List<Place>;

      final activities =
          <_Activity>[];

      for (final event in events) {
        final item =
            _makeEventActivity(event);

        if (item != null) {
          activities.add(item);
        }
      }

      for (final place in places) {
        final item =
            _makePlaceActivity(place);

        if (item != null) {
          activities.add(item);
        }
      }

      activities.sort(
        (a, b) =>
            b.score.compareTo(a.score),
      );

      final unique = <String>{};
      final filtered =
          <_Activity>[];

      for (final activity
          in activities) {
        final id =
            activity.id;

        if (!unique.add(id)) {
          continue;
        }

        filtered.add(activity);

        if (filtered.length >= 30) {
          break;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _results = filtered;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error =
            'Öneriler alınırken bir sorun oluştu.';
      });
    }
  }

  _Activity? _makeEventActivity(
    Event event,
  ) {
    final start =
        event.startsAt.toLocal();

    if (!start.isAfter(
      DateTime.now(),
    )) {
      return null;
    }

    final score =
        _scoreEvent(event);

    if (score <= 0) {
      return null;
    }

    return _Activity(
      type: _ActivityType.event,
      id: event.id,
      score: score,
      durationMinutes:
          _eventDuration(event),
      event: event,
      place: null,
    );
  }

  _Activity? _makePlaceActivity(
    Place place,
  ) {
    final score =
        _scorePlace(place);

    if (score <= 0) {
      return null;
    }

    return _Activity(
      type: _ActivityType.place,
      id: place.id,
      score: score,
      durationMinutes:
          _placeDuration(place),
      event: null,
      place: place,
    );
  }

  int _placeDuration(
    Place place,
  ) {
    final value =
        place.visitDurationMin;

    if (value == null ||
        value <= 0) {
      return 120;
    }

    return value.clamp(
      30,
      600,
    );
  }

  int _eventDuration(
    Event event,
  ) {
    final start =
        event.startsAt.toLocal();

    final end =
        event.endsAt?.toLocal();

    if (end != null &&
        end.isAfter(start)) {
      final minutes =
          end.difference(start).inMinutes;

      if (minutes >= 20 &&
          minutes <= 600) {
        return minutes;
      }
    }

    return 120;
  }

  double _scoreEvent(
    Event event,
  ) {
    if (!_matchesInterestForEvent(
      event,
    )) {
      return 0;
    }

    if (!_matchesBudgetForEvent(
      event,
    )) {
      return 0;
    }

    if (!_matchesDuration(
      _eventDuration(event),
    )) {
      return 0;
    }

    double score = 50;

    final text =
        _eventText(event);

    if (_interests.contains(
      InterestType.any,
    )) {
      score += 10;
    }

    for (final interest
        in _interests) {
      if (interest ==
          InterestType.any) {
        continue;
      }

      if (_eventMatchesInterest(
        text,
        interest,
      )) {
        score += 45;
      }
    }

    final start =
        event.startsAt.toLocal();

    final minutesUntil =
        start
            .difference(
              DateTime.now(),
            )
            .inMinutes;

    if (minutesUntil <= 180) {
      score += 20;
    } else if (minutesUntil <= 1440) {
      score += 14;
    } else if (minutesUntil <= 4320) {
      score += 7;
    }

    score +=
        _eventBudgetScore(event);

    score +=
        _companionScoreForEvent(
      text,
    );

    score +=
        _locationScore(
      event.latitude,
      event.longitude,
    );

    score +=
        event.trustScore / 10;

    return score;
  }

  double _scorePlace(
    Place place,
  ) {
    if (!_matchesInterestForPlace(
      place,
    )) {
      return 0;
    }

    if (!_matchesBudgetForPlace(
      place,
    )) {
      return 0;
    }

    if (!_matchesDuration(
      _placeDuration(place),
    )) {
      return 0;
    }

    double score = 45;

    final text =
        _placeText(place);

    if (_interests.contains(
      InterestType.any,
    )) {
      score += 10;
    }

    for (final interest
        in _interests) {
      if (interest ==
          InterestType.any) {
        continue;
      }

      if (_placeMatchesInterest(
        text,
        place,
        interest,
      )) {
        score += 48;
      }
    }

    if (_budgets.contains(
      BudgetType.any,
    )) {
      score += 8;
    }

    if (place.isFree == true) {
      score += 12;
    }

    if (place.verified) {
      score += 10;
    }

    score +=
        _companionScoreForPlace(
      place,
    );

    score +=
        _locationScore(
      place.latitude,
      place.longitude,
    );

    score +=
        place.trustScore / 10;

    return score;
  }

  String _eventText(
    Event event,
  ) {
    return [
      event.title,
      event.category,
      event.description ?? '',
      event.venueName ?? '',
    ].join(' ').toLowerCase();
  }

  String _placeText(
    Place place,
  ) {
    return [
      place.name,
      place.category,
      place.placeType ?? '',
      place.shortDescription ?? '',
      ...place.tags,
    ].join(' ').toLowerCase();
  }

  bool _matchesInterestForEvent(
    Event event,
  ) {
    if (_interests.contains(
      InterestType.any,
    )) {
      return true;
    }

    final text =
        _eventText(event);

    for (final interest
        in _interests) {
      if (_eventMatchesInterest(
        text,
        interest,
      )) {
        return true;
      }
    }

    return false;
  }

  bool _eventMatchesInterest(
    String text,
    InterestType interest,
  ) {
    switch (interest) {
      case InterestType.event:
        return true;

      case InterestType.music:
        return _containsAny(
          text,
          [
            'müzik',
            'music',
            'konser',
            'concert',
            'jazz',
            'rock',
            'pop',
            'festival',
          ],
        );

      case InterestType.cinema:
        return _containsAny(
          text,
          [
            'sinema',
            'cinema',
            'film',
            'movie',
          ],
        );

      case InterestType.nature:
        return _containsAny(
          text,
          [
            'doğa',
            'nature',
            'outdoor',
            'göl',
            'lake',
            'orman',
            'forest',
          ],
        );

      case InterestType.park:
        return _containsAny(
          text,
          [
            'park',
            'bahçe',
            'garden',
          ],
        );

      case InterestType.culture:
        return _containsAny(
          text,
          [
            'kültür',
            'culture',
            'sanat',
            'art',
            'tiyatro',
            'theatre',
            'theater',
            'sergi',
            'exhibition',
          ],
        );

      case InterestType.history:
        return _containsAny(
          text,
          [
            'tarih',
            'history',
            'tarihi',
            'historic',
            'kale',
            'castle',
            'anıt',
          ],
        );

      case InterestType.museum:
        return _containsAny(
          text,
          [
            'müze',
            'museum',
          ],
        );

      case InterestType.any:
        return true;
    }
  }

  bool _matchesInterestForPlace(
    Place place,
  ) {
    if (_interests.contains(
      InterestType.any,
    )) {
      return true;
    }

    final text =
        _placeText(place);

    for (final interest
        in _interests) {
      if (_placeMatchesInterest(
        text,
        place,
        interest,
      )) {
        return true;
      }
    }

    return false;
  }

  bool _placeMatchesInterest(
    String text,
    Place place,
    InterestType interest,
  ) {
    switch (interest) {
      case InterestType.event:
      case InterestType.music:
        return false;

      case InterestType.cinema:
        return _containsAny(
          text,
          [
            'sinema',
            'cinema',
            'film',
            'movie',
          ],
        );

      case InterestType.nature:
        return place.outdoor == true ||
            _containsAny(
              text,
              [
                'doğa',
                'nature',
                'göl',
                'lake',
                'orman',
                'forest',
              ],
            );

      case InterestType.park:
        return _containsAny(
          text,
          [
            'park',
            'bahçe',
            'garden',
          ],
        );

      case InterestType.culture:
        return _containsAny(
          text,
          [
            'kültür',
            'culture',
            'sanat',
            'art',
            'galeri',
            'gallery',
          ],
        );

      case InterestType.history:
        return _containsAny(
          text,
          [
            'tarih',
            'history',
            'tarihi',
            'historic',
            'kale',
            'castle',
            'anıt',
          ],
        );

      case InterestType.museum:
        return _containsAny(
          text,
          [
            'müze',
            'museum',
          ],
        );

      case InterestType.any:
        return true;
    }
  }

  bool _matchesBudgetForEvent(
    Event event,
  ) {
    if (_budgets.contains(
      BudgetType.any,
    )) {
      return true;
    }

    final price =
        event.priceMin ??
            event.priceMax;

    final free =
        (event.priceMin == null ||
            event.priceMin == 0) &&
        (event.priceMax == null ||
            event.priceMax == 0);

    for (final budget
        in _budgets) {
      if (budget ==
          BudgetType.free &&
          free) {
        return true;
      }

      if (price == null) {
        if (budget ==
            BudgetType.low) {
          return true;
        }

        if (budget ==
            BudgetType.medium) {
          return true;
        }
      } else {
        if (budget ==
                BudgetType.low &&
            price <= 1000) {
          return true;
        }

        if (budget ==
                BudgetType.medium &&
            price <= 2500) {
          return true;
        }
      }
    }

    return false;
  }

  bool _matchesBudgetForPlace(
    Place place,
  ) {
    if (_budgets.contains(
      BudgetType.any,
    )) {
      return true;
    }

    if (_budgets.contains(
      BudgetType.free,
    ) &&
        place.isFree == true) {
      return true;
    }

    if (_budgets.contains(
      BudgetType.low,
    )) {
      return true;
    }

    if (_budgets.contains(
      BudgetType.medium,
    )) {
      return true;
    }

    return false;
  }

  double _eventBudgetScore(
    Event event,
  ) {
    final price =
        event.priceMin ??
            event.priceMax;

    if (price == null ||
        price == 0) {
      return 20;
    }

    if (price <= 500) {
      return 15;
    }

    if (price <= 1000) {
      return 8;
    }

    if (price <= 2500) {
      return 3;
    }

    return -5;
  }

  bool _matchesDuration(
    int minutes,
  ) {
    if (_durations.contains(
      DurationType.any,
    )) {
      return true;
    }

    for (final duration
        in _durations) {
      switch (duration) {
        case DurationType.short:
          if (minutes <= 120) {
            return true;
          }
          break;

        case DurationType.medium:
          if (minutes >= 120 &&
              minutes <= 300) {
            return true;
          }
          break;

        case DurationType.fullDay:
          if (minutes >= 300) {
            return true;
          }
          break;

        case DurationType.any:
          return true;
      }
    }

    return false;
  }

  double _companionScoreForEvent(
    String text,
  ) {
    if (_companions.contains(
      CompanionType.any,
    )) {
      return 8;
    }

    double score = 0;

    if (_companions.contains(
      CompanionType.family,
    )) {
      if (_containsAny(
        text,
        [
          'aile',
          'family',
          'çocuk',
          'kids',
          'child',
        ],
      )) {
        score += 22;
      }
    }

    if (_companions.contains(
      CompanionType.couple,
    )) {
      score += 7;
    }

    if (_companions.contains(
      CompanionType.solo,
    )) {
      score += 6;
    }

    return score;
  }

  double _companionScoreForPlace(
    Place place,
  ) {
    if (_companions.contains(
      CompanionType.any,
    )) {
      return 8;
    }

    double score = 0;

    if (_companions.contains(
      CompanionType.family,
    ) &&
        place.kidsFriendly == true) {
      score += 30;
    }

    if (_companions.contains(
      CompanionType.couple,
    )) {
      score += 7;
    }

    if (_companions.contains(
      CompanionType.solo,
    )) {
      score += 6;
    }

    return score;
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

  bool _containsAny(
    String text,
    List<String> values,
  ) {
    for (final value
        in values) {
      if (text.contains(value)) {
        return true;
      }
    }

    return false;
  }

  bool _isQueued(
    _Activity activity,
  ) {
    return _queue.any(
      (item) => item.id == activity.id,
    );
  }

  void _toggleQueue(
    _Activity activity,
  ) {
    setState(() {
      final index =
          _queue.indexWhere(
        (item) =>
            item.id == activity.id,
      );

      if (index >= 0) {
        _queue.removeAt(index);
      } else {
        _queue.add(activity);
      }
    });
  }

  Future<void> _buildRoute() async {
    final navigable =
        _queue.where(
      (activity) =>
          _latitude(activity) != null &&
          _longitude(activity) != null,
    ).toList();

    if (navigable.isEmpty) {
      _showMessage(
        'Kuyruktaki seçeneklerde kullanılabilir konum bilgisi yok.',
      );
      return;
    }

    final destination =
        '${_latitude(navigable.last)},${_longitude(navigable.last)}';

    final waypoints =
        navigable.length > 2
            ? navigable
                .sublist(
                  0,
                  navigable.length - 1,
                )
                .map(
                  (item) =>
                      '${_latitude(item)},${_longitude(item)}',
                )
                .join('|')
            : null;

    final queryParameters =
        <String, String>{
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    };

    if (waypoints != null &&
        waypoints.isNotEmpty) {
      queryParameters['waypoints'] =
          waypoints;
    }

    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      queryParameters,
    );

    try {
      final launched =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage(
          'Harita uygulaması açılamadı.',
        );
      }
    } catch (_) {
      _showMessage(
        'Rota açılamadı.',
      );
    }
  }

  double? _latitude(
    _Activity activity,
  ) {
    return activity.event?.latitude ??
        activity.place?.latitude;
  }

  double? _longitude(
    _Activity activity,
  ) {
    return activity.event?.longitude ??
        activity.place?.longitude;
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  void _openActivity(
    _Activity activity,
  ) {
    if (activity.event != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              EventDetailScreen(
            event: activity.event!,
          ),
        ),
      );
      return;
    }

    if (activity.place != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              PlaceDetailScreen(
            place: activity.place!,
          ),
        ),
      );
    }
  }

  String _dateTime(
    DateTime dateTime,
  ) {
    final local =
        dateTime.toLocal();

    final day =
        local.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        local.month.toString().padLeft(
              2,
              '0',
            );

    final hour =
        local.hour.toString().padLeft(
              2,
              '0',
            );

    final minute =
        local.minute.toString().padLeft(
              2,
              '0',
            );

    return '$day.$month.${local.year} · '
        '$hour:$minute';
  }

  String _durationLabel(
    int minutes,
  ) {
    if (minutes < 60) {
      return '$minutes dk';
    }

    final hours =
        minutes ~/ 60;

    final remaining =
        minutes % 60;

    if (remaining == 0) {
      return '$hours saat';
    }

    return '$hours s $remaining dk';
  }

  String _activityTitle(
    _Activity activity,
  ) {
    return activity.event?.title ??
        activity.place?.name ??
        '';
  }

  String _activityInfo(
    _Activity activity,
  ) {
    if (activity.event != null) {
      final event =
          activity.event!;

      final venue =
          event.venueName;

      if (venue != null &&
          venue.trim().isNotEmpty) {
        return '${_dateTime(event.startsAt)} · '
            '$venue';
      }

      return _dateTime(
        event.startsAt,
      );
    }

    final place =
        activity.place!;

    final parts =
        <String>[
      _durationLabel(
        activity.durationMinutes,
      ),
    ];

    if (place.isFree == true) {
      parts.add('Ücretsiz');
    }

    return parts.join(' · ');
  }

  Widget _choiceChip<T>({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        right: 7,
        bottom: 7,
      ),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle:
            TextStyle(
          fontSize: 12,
          fontWeight:
              FontWeight.w700,
          color: selected
              ? Colors.white
              : Colors.black,
        ),
        selectedColor:
            Colors.black,
        backgroundColor:
            Colors.white,
        side: BorderSide(
          color: selected
              ? Colors.black
              : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _section(
    String title,
    Widget child,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
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
          const SizedBox(
            height: 9,
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _section(
          'KİMİNLE?',
          Wrap(
            children: [
              _choiceChip(
                label:
                    'Tek başıma',
                selected:
                    _companions.contains(
                  CompanionType.solo,
                ),
                onTap: () =>
                    _toggleCompanion(
                  CompanionType.solo,
                ),
              ),
              _choiceChip(
                label:
                    'İki kişi',
                selected:
                    _companions.contains(
                  CompanionType.couple,
                ),
                onTap: () =>
                    _toggleCompanion(
                  CompanionType.couple,
                ),
              ),
              _choiceChip(
                label:
                    'Aile',
                selected:
                    _companions.contains(
                  CompanionType.family,
                ),
                onTap: () =>
                    _toggleCompanion(
                  CompanionType.family,
                ),
              ),
              _choiceChip(
                label:
                    'Farketmez',
                selected:
                    _companions.contains(
                  CompanionType.any,
                ),
                onTap: () =>
                    _toggleCompanion(
                  CompanionType.any,
                ),
              ),
            ],
          ),
        ),
        _section(
          'BÜTÇE',
          Wrap(
            children: [
              _choiceChip(
                label:
                    'Ücretsiz',
                selected:
                    _budgets.contains(
                  BudgetType.free,
                ),
                onTap: () =>
                    _toggleBudget(
                  BudgetType.free,
                ),
              ),
              _choiceChip(
                label:
                    'Ekonomik',
                selected:
                    _budgets.contains(
                  BudgetType.low,
                ),
                onTap: () =>
                    _toggleBudget(
                  BudgetType.low,
                ),
              ),
              _choiceChip(
                label:
                    'Orta bütçe',
                selected:
                    _budgets.contains(
                  BudgetType.medium,
                ),
                onTap: () =>
                    _toggleBudget(
                  BudgetType.medium,
                ),
              ),
              _choiceChip(
                label:
                    'Farketmez',
                selected:
                    _budgets.contains(
                  BudgetType.any,
                ),
                onTap: () =>
                    _toggleBudget(
                  BudgetType.any,
                ),
              ),
            ],
          ),
        ),
        _section(
          'NE KADAR ZAMAN?',
          Wrap(
            children: [
              _choiceChip(
                label:
                    '1-2 saat',
                selected:
                    _durations.contains(
                  DurationType.short,
                ),
                onTap: () =>
                    _toggleDuration(
                  DurationType.short,
                ),
              ),
              _choiceChip(
                label:
                    '3-5 saat',
                selected:
                    _durations.contains(
                  DurationType.medium,
                ),
                onTap: () =>
                    _toggleDuration(
                  DurationType.medium,
                ),
              ),
              _choiceChip(
                label:
                    'Tüm gün',
                selected:
                    _durations.contains(
                  DurationType.fullDay,
                ),
                onTap: () =>
                    _toggleDuration(
                  DurationType.fullDay,
                ),
              ),
              _choiceChip(
                label:
                    'Farketmez',
                selected:
                    _durations.contains(
                  DurationType.any,
                ),
                onTap: () =>
                    _toggleDuration(
                  DurationType.any,
                ),
              ),
            ],
          ),
        ),
        _section(
          'NE YAPMAK İSTİYORSUN?',
          Wrap(
            children: [
              _choiceChip(
                label:
                    'Etkinlik',
                selected:
                    _interests.contains(
                  InterestType.event,
                ),
                onTap: () =>
                    _toggleInterest(
                  InterestType.event,
                ),
              ),
              _choiceChip(
                label:
                    'Müzik',
                selected:
                    _interests.contains(
                  InterestType.music,
                ),
                onTap: () =>
                    _toggleInterest(
                  InterestType.music,
                ),
              ),
              _choiceChip(
                label:
                    'Sinema',
                selected:
                    _interests.contains(
                  InterestType.cinema,
                ),
                onTap: () =>
                    _toggleInterest(
                  InterestType.cinema,
                ),
              ),
              _choiceChip(
                label:
                    'Doğa',
                selected:
                    _interests.contains(
                  InterestType.nature,
                ),
                onTap: () =>
                    _toggleInterest(
                  InterestType.nature,
                ),
              ),
              _choiceChip(
                label:
                    'Park',
                selected:
                    _interests.contains(
                  InterestType.park,
                ),
                onTap: () =>
                    _toggleInterest(
                  InterestType.park,
                ),
              ),
              _choiceChip(
                label:
                    'Tarih',
                selected:
                    _interests.contains(
                  InterestType.history,
                ),
                onTap: () =>
                    _toggleInterest(
                  InterestType.history,
                ),
              ),
              _choiceChip(
                label:
                    'Müze',
                selected:
                    _interests.contains(
                  InterestType.museum,
                ),
                onTap: () =>
                    _toggleInterest(
                  InterestType.museum,
                ),
              ),
              _choiceChip(
                label:
                    'Kültür',
                selected:
                    _interests.contains(
                  InterestType.culture,
                ),
                onTap: () =>
                    _toggleInterest(
                  InterestType.culture,
                ),
              ),
              _choiceChip(
                label:
                    'Farketmez',
                selected:
                    _interests.contains(
                  InterestType.any,
                ),
                onTap: () =>
                    _toggleInterest(
                  InterestType.any,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStatus() {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 18,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _userPosition != null
                ? Icons.my_location_rounded
                : Icons.location_off_outlined,
            size: 20,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              _userPosition != null
                  ? 'Konumuna göre sıralanıyor.'
                  : 'Konum olmadan Ankara geneli sıralanıyor.',
              style:
                  const TextStyle(
                fontSize: 12,
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
                fontSize: 10,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    _Activity activity,
  ) {
    final queued =
        _isQueued(activity);

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: queued
              ? Colors.black
              : Colors.grey.shade200,
          width: queued ? 1.3 : 1,
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        onTap: () =>
            _openActivity(
          activity,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(
                color:
                    Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),
              child: Icon(
                activity.type ==
                        _ActivityType.event
                    ? Icons.event_outlined
                    : Icons.place_outlined,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.event
                            ?.title ??
                        activity.place
                            ?.name ??
                        '',
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    _activityInfo(
                      activity,
                    ),
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        TextStyle(
                      fontSize: 11,
                      color:
                          Colors.grey.shade600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(
                    height: 9,
                  ),
                  SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _toggleQueue(
                        activity,
                      ),
                      icon: Icon(
                        queued
                            ? Icons.check
                            : Icons.add,
                        size: 17,
                      ),
                      label: Text(
                        queued
                            ? 'Kuyrukta'
                            : 'Kuyruğa ekle',
                        style:
                            const TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.black,
                        side:
                            BorderSide(
                          color:
                              queued
                                  ? Colors.black
                                  : Colors.grey.shade300,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
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

  Widget _buildQueueBar() {
    if (_queue.isEmpty) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          10,
        ),
        decoration:
            const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color:
                  Color(0x16000000),
              blurRadius: 15,
              offset:
                  Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_queue.length} aktivite seçildi',
                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  const Text(
                    'İstersen sırayı rota olarak açabilirsin.',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            FilledButton.icon(
              onPressed:
                  _buildRoute,
              icon:
                  const Icon(
                Icons.route,
                size: 18,
              ),
              label:
                  const Text(
                'ROTA OLUŞTUR',
                style:
                    TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.black,
                foregroundColor:
                    Colors.white,
                minimumSize:
                    const Size(
                  0,
                  45,
                ),
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF7F7F5),
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        title:
            const Text(
          'Bugün ne yapayım?',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      bottomNavigationBar:
          _buildQueueBar(),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  20,
                  8,
                  20,
                  10,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child:
                          ListView(
                        padding:
                            const EdgeInsets
                                .only(
                          bottom: 20,
                        ),
                        children: [
                          const Text(
                            'Bugünü sana göre\nbirlikte planlayalım.',
                            style:
                                TextStyle(
                              fontSize: 29,
                              fontWeight:
                                  FontWeight.w900,
                              height: 1.06,
                              letterSpacing:
                                  -0.8,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          _buildLocationStatus(),
                          _buildFilterChips(),
                          if (_error != null)
                            Container(
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom: 16,
                              ),
                              padding:
                                  const EdgeInsets
                                      .all(
                                15,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  18,
                                ),
                              ),
                              child:
                                  Text(
                                _error!,
                              ),
                            ),
                          if (_results.isNotEmpty)
                            Text(
                              'ÖNERİLER',
                              style:
                                  const TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w900,
                                letterSpacing:
                                    1,
                                color:
                                    Colors.black54,
                              ),
                            ),
                          if (_results.isNotEmpty)
                            const SizedBox(
                              height: 10,
                            ),
                          if (_results.isNotEmpty)
                            ..._results.map(
                              _buildResultCard,
                            ),
                          if (_hasSearched &&
                              _results.isEmpty &&
                              _error == null)
                            Container(
                              margin:
                                  const EdgeInsets
                                      .only(
                                top: 10,
                              ),
                              padding:
                                  const EdgeInsets
                                      .all(
                                22,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                              ),
                              child:
                                  const Column(
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 42,
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    'Bu kriterlere uygun sonuç bulamadım.',
                                    textAlign:
                                        TextAlign.center,
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton:
          _buildRecommendationButton(),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildRecommendationButton() {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 53,
          child: FilledButton.icon(
            onPressed:
                _generateRecommendations,
            icon:
                const Icon(
              Icons.auto_awesome,
            ),
            label:
                const Text(
              'BANA PLAN ÖNER',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            style:
                FilledButton.styleFrom(
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
        ),
      ),
    );
  }
}

class _Activity {
  final _ActivityType type;
  final String id;
  final double score;
  final int durationMinutes;
  final Event? event;
  final Place? place;

  const _Activity({
    required this.type,
    required this.id,
    required this.score,
    required this.durationMinutes,
    required this.event,
    required this.place,
  });
}
