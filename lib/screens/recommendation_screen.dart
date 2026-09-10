import 'package:flutter/material.dart';
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

  String? _error;

  List<_DailyPlan> _plans = <_DailyPlan>[];

  Future<void> _generateRecommendations() async {
    setState(() {
      _loading = true;
      _hasSearched = true;
      _error = null;
      _plans = <_DailyPlan>[];
    });

    try {
      final result = await Future.wait<Object>([
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

      final events = result[0] as List<Event>;
      final places = result[1] as List<Place>;

      final activities = <_Activity>[];

      for (final event in events) {
        final activity = _buildEventActivity(event);
        if (activity != null) {
          activities.add(activity);
        }
      }

      for (final place in places) {
        final activity = _buildPlaceActivity(place);
        if (activity != null) {
          activities.add(activity);
        }
      }

      final plans = _buildPlans(activities);

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
            'Lütfen internet bağlantını ve verileri kontrol et.';
      });
    }
  }

  _Activity? _buildEventActivity(
    Event event,
  ) {
    final now = DateTime.now();
    final start = event.startsAt.toLocal();

    if (!start.isAfter(now)) {
      return null;
    }

    final score = _scoreEvent(event);

    if (score <= 0) {
      return null;
    }

    return _Activity(
      type: _ActivityType.event,
      score: score,
      durationMinutes: _eventDuration(event),
      startsAt: start,
      event: event,
    );
  }

  _Activity? _buildPlaceActivity(
    Place place,
  ) {
    final score = _scorePlace(place);

    if (score <= 0) {
      return null;
    }

    final duration = _placeDuration(place);

    return _Activity(
      type: _ActivityType.place,
      score: score,
      durationMinutes: duration,
      startsAt: DateTime.now(),
      place: place,
    );
  }

  int _placeDuration(Place place) {
    final value = place.visitDurationMin;

    if (value == null || value <= 0) {
      return 120;
    }

    return value.clamp(30, 600);
  }

  int _eventDuration(Event event) {
    final starts = event.startsAt.toLocal();
    final ends = event.endsAt?.toLocal();

    if (ends != null && ends.isAfter(starts)) {
      final minutes = ends.difference(starts).inMinutes;

      if (minutes >= 20 && minutes <= 600) {
        return minutes;
      }
    }

    return 120;
  }

  double _scoreEvent(Event event) {
    final now = DateTime.now();
    final start = event.startsAt.toLocal();

    if (!start.isAfter(now)) {
      return 0;
    }

    double score = 40;

    final category = event.category.toLowerCase();
    final title = event.title.toLowerCase();
    final description =
        (event.description ?? '').toLowerCase();

    final allText =
        '$category $title $description';

    switch (_interest) {
      case InterestType.event:
        score += 55;
        break;

      case InterestType.music:
        if (_containsAny(
          allText,
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
          allText,
          <String>[
            'kültür',
            'culture',
            'sanat',
            'art',
            'theatre',
            'theater',
            'tiyatro',
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
          allText,
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
          allText,
          <String>[
            'tarih',
            'history',
            'historical',
            'tarihi',
          ],
        )) {
          score += 45;
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
        final min = event.priceMin;
        final max = event.priceMax;

        final isFree =
            (min == null || min == 0) &&
            (max == null || max == 0);

        if (!isFree) {
          return 0;
        }

        score += 45;
        break;

      case BudgetType.low:
        final price =
            event.priceMin ?? event.priceMax;

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
            event.priceMin ?? event.priceMax;

        if (price == null) {
          score += 6;
        } else if (price <= 1500) {
          score += 22;
        } else if (price <= 2500) {
          score += 4;
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
          allText,
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

    final duration = _eventDuration(event);

    score += _durationCompatibilityScore(
      duration,
      isEvent: true,
    );

    score += event.trustScore / 10;

    return score;
  }

  double _scorePlace(Place place) {
    double score = 35;

    final category =
        place.category.toLowerCase();

    final placeType =
        (place.placeType ?? '').toLowerCase();

    final tags = place.tags
        .map((tag) => tag.toLowerCase())
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

    final duration = _placeDuration(place);

    score += _durationCompatibilityScore(
      duration,
      isEvent: false,
    );

    if (place.verified) {
      score += 10;
    }

    score += place.trustScore / 10;

    return score;
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
        if (minutes >= 120 && minutes <= 300) {
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

    final sorted = <_Activity>[
      ...activities,
    ]..sort(
        (a, b) => b.score.compareTo(a.score),
      );

    final plans = <_DailyPlan>[];

    final target = _targetDurationMinutes();
    final maximum = _maximumPlanMinutes();

    // 1) Tek aktivite planları.
    for (final activity in sorted) {
      final total = activity.durationMinutes;

      if (total > maximum) {
        continue;
      }

      if (activity.type == _ActivityType.event &&
          !_eventFitsNow(activity)) {
        continue;
      }

      final fit = _durationFitBonus(
        total,
        target,
      );

      plans.add(
        _DailyPlan(
          score: activity.score + fit,
          activities: <_Activity>[
            activity,
          ],
          transitionMinutes: 0,
        ),
      );
    }

    final places = sorted
        .where(
          (item) =>
              item.type == _ActivityType.place,
        )
        .toList();

    final events = sorted
        .where(
          (item) =>
              item.type == _ActivityType.event,
        )
        .toList();

    // 2) Yer + etkinlik.
    for (final place in places.take(15)) {
      for (final event in events.take(15)) {
        final plan = _buildPlaceEventPlan(
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

    // 3) Yer + yer.
    for (var i = 0; i < places.length && i < 12; i++) {
      for (var j = i + 1;
          j < places.length && j < 12;
          j++) {
        final first = places[i];
        final second = places[j];

        final transitionMinutes =
            _estimatedTransitionMinutes(
          first,
          second,
        );

        final total =
            first.durationMinutes +
            transitionMinutes +
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
            8;

        plans.add(
          _DailyPlan(
            score: score,
            activities: <_Activity>[
              first,
              second,
            ],
            transitionMinutes: transitionMinutes,
          ),
        );
      }
    }

    plans.sort(
      (a, b) =>
          b.score.compareTo(a.score),
    );

    final unique =
        <String>{};

    final result =
        <_DailyPlan>[];

    for (final plan in plans) {
      if (unique.add(plan.signature)) {
        result.add(plan);
      }

      if (result.length >= 8) {
        break;
      }
    }

    return result;
  }

  bool _eventFitsNow(
    _Activity activity,
  ) {
    if (activity.event == null) {
      return true;
    }

    final now = DateTime.now();
    final start =
        activity.event!.startsAt.toLocal();

    return start.isAfter(now);
  }

  _DailyPlan? _buildPlaceEventPlan(
    _Activity place,
    _Activity event,
    int target,
    int maximum,
  ) {
    final eventStart =
        event.startsAt;

    final now = DateTime.now();

    final availableBeforeEvent =
        eventStart.difference(now).inMinutes;

    final transitionMinutes =
        _estimatedPlaceToEventMinutes(
      place,
      event,
    );

    final requiredBeforeEvent =
        place.durationMinutes +
        transitionMinutes;

    if (availableBeforeEvent <
        requiredBeforeEvent) {
      return null;
    }

    final total =
        place.durationMinutes +
        transitionMinutes +
        event.durationMinutes;

    if (total > maximum) {
      return null;
    }

    final score =
        place.score +
        event.score +
        _durationFitBonus(
          total,
          target,
        ) +
        18;

    return _DailyPlan(
      score: score,
      activities: <_Activity>[
        place,
        event,
      ],
      transitionMinutes: transitionMinutes,
    );
  }

  int _estimatedTransitionMinutes(
    _Activity first,
    _Activity second,
  ) {
    if (first.place != null &&
        second.place != null) {
      return _estimatedPlaceToPlaceMinutes(
        first.place!,
        second.place!,
      );
    }

    return 20;
  }

  int _estimatedPlaceToPlaceMinutes(
    Place first,
    Place second,
  ) {
    final distanceKm =
        _distanceKm(
      first.latitude,
      first.longitude,
      second.latitude,
      second.longitude,
    );

    if (distanceKm == null) {
      return 30;
    }

    // Şehir içi ortalama hız için kaba planlama.
    // Gerçek rota daha sonra Maps üzerinden hesaplanacak.
    final roadKm = distanceKm * 1.25;
    final minutes =
        (roadKm / 30 * 60).round();

    return minutes.clamp(10, 75);
  }

  int _estimatedPlaceToEventMinutes(
    _Activity place,
    _Activity event,
  ) {
    final placeItem = place.place;
    final eventItem = event.event;

    if (placeItem == null ||
        eventItem == null) {
      return 25;
    }

    final distanceKm =
        _distanceKm(
      placeItem.latitude,
      placeItem.longitude,
      eventItem.latitude,
      eventItem.longitude,
    );

    if (distanceKm == null) {
      return 25;
    }

    final roadKm = distanceKm * 1.25;
    final minutes =
        (roadKm / 30 * 60).round();

    return minutes.clamp(10, 75);
  }

  double? _distanceKm(
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

    const earthRadiusKm = 6371.0;

    final dLat =
        _degreesToRadians(lat2 - lat1);

    final dLon =
        _degreesToRadians(lon2 - lon1);

    final a =
        _sinSquared(dLat / 2) +
        _cosDegrees(lat1) *
            _cosDegrees(lat2) *
            _sinSquared(dLon / 2);

    final c =
        2 * _asinSafe(a.clamp(0.0, 1.0));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees * 3.141592653589793 / 180;
  }

  double _sinSquared(
    double value,
  ) {
    final sine = _sin(value);
    return sine * sine;
  }

  double _sin(
    double value,
  ) {
    // Küçük ve şehir içi mesafelerde
    // yeterli hassasiyet için Taylor yaklaşımı.
    double result = value;
    double term = value;

    for (var i = 1; i <= 8; i++) {
      term *=
          -value * value /
          ((2 * i) * (2 * i + 1));
      result += term;
    }

    return result;
  }

  double _cosDegrees(
    double degrees,
  ) {
    final radians =
        _degreesToRadians(degrees);

    double result = 1;
    double term = 1;

    for (var i = 1; i <= 8; i++) {
      term *=
          -radians * radians /
          ((2 * i - 1) * (2 * i));
      result += term;
    }

    return result;
  }

  double _asinSafe(
    double value,
  ) {
    if (value <= -1) {
      return -1.5707963267948966;
    }

    if (value >= 1) {
      return 1.5707963267948966;
    }

    // Newton-Raphson.
    double x = value;

    for (var i = 0; i < 8; i++) {
      final sinX = _sin(x);
      final cosX = _cos(x);

      if (cosX.abs() < 0.000001) {
        break;
      }

      x -=
          (sinX - value) / cosX;
    }

    return x;
  }

  double _cos(
    double value,
  ) {
    double result = 1;
    double term = 1;

    for (var i = 1; i <= 8; i++) {
      term *=
          -value * value /
          ((2 * i - 1) * (2 * i));
      result += term;
    }

    return result;
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
    switch (_duration) {
      case DurationType.short:
        return 'Yaklaşık 1-2 saatlik seçenekler.';

      case DurationType.medium:
        return 'Yaklaşık 3-5 saatlik planlar.';

      case DurationType.fullDay:
        return 'Günün büyük bölümünü değerlendiren seçenekler.';

      case DurationType.any:
        return 'Süre açısından dengelenmiş seçenekler.';
    }
  }

  String _durationLabel(
    int minutes,
  ) {
    if (minutes < 60) {
      return '$minutes dk';
    }

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

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

    return activity.place?.category ?? 'Yer';
  }

  String _activitySubtitle(
    _Activity activity,
  ) {
    if (activity.event != null) {
      final event = activity.event!;
      final time = _eventTime(
        event.startsAt,
      );

      if (event.venueName != null &&
          event.venueName!.trim().isNotEmpty) {
        return '$time · ${event.venueName}';
      }

      return time;
    }

    final place = activity.place!;

    final duration =
        _durationLabel(
      activity.durationMinutes,
    );

    if (place.isFree == true) {
      return '$duration · Ücretsiz';
    }

    return duration;
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
        plan.activities.last.event != null) {
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
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        plan.activities.length == 1
                            ? 'TEK AKTİVİTE'
                            : 'GÜNÜN PLANI',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: 1,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_durationLabel(plan.totalMinutes)} · ${_planTimeText(plan)}',
                        style: const TextStyle(
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
                      const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                  ),
                  child: Text(
                    '${plan.activities.length} adım',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
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
            const SizedBox(height: 5),
            if (plan.transitionMinutes > 0)
              Align(
                alignment:
                    Alignment.centerLeft,
                child: Padding(
                  padding:
                      const EdgeInsets.only(
                    left: 8,
                    top: 2,
                  ),
                  child: Text(
                    'Tahmini geçiş süresi: '
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
        activity.type == _ActivityType.event;

    return InkWell(
      borderRadius:
          BorderRadius.circular(18),
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
              decoration: BoxDecoration(
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
            const SizedBox(width: 12),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _activityCategory(
                      activity,
                    ).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black38,
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
            style: const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: 1,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
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

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
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
          const SizedBox(height: 12),
          const Text(
            'Bu kriterlere uygun bir plan bulamadım.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Süreyi veya bütçeyi biraz genişletirsen '
            'daha fazla seçenek bulabiliriz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF7F7F5),
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,
        title: const Text(
          'Bugün ne yapayım?',
          style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight:
                        FontWeight.w900,
                    height: 1.06,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 28),
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
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed:
                        _generateRecommendations,
                    icon: const Icon(
                      Icons.auto_awesome,
                    ),
                    label: const Text(
                      'BANA PLAN ÖNER',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w800,
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
                          18,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  _buildError(),
                ],
                if (_plans.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    _resultTitle(),
                    style:
                        const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _planSubtitle(),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._plans.map(
                    _buildPlanCard,
                  ),
                ],
                if (_hasSearched &&
                    !_loading &&
                    _plans.isEmpty &&
                    _error == null) ...[
                  const SizedBox(height: 30),
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
    if (activities.isEmpty) {
      return 0;
    }

    var total = transitionMinutes;

    for (final activity in activities) {
      total += activity.durationMinutes;
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

class _Choice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(30),
        onTap: onTap,
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: selected
                ? Colors.black
                : Colors.white,
            borderRadius:
                BorderRadius.circular(30),
            border: Border.all(
              color: selected
                  ? Colors.black
                  : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
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
