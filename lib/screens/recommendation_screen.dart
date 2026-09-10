import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

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

  CompanionType _companion = CompanionType.any;
  BudgetType _budget = BudgetType.any;
  DurationType _duration = DurationType.any;
  InterestType _interest = InterestType.any;

  bool _loading = false;
  bool _hasSearched = false;
  bool _locationLoading = false;

  String? _error;

  Position? _userPosition;

  List<_DailyPlan> _plans = <_DailyPlan>[];

  @override
  void initState() {
    super.initState();
    _tryGetLocationSilently();
  }

  Future<void> _tryGetLocationSilently() async {
    try {
      final position = await _getCurrentPosition(
        askPermission: false,
      );

      if (!mounted) {
        return;
      }

      if (position != null) {
        setState(() {
          _userPosition = position;
        });
      }
    } catch (_) {
      // Konum alınamazsa uygulama normal şekilde devam eder.
    }
  }

  Future<Position?> _getCurrentPosition({
    required bool askPermission,
  }) async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return null;
    }

    var permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      if (!askPermission) {
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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
  }

  Future<void> _prepareLocation() async {
    if (_locationLoading) {
      return;
    }

    setState(() {
      _locationLoading = true;
    });

    try {
      final position =
          await _getCurrentPosition(
        askPermission: true,
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

  Future<void> _generateRecommendations() async {
    setState(() {
      _loading = true;
      _hasSearched = true;
      _error = null;
      _plans = <_DailyPlan>[];
    });

    await _prepareLocation();

    try {
      final result =
          await Future.wait<Object>([
        _eventService.getUpcomingEvents(
          city: 'Ankara',
          days: 7,
          limit: 100,
        ),
        _placeService.getPlaces(
          city: 'Ankara',
          limit: 100,
        ),
      ]);

      final events =
          result[0] as List<Event>;

      final places =
          result[1] as List<Place>;

      final activities =
          <_Activity>[];

      for (final event in events) {
        final activity =
            _buildEventActivity(event);

        if (activity != null) {
          activities.add(activity);
        }
      }

      for (final place in places) {
        final activity =
            _buildPlaceActivity(place);

        if (activity != null) {
          activities.add(activity);
        }
      }

      final plans =
          _buildPlans(activities);

      if (!mounted) {
        return;
      }

      setState(() {
        _plans = plans;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error =
            'Öneriler oluşturulurken bir sorun oluştu. '
            'Lütfen internet bağlantını kontrol et.';
      });
    }
  }

  _Activity? _buildEventActivity(
    Event event,
  ) {
    final now = DateTime.now();
    final start =
        event.startsAt.toLocal();

    if (!start.isAfter(now)) {
      return null;
    }

    final score =
        _scoreEvent(event);

    if (score <= 0) {
      return null;
    }

    return _Activity(
      type: _ActivityType.event,
      score: score,
      durationMinutes:
          _eventDuration(event),
      startsAt: start,
      event: event,
    );
  }

  _Activity? _buildPlaceActivity(
    Place place,
  ) {
    final score =
        _scorePlace(place);

    if (score <= 0) {
      return null;
    }

    return _Activity(
      type: _ActivityType.place,
      score: score,
      durationMinutes:
          _placeDuration(place),
      startsAt: DateTime.now(),
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

    return value.clamp(30, 600);
  }

  int _eventDuration(
    Event event,
  ) {
    final starts =
        event.startsAt.toLocal();

    final ends =
        event.endsAt?.toLocal();

    if (ends != null &&
        ends.isAfter(starts)) {
      final minutes =
          ends.difference(starts).inMinutes;

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
    final now = DateTime.now();
    final start =
        event.startsAt.toLocal();

    if (!start.isAfter(now)) {
      return 0;
    }

    double score = 40;

    final category =
        event.category.toLowerCase();

    final title =
        event.title.toLowerCase();

    final description =
        (event.description ?? '')
            .toLowerCase();

    final text =
        '$category $title $description';

    switch (_interest) {
      case InterestType.event:
        score += 55;
        break;

      case InterestType.music:
        if (_containsAny(
          text,
          <String>[
            'müzik',
            'music',
            'konser',
            'concert',
            'festival',
            'jazz',
            'rock',
            'pop',
          ],
        )) {
          score += 55;
        } else {
          score -= 25;
        }
        break;

      case InterestType.culture:
        if (_containsAny(
          text,
          <String>[
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
        )) {
          score += 48;
        } else {
          score -= 20;
        }
        break;

      case InterestType.museum:
        if (_containsAny(
          text,
          <String>[
            'müze',
            'museum',
          ],
        )) {
          score += 50;
        } else {
          score -= 25;
        }
        break;

      case InterestType.history:
        if (_containsAny(
          text,
          <String>[
            'tarih',
            'history',
            'tarihi',
            'historic',
          ],
        )) {
          score += 46;
        } else {
          score -= 15;
        }
        break;

      case InterestType.nature:
      case InterestType.park:
        score -= 12;
        break;

      case InterestType.any:
        score += 10;
        break;
    }

    switch (_budget) {
      case BudgetType.free:
        final minPrice =
            event.priceMin;

        final maxPrice =
            event.priceMax;

        final isFree =
            (minPrice == null ||
                minPrice == 0) &&
            (maxPrice == null ||
                maxPrice == 0);

        if (!isFree) {
          return 0;
        }

        score += 45;
        break;

      case BudgetType.low:
        final price =
            event.priceMin ??
                event.priceMax;

        if (price == null) {
          score += 8;
        } else if (price <= 500) {
          score += 30;
        } else if (price <= 1000) {
          score += 10;
        } else {
          score -= 25;
        }
        break;

      case BudgetType.medium:
        final price =
            event.priceMin ??
                event.priceMax;

        if (price == null) {
          score += 6;
        } else if (price <= 1500) {
          score += 22;
        } else if (price <= 2500) {
          score += 5;
        } else {
          score -= 18;
        }
        break;

      case BudgetType.any:
        break;
    }

    switch (_companion) {
      case CompanionType.family:
        if (_containsAny(
          text,
          <String>[
            'aile',
            'family',
            'çocuk',
            'kids',
            'child',
          ],
        )) {
          score += 25;
        } else {
          score -= 4;
        }
        break;

      case CompanionType.couple:
        score += 8;
        break;

      case CompanionType.solo:
        score += 5;
        break;

      case CompanionType.any:
        break;
    }

    final minutesUntil =
        start.difference(now).inMinutes;

    if (minutesUntil <= 180) {
      score += 15;
    } else if (minutesUntil <= 1440) {
      score += 9;
    } else if (minutesUntil <= 4320) {
      score += 4;
    }

    score +=
        _durationCompatibilityScore(
      _eventDuration(event),
      isEvent: true,
    );

    score +=
        _locationScoreForEvent(event);

    score +=
        event.trustScore / 10;

    return score;
  }

  double _scorePlace(
    Place place,
  ) {
    double score = 35;

    final category =
        place.category.toLowerCase();

    final placeType =
        (place.placeType ?? '')
            .toLowerCase();

    final tags =
        place.tags
            .map(
              (tag) =>
                  tag.toLowerCase(),
            )
            .join(' ');

    final text =
        '$category $placeType $tags';

    switch (_interest) {
      case InterestType.nature:
        if (_containsAny(
          text,
          <String>[
            'doğa',
            'nature',
            'göl',
            'lake',
            'orman',
            'forest',
            'rekreasyon',
            'recreation',
          ],
        ) ||
            place.outdoor == true) {
          score += 55;
        } else {
          score -= 28;
        }
        break;

      case InterestType.park:
        if (_containsAny(
          text,
          <String>[
            'park',
            'bahçe',
            'garden',
          ],
        )) {
          score += 55;
        } else {
          score -= 28;
        }
        break;

      case InterestType.history:
        if (_containsAny(
          text,
          <String>[
            'tarih',
            'history',
            'historic',
            'tarihi',
            'anıt',
            'kale',
            'castle',
          ],
        )) {
          score += 52;
        } else {
          score -= 18;
        }
        break;

      case InterestType.museum:
        if (_containsAny(
          text,
          <String>[
            'müze',
            'museum',
          ],
        )) {
          score += 55;
        } else {
          score -= 25;
        }
        break;

      case InterestType.culture:
        if (_containsAny(
          text,
          <String>[
            'kültür',
            'culture',
            'sanat',
            'art',
            'galeri',
            'gallery',
            'müze',
            'museum',
          ],
        )) {
          score += 48;
        } else {
          score -= 12;
        }
        break;

      case InterestType.event:
      case InterestType.music:
        score -= 18;
        break;

      case InterestType.any:
        score += 10;
        break;
    }

    switch (_budget) {
      case BudgetType.free:
        if (place.isFree == true) {
          score += 45;
        } else {
          return 0;
        }
        break;

      case BudgetType.low:
        if (place.isFree == true) {
          score += 30;
        } else {
          score += 6;
        }
        break;

      case BudgetType.medium:
        score += 10;
        break;

      case BudgetType.any:
        break;
    }

    switch (_companion) {
      case CompanionType.family:
        if (place.kidsFriendly == true) {
          score += 40;
        } else {
          score -= 10;
        }
        break;

      case CompanionType.couple:
        score += 10;
        break;

      case CompanionType.solo:
        score += 7;
        break;

      case CompanionType.any:
        break;
    }

    score +=
        _durationCompatibilityScore(
      _placeDuration(place),
      isEvent: false,
    );

    score +=
        _locationScoreForPlace(place);

    if (place.verified) {
      score += 10;
    }

    score +=
        place.trustScore / 10;

    return score;
  }

  double _locationScoreForPlace(
    Place place,
  ) {
    final distance =
        _distanceFromUser(
      place.latitude,
      place.longitude,
    );

    if (distance == null) {
      return 0;
    }

    if (distance <= 2) {
      return 45;
    }

    if (distance <= 5) {
      return 35;
    }

    if (distance <= 10) {
      return 23;
    }

    if (distance <= 15) {
      return 10;
    }

    if (distance <= 25) {
      return 0;
    }

    return -15;
  }

  double _locationScoreForEvent(
    Event event,
  ) {
    final distance =
        _distanceFromUser(
      event.latitude,
      event.longitude,
    );

    if (distance == null) {
      return 0;
    }

    if (distance <= 2) {
      return 35;
    }

    if (distance <= 5) {
      return 28;
    }

    if (distance <= 10) {
      return 18;
    }

    if (distance <= 15) {
      return 8;
    }

    if (distance <= 25) {
      return 0;
    }

    return -12;
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

    return _haversineKm(
      position.latitude,
      position.longitude,
      latitude,
      longitude,
    );
  }

  double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm =
        6371.0;

    final dLat =
        _toRadians(lat2 - lat1);

    final dLon =
        _toRadians(lon2 - lon1);

    final a =
        pow(
              sin(dLat / 2),
              2,
            ) +
            cos(_toRadians(lat1)) *
                cos(_toRadians(lat2)) *
                pow(
                  sin(dLon / 2),
                  2,
                );

    final c =
        2 *
            atan2(
              sqrt(a),
              sqrt(1 - a),
            );

    return earthRadiusKm * c;
  }

  double _toRadians(
    double value,
  ) {
    return value *
        pi /
        180;
  }

  double _estimatedTravelMinutes(
    double? distanceKm,
  ) {
    if (distanceKm == null) {
      return 25;
    }

    final roadDistance =
        distanceKm * 1.25;

    final minutes =
        roadDistance /
            30 *
            60;

    return minutes
        .round()
        .clamp(10, 90)
        .toDouble();
  }

  int _transitionBetween(
    _Activity first,
    _Activity second,
  ) {
    double? distance;

    if (first.place != null) {
      distance = _distanceBetween(
        first.place!.latitude,
        first.place!.longitude,
        second.place?.latitude ??
            second.event?.latitude,
        second.place?.longitude ??
            second.event?.longitude,
      );
    } else if (first.event != null) {
      distance = _distanceBetween(
        first.event!.latitude,
        first.event!.longitude,
        second.place?.latitude ??
            second.event?.latitude,
        second.place?.longitude ??
            second.event?.longitude,
      );
    }

    return _estimatedTravelMinutes(
      distance,
    ).round();
  }

  double? _distanceBetween(
    double? lat1,
    double? lon1,
    double? lat2,
    double? lon2,
  ) {
    if (lat1 == null ||
        lon1 == null ||
        lat2 == null ||
        lon2 == null) {
      return null;
    }

    return _haversineKm(
      lat1,
      lon1,
      lat2,
      lon2,
    );
  }

  double? _distanceBetweenActivities(
    _Activity first,
    _Activity second,
  ) {
    return _distanceBetween(
      first.place?.latitude ??
          first.event?.latitude,
      first.place?.longitude ??
          first.event?.longitude,
      second.place?.latitude ??
          second.event?.latitude,
      second.place?.longitude ??
          second.event?.longitude,
    );
  }

  double _durationCompatibilityScore(
    int minutes, {
    required bool isEvent,
  }) {
    switch (_duration) {
      case DurationType.short:
        if (minutes <= 120) {
          return 35;
        }

        if (minutes <= 180) {
          return 10;
        }

        return -35;

      case DurationType.medium:
        if (minutes >= 120 &&
            minutes <= 300) {
          return 35;
        }

        if (minutes <= 360) {
          return 10;
        }

        return -25;

      case DurationType.fullDay:
        if (minutes >= 360) {
          return 35;
        }

        if (minutes >= 240) {
          return 20;
        }

        return isEvent ? 2 : -2;

      case DurationType.any:
        return isEvent ? 5 : 8;
    }
  }

  int _targetDurationMinutes() {
    switch (_duration) {
      case DurationType.short:
        return 120;

      case DurationType.medium:
        return 300;

      case DurationType.fullDay:
        return 600;

      case DurationType.any:
        return 360;
    }
  }

  int _maximumPlanMinutes() {
    switch (_duration) {
      case DurationType.short:
        return 180;

      case DurationType.medium:
        return 360;

      case DurationType.fullDay:
        return 720;

      case DurationType.any:
        return 480;
    }
  }

  List<_DailyPlan> _buildPlans(
    List<_Activity> activities,
  ) {
    if (activities.isEmpty) {
      return <_DailyPlan>[];
    }

    final sorted =
        <_Activity>[
          ...activities,
        ]..sort(
            (a, b) =>
                b.score.compareTo(
              a.score,
            ),
          );

    final plans =
        <_DailyPlan>[];

    final target =
        _targetDurationMinutes();

    final maximum =
        _maximumPlanMinutes();

    // TEK AKTİVİTELER
    for (final activity in sorted) {
      if (activity.durationMinutes >
          maximum) {
        continue;
      }

      if (activity.type ==
              _ActivityType.event &&
          !_eventCanBeAttended(
            activity,
          )) {
        continue;
      }

      final score =
          activity.score +
              _durationFitBonus(
                activity.durationMinutes,
                target,
              );

      plans.add(
        _DailyPlan(
          score: score,
          activities: <_Activity>[
            activity,
          ],
          transitionMinutes: 0,
        ),
      );
    }

    final places =
        sorted
            .where(
              (item) =>
                  item.type ==
                  _ActivityType.place,
            )
            .toList();

    final events =
        sorted
            .where(
              (item) =>
                  item.type ==
                  _ActivityType.event,
            )
            .toList();

    // YER + ETKİNLİK
    for (final place
        in places.take(15)) {
      for (final event
          in events.take(20)) {
        final plan =
            _buildPlaceEventPlan(
          place,
          event,
          target,
          maximum,
        );

        if (plan != null) {
          plans.add(plan);
        }
      }
    }

    // YER + YER
    for (var i = 0;
        i < places.length &&
            i < 15;
        i++) {
      for (var j = i + 1;
          j < places.length &&
              j < 15;
          j++) {
        final first =
            places[i];

        final second =
            places[j];

        final transition =
            _transitionBetween(
          first,
          second,
        );

        final total =
            first.durationMinutes +
                transition +
                second.durationMinutes;

        if (total > maximum) {
          continue;
        }

        final score =
            first.score +
                second.score +
                _durationFitBonus(
                  total,
                  target,
                ) +
                _distancePairBonus(
                  first,
                  second,
                );

        plans.add(
          _DailyPlan(
            score: score,
            activities: <_Activity>[
              first,
              second,
            ],
            transitionMinutes:
                transition,
          ),
        );
      }
    }

    plans.sort(
      (a, b) =>
          b.score.compareTo(
        a.score,
      ),
    );

    final seen =
        <String>{};

    final result =
        <_DailyPlan>[];

    for (final plan in plans) {
      if (!seen.add(
        plan.signature,
      )) {
        continue;
      }

      result.add(plan);

      if (result.length >= 8) {
        break;
      }
    }

    return result;
  }

  _DailyPlan? _buildPlaceEventPlan(
    _Activity place,
    _Activity event,
    int target,
    int maximum,
  ) {
    final eventStart =
        event.startsAt;

    final now =
        DateTime.now();

    final minutesUntil =
        eventStart
            .difference(now)
            .inMinutes;

    final travel =
        _transitionBetween(
      place,
      event,
    );

    final required =
        place.durationMinutes +
            travel;

    if (minutesUntil <
        required) {
      return null;
    }

    final total =
        place.durationMinutes +
            travel +
            event.durationMinutes;

    if (total > maximum) {
      return null;
    }

    final durationBonus =
        _durationFitBonus(
      total,
      target,
    );

    final distanceBonus =
        _distancePairBonus(
      place,
      event,
    );

    final timingBonus =
        minutesUntil <= 360
            ? 15
            : minutesUntil <= 1440
                ? 8
                : 0;

    return _DailyPlan(
      score:
          place.score +
              event.score +
              durationBonus +
              distanceBonus +
              timingBonus +
              15,
      activities: <_Activity>[
        place,
        event,
      ],
      transitionMinutes:
          travel,
    );
  }

  double _distancePairBonus(
    _Activity first,
    _Activity second,
  ) {
    final distance =
        _distanceBetweenActivities(
      first,
      second,
    );

    if (distance == null) {
      return 0;
    }

    if (distance <= 2) {
      return 30;
    }

    if (distance <= 5) {
      return 22;
    }

    if (distance <= 10) {
      return 12;
    }

    if (distance <= 15) {
      return 4;
    }

    return -10;
  }

  bool _eventCanBeAttended(
    _Activity activity,
  ) {
    final event =
        activity.event;

    if (event == null) {
      return true;
    }

    final start =
        event.startsAt.toLocal();

    return start.isAfter(
      DateTime.now(),
    );
  }

  double _durationFitBonus(
    int actual,
    int target,
  ) {
    final difference =
        (actual - target).abs();

    if (difference <= 20) {
      return 45;
    }

    if (difference <= 40) {
      return 34;
    }

    if (difference <= 60) {
      return 25;
    }

    if (difference <= 90) {
      return 15;
    }

    if (difference <= 120) {
      return 8;
    }

    return 0;
  }

  bool _containsAny(
    String text,
    List<String> values,
  ) {
    for (final value in values) {
      if (text.contains(value)) {
        return true;
      }
    }

    return false;
  }

  String _resultTitle() {
    switch (_interest) {
      case InterestType.event:
        return 'Sana uygun etkinlikler';

      case InterestType.music:
        return 'Müzik önerileri';

      case InterestType.nature:
        return 'Doğa önerileri';

      case InterestType.park:
        return 'Park önerileri';

      case InterestType.culture:
        return 'Kültür önerileri';

      case InterestType.history:
        return 'Tarih önerileri';

      case InterestType.museum:
        return 'Müze önerileri';

      case InterestType.any:
        return 'Sana uygun planlar';
    }
  }

  String _planSubtitle() {
    final locationText =
        _userPosition != null
            ? 'Konumuna göre sıralandı.'
            : 'Konum olmadan Ankara geneli önerildi.';

    switch (_duration) {
      case DurationType.short:
        return 'Yaklaşık 1-2 saatlik seçenekler. '
            '$locationText';

      case DurationType.medium:
        return 'Yaklaşık 3-5 saatlik planlar. '
            '$locationText';

      case DurationType.fullDay:
        return 'Günün büyük bölümünü değerlendiren seçenekler. '
            '$locationText';

      case DurationType.any:
        return 'Süre, yakınlık ve etkinlik saatine göre dengelendi. '
            '$locationText';
    }
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

    return '$hours saat $remaining dk';
  }

  String _eventTime(
    DateTime dateTime,
  ) {
    return DateFormat(
      'HH:mm',
      'tr_TR',
    ).format(
      dateTime.toLocal(),
    );
  }

  String _distanceLabel(
    double? distance,
  ) {
    if (distance == null) {
      return '';
    }

    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    }

    return '${distance.toStringAsFixed(1)} km';
  }

  String _activityTitle(
    _Activity activity,
  ) {
    if (activity.event != null) {
      return activity.event!.title;
    }

    return activity.place?.name ?? '';
  }

  String _activityCategory(
    _Activity activity,
  ) {
    if (activity.event != null) {
      return activity.event!.category;
    }

    return activity.place?.category ??
        'Yer';
  }

  String _activitySubtitle(
    _Activity activity,
  ) {
    if (activity.event != null) {
      final event =
          activity.event!;

      final time =
          _eventTime(
        event.startsAt,
      );

      final distance =
          _distanceFromUser(
        event.latitude,
        event.longitude,
      );

      final distanceText =
          _distanceLabel(
        distance,
      );

      final venue =
          event.venueName;

      final parts =
          <String>[
        time,
      ];

      if (venue != null &&
          venue.trim().isNotEmpty) {
        parts.add(venue);
      }

      if (distanceText.isNotEmpty) {
        parts.add(distanceText);
      }

      return parts.join(' · ');
    }

    final place =
        activity.place!;

    final duration =
        _durationLabel(
      activity.durationMinutes,
    );

    final distance =
        _distanceFromUser(
      place.latitude,
      place.longitude,
    );

    final distanceText =
        _distanceLabel(
      distance,
    );

    final parts =
        <String>[
      duration,
    ];

    if (place.isFree == true) {
      parts.add('Ücretsiz');
    }

    if (distanceText.isNotEmpty) {
      parts.add(distanceText);
    }

    return parts.join(' · ');
  }

  String _planTimeText(
    _DailyPlan plan,
  ) {
    if (plan.activities.isEmpty) {
      return '';
    }

    final first =
        plan.activities.first;

    if (first.event != null) {
      return _eventTime(
        first.event!.startsAt,
      );
    }

    if (plan.activities.length > 1 &&
        plan.activities.last.event !=
            null) {
      return 'Etkinlik ${_eventTime(
        plan.activities.last.event!.startsAt,
      )}';
    }

    return 'Şimdi başlayabilir';
  }

  Widget _buildPlanCard(
    _DailyPlan plan,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x08000000,
            ),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.activities.length ==
                                1
                            ? 'TEK AKTİVİTE'
                            : 'GÜNÜN PLANI',
                        style:
                            const TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: 1,
                          color:
                              Colors.black54,
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        '${_durationLabel(plan.totalMinutes)} · ${_planTimeText(plan)}',
                        style:
                            const TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                  ),
                  child: Text(
                    '${plan.activities.length} adım',
                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            ...List.generate(
              plan.activities.length,
              (index) {
                return _buildPlanActivity(
                  plan,
                  plan.activities[index],
                  index,
                );
              },
            ),
            if (plan.transitionMinutes >
                0) ...[
              const SizedBox(
                height: 7,
              ),
              Align(
                alignment:
                    Alignment.centerLeft,
                child: Padding(
                  padding:
                      const EdgeInsets.only(
                    left: 8,
                  ),
                  child: Text(
                    'Tahmini geçiş: '
                    '${plan.transitionMinutes} dk',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanActivity(
    _DailyPlan plan,
    _Activity activity,
    int index,
  ) {
    final isEvent =
        activity.type ==
            _ActivityType.event;

    final distance =
        activity.place != null
            ? _distanceFromUser(
                activity.place!.latitude,
                activity.place!.longitude,
              )
            : _distanceFromUser(
                activity.event!.latitude,
                activity.event!.longitude,
              );

    return InkWell(
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      onTap: () {
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
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 7,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
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
                isEvent
                    ? Icons.event_outlined
                    : Icons.place_outlined,
                size: 21,
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
                    '${index + 1}. ${_activityTitle(activity)}',
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    _activityCategory(
                      activity,
                    ).toUpperCase(),
                    style:
                        const TextStyle(
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: 0.8,
                      color:
                          Colors.black54,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    _activitySubtitle(
                      activity,
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                  if (distance != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 3,
                      ),
                      child: Text(
                        'Konumuna ${_distanceLabel(distance)}',
                        style:
                            const TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color:
                  Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    Widget child,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 23,
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
              color: Colors.black54,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildCompanionChoices() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Choice(
          label: 'Tek başıma',
          selected:
              _companion ==
                  CompanionType.solo,
          onTap: () {
            setState(() {
              _companion =
                  CompanionType.solo;
            });
          },
        ),
        _Choice(
          label: 'İki kişi',
          selected:
              _companion ==
                  CompanionType.couple,
          onTap: () {
            setState(() {
              _companion =
                  CompanionType.couple;
            });
          },
        ),
        _Choice(
          label: 'Aile',
          selected:
              _companion ==
                  CompanionType.family,
          onTap: () {
            setState(() {
              _companion =
                  CompanionType.family;
            });
          },
        ),
        _Choice(
          label: 'Farketmez',
          selected:
              _companion ==
                  CompanionType.any,
          onTap: () {
            setState(() {
              _companion =
                  CompanionType.any;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBudgetChoices() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Choice(
          label: 'Ücretsiz',
          selected:
              _budget ==
                  BudgetType.free,
          onTap: () {
            setState(() {
              _budget =
                  BudgetType.free;
            });
          },
        ),
        _Choice(
          label: 'Ekonomik',
          selected:
              _budget ==
                  BudgetType.low,
          onTap: () {
            setState(() {
              _budget =
                  BudgetType.low;
            });
          },
        ),
        _Choice(
          label: 'Orta bütçe',
          selected:
              _budget ==
                  BudgetType.medium,
          onTap: () {
            setState(() {
              _budget =
                  BudgetType.medium;
            });
          },
        ),
        _Choice(
          label: 'Farketmez',
          selected:
              _budget ==
                  BudgetType.any,
          onTap: () {
            setState(() {
              _budget =
                  BudgetType.any;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDurationChoices() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Choice(
          label: '1-2 saat',
          selected:
              _duration ==
                  DurationType.short,
          onTap: () {
            setState(() {
              _duration =
                  DurationType.short;
            });
          },
        ),
        _Choice(
          label: '3-5 saat',
          selected:
              _duration ==
                  DurationType.medium,
          onTap: () {
            setState(() {
              _duration =
                  DurationType.medium;
            });
          },
        ),
        _Choice(
          label: 'Tüm gün',
          selected:
              _duration ==
                  DurationType.fullDay,
          onTap: () {
            setState(() {
              _duration =
                  DurationType.fullDay;
            });
          },
        ),
        _Choice(
          label: 'Farketmez',
          selected:
              _duration ==
                  DurationType.any,
          onTap: () {
            setState(() {
              _duration =
                  DurationType.any;
            });
          },
        ),
      ],
    );
  }

  Widget _buildInterestChoices() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Choice(
          label: 'Etkinlik',
          selected:
              _interest ==
                  InterestType.event,
          onTap: () {
            setState(() {
              _interest =
                  InterestType.event;
            });
          },
        ),
        _Choice(
          label: 'Müzik',
          selected:
              _interest ==
                  InterestType.music,
          onTap: () {
            setState(() {
              _interest =
                  InterestType.music;
            });
          },
        ),
        _Choice(
          label: 'Doğa',
          selected:
              _interest ==
                  InterestType.nature,
          onTap: () {
            setState(() {
              _interest =
                  InterestType.nature;
            });
          },
        ),
        _Choice(
          label: 'Park',
          selected:
              _interest ==
                  InterestType.park,
          onTap: () {
            setState(() {
              _interest =
                  InterestType.park;
            });
          },
        ),
        _Choice(
          label: 'Tarih',
          selected:
              _interest ==
                  InterestType.history,
          onTap: () {
            setState(() {
              _interest =
                  InterestType.history;
            });
          },
        ),
        _Choice(
          label: 'Müze',
          selected:
              _interest ==
                  InterestType.museum,
          onTap: () {
            setState(() {
              _interest =
                  InterestType.museum;
            });
          },
        ),
        _Choice(
          label: 'Kültür',
          selected:
              _interest ==
                  InterestType.culture,
          onTap: () {
            setState(() {
              _interest =
                  InterestType.culture;
            });
          },
        ),
        _Choice(
          label: 'Farketmez',
          selected:
              _interest ==
                  InterestType.any,
          onTap: () {
            setState(() {
              _interest =
                  InterestType.any;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLocationStatus() {
    final hasLocation =
        _userPosition != null;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 24,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasLocation
                ? Icons.my_location_rounded
                : Icons.location_off_outlined,
            size: 20,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              hasLocation
                  ? 'Konumun önerilerde kullanılıyor.'
                  : 'Konum kapalı. Ankara geneli öneri yapılacak.',
              style:
                  const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
          if (!hasLocation)
            TextButton(
              onPressed:
                  _locationLoading
                      ? null
                      : _prepareLocation,
              child: const Text(
                'AÇ',
                style:
                    TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              _error!,
              style:
                  const TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResult() {
    return Container(
      padding:
          const EdgeInsets.all(
        22,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 42,
          ),
          const SizedBox(
            height: 12,
          ),
          const Text(
            'Bu kriterlere uygun bir plan bulamadım.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            'Süreyi, bütçeyi veya ilgi alanını '
            'biraz genişletirsen daha fazla '
            'seçenek bulabiliriz.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize: 12,
              height: 1.4,
              color:
                  Colors.grey.shade600,
            ),
          ),
        ],
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
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                30,
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
                  height: 24,
                ),
                _buildLocationStatus(),
                _buildSection(
                  'KİMİNLE?',
                  _buildCompanionChoices(),
                ),
                _buildSection(
                  'BÜTÇE',
                  _buildBudgetChoices(),
                ),
                _buildSection(
                  'NE KADAR ZAMAN?',
                  _buildDurationChoices(),
                ),
                _buildSection(
                  'NE YAPMAK İSTİYORSUN?',
                  _buildInterestChoices(),
                ),
                const SizedBox(
                  height: 8,
                ),
                SizedBox(
                  height: 56,
                  child:
                      FilledButton.icon(
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
                            FontWeight.w800,
                      ),
                    ),
                    style:
                        FilledButton
                            .styleFrom(
                      backgroundColor:
                          Colors.black,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(
                    height: 20,
                  ),
                  _buildError(),
                ],
                if (_plans.isNotEmpty) ...[
                  const SizedBox(
                    height: 32,
                  ),
                  Text(
                    _resultTitle(),
                    style:
                        const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    _planSubtitle(),
                    style:
                        TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  ..._plans.map(
                    _buildPlanCard,
                  ),
                ],
                if (_hasSearched &&
                    !_loading &&
                    _plans.isEmpty &&
                    _error == null) ...[
                  const SizedBox(
                    height: 30,
                  ),
                  _buildNoResult(),
                ],
              ],
            ),
    );
  }
}

class _Activity {
  final _ActivityType type;
  final double score;
  final int durationMinutes;
  final DateTime startsAt;
  final Event? event;
  final Place? place;

  const _Activity({
    required this.type,
    required this.score,
    required this.durationMinutes,
    required this.startsAt,
    this.event,
    this.place,
  });
}

class _DailyPlan {
  final double score;
  final List<_Activity> activities;
  final int transitionMinutes;

  const _DailyPlan({
    required this.score,
    required this.activities,
    required this.transitionMinutes,
  });

  int get totalMinutes {
    var total =
        transitionMinutes;

    for (final activity
        in activities) {
      total +=
          activity.durationMinutes;
    }

    return total;
  }

  String get signature {
    return activities
        .map(
          (activity) =>
              activity.event?.id ??
              activity.place?.id ??
              '',
        )
        .join('|');
  }
}

class _Choice
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          30,
        ),
        onTap: onTap,
        child:
            AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 180,
          ),
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 15,
            vertical: 11,
          ),
          decoration:
              BoxDecoration(
            color: selected
                ? Colors.black
                : Colors.white,
            borderRadius:
                BorderRadius.circular(
              30,
            ),
            border: Border.all(
              color: selected
                  ? Colors.black
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style:
                TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
              color: selected
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}