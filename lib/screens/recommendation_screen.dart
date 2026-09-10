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
  final EventService _eventService =
      EventService();

  final PlaceService _placeService =
      PlaceService();

  CompanionType _companion =
      CompanionType.any;

  BudgetType _budget =
      BudgetType.any;

  DurationType _duration =
      DurationType.any;

  InterestType _interest =
      InterestType.any;

  bool _loading = false;
  bool _hasSearched = false;

  String? _error;

  List<_DailyPlan> _plans = [];

  Future<void> _generateRecommendations() async {
    setState(() {
      _loading = true;
      _hasSearched = true;
      _error = null;
      _plans = [];
    });

    try {
      final result = await Future.wait([
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

      if (!mounted) return;

      setState(() {
        _plans = plans;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'Öneriler oluşturulurken bir sorun oluştu.';
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

    final duration =
        _eventDuration(event);

    return _Activity(
      type: _ActivityType.event,
      score: score,
      durationMinutes: duration,
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

    final duration =
        place.visitDurationMin ??
            120;

    return _Activity(
      type: _ActivityType.place,
      score: score,
      durationMinutes: duration,
      startsAt: DateTime.now(),
      place: place,
    );
  }

  int _eventDuration(Event event) {
    final starts =
        event.startsAt.toLocal();

    final ends =
        event.endsAt?.toLocal();

    if (ends != null &&
        ends.isAfter(starts)) {
      final minutes =
          ends.difference(starts).inMinutes;

      if (minutes >= 20 &&
          minutes <= 480) {
        return minutes;
      }
    }

    return 120;
  }

  double _scoreEvent(Event event) {
    final now = DateTime.now();
    final start =
        event.startsAt.toLocal();

    if (!start.isAfter(now)) {
      return 0;
    }

    double score = 35;

    final category =
        event.category.toLowerCase();

    final title =
        event.title.toLowerCase();

    final description =
        (event.description ?? '')
            .toLowerCase();

    final allText =
        '$category $title $description';

    switch (_interest) {
      case InterestType.event:
        score += 50;
        break;

      case InterestType.music:
        if (category.contains('music') ||
            category.contains('müzik') ||
            allText.contains('konser')) {
          score += 50;
        } else {
          score -= 25;
        }
        break;

      case InterestType.culture:
        if (category.contains('arts') ||
            category.contains('art') ||
            category.contains('culture') ||
            category.contains('kültür') ||
            category.contains('theatre') ||
            category.contains('tiyatro')) {
          score += 42;
        } else {
          score -= 20;
        }
        break;

      case InterestType.museum:
        if (category.contains('museum') ||
            category.contains('müze')) {
          score += 45;
        } else {
          score -= 25;
        }
        break;

      case InterestType.history:
        if (allText.contains('tarih') ||
            allText.contains('history')) {
          score += 35;
        } else {
          score -= 10;
        }
        break;

      case InterestType.nature:
      case InterestType.park:
        score -= 15;
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
            min == 0 &&
            (max == null || max == 0);

        if (isFree) {
          score += 45;
        } else {
          return 0;
        }
        break;

      case BudgetType.low:
        final price =
            event.priceMin ??
                event.priceMax;

        if (price == null) {
          score += 5;
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
          score += 4;
        } else if (price <= 1500) {
          score += 20;
        } else {
          score -= 10;
        }
        break;

      case BudgetType.any:
        break;
    }

    if (_companion ==
        CompanionType.family) {
      if (allText.contains('aile') ||
          allText.contains('family') ||
          allText.contains('çocuk') ||
          allText.contains('kids')) {
        score += 25;
      }
    }

    if (_companion ==
        CompanionType.couple) {
      score += 8;
    }

    final minutesUntil =
        start
            .difference(now)
            .inMinutes;

    if (minutesUntil >= 0 &&
        minutesUntil <= 180) {
      score += 15;
    } else if (minutesUntil <= 1440) {
      score += 8;
    }

    final duration =
        _eventDuration(event);

    score +=
        _durationCompatibilityScore(
      duration,
      isEvent: true,
    );

    score +=
        event.trustScore / 10;

    return score;
  }

  double _scorePlace(Place place) {
    double score = 30;

    final category =
        place.category.toLowerCase();

    final placeType =
        (place.placeType ?? '')
            .toLowerCase();

    final tags =
        place.tags
            .map(
              (tag) => tag.toLowerCase(),
            )
            .join(' ');

    final allText =
        '$category $placeType $tags';

    switch (_interest) {
      case InterestType.nature:
        if (category.contains('doğa') ||
            place.outdoor == true ||
            allText.contains('nature')) {
          score += 50;
        } else {
          score -= 30;
        }
        break;

      case InterestType.park:
        if (category.contains('park')) {
          score += 50;
        } else {
          score -= 30;
        }
        break;

      case InterestType.history:
        if (category.contains('tarih') ||
            allText.contains('tarih') ||
            allText.contains('historic')) {
          score += 48;
        } else {
          score -= 20;
        }
        break;

      case InterestType.museum:
        if (category.contains('müze') ||
            allText.contains('museum')) {
          score += 50;
        } else {
          score -= 25;
        }
        break;

      case InterestType.culture:
        if (category.contains('kültür') ||
            allText.contains('culture')) {
          score += 45;
        } else {
          score -= 10;
        }
        break;

      case InterestType.event:
      case InterestType.music:
        score -= 20;
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
          score += 5;
        }
        break;

      case BudgetType.medium:
        score += 10;
        break;

      case BudgetType.any:
        break;
    }

    if (_companion ==
        CompanionType.family) {
      if (place.kidsFriendly == true) {
        score += 40;
      } else {
        score -= 8;
      }
    }

    if (_companion ==
        CompanionType.couple) {
      score += 8;
    }

    if (_companion ==
        CompanionType.solo) {
      score += 5;
    }

    if (_duration !=
        DurationType.any) {
      final minutes =
          place.visitDurationMin ??
              120;

      score +=
          _durationCompatibilityScore(
        minutes,
        isEvent: false,
      );
    }

    if (place.verified) {
      score += 8;
    }

    score +=
        place.trustScore / 10;

    return score;
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
          return 8;
        }

        return -30;

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
        if (minutes >= 240) {
          return 30;
        }

        return 5;

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

  List<_DailyPlan> _buildPlans(
    List<_Activity> activities,
  ) {
    if (activities.isEmpty) {
      return [];
    }

    final sorted =
        [...activities]
          ..sort(
            (a, b) =>
                b.score.compareTo(
              a.score,
            ),
          );

    final plans =
        <_DailyPlan>[];

    final target =
        _targetDurationMinutes();

    // Önce tek aktiviteler.
    for (final activity in sorted) {
      if (activity.durationMinutes >
          target + 90) {
        continue;
      }

      final fit =
          _durationFitBonus(
        activity.durationMinutes,
        target,
      );

      plans.add(
        _DailyPlan(
          score:
              activity.score + fit,
          activities: [
            activity,
          ],
        ),
      );
    }

    // Sonra iki aşamalı gerçek planlar.
    final places = sorted
        .where(
          (item) =>
              item.type ==
              _ActivityType.place,
        )
        .toList();

    final events = sorted
        .where(
          (item) =>
              item.type ==
              _ActivityType.event,
        )
        .toList();

    // Yer + etkinlik.
    for (final place in places.take(12)) {
      for (final event in events.take(12)) {
        final plan =
            _buildPlaceEventPlan(
          place,
          event,
          target,
        );

        if (plan != null) {
          plans.add(plan);
        }
      }
    }

    // İki farklı yer.
    for (var i = 0;
        i < places.length &&
            i < 12;
        i++) {
      for (var j = i + 1;
          j < places.length &&
              j < 12;
          j++) {
        final first = places[i];
        final second = places[j];

        final total =
            first.durationMinutes +
                second.durationMinutes +
                20;

        if (total >
            target + 30) {
          continue;
        }

        final score =
            first.score +
                second.score +
                _durationFitBonus(
                  total,
                  target,
                );

        plans.add(
          _DailyPlan(
            score: score,
            activities: [
              first,
              second,
            ],
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

    final unique =
        <String>{};

    final result =
        <_DailyPlan>[];

    for (final plan in plans) {
      final key =
          plan.signature;

      if (unique.add(key)) {
        result.add(plan);
      }

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
  ) {
    final eventStart =
        event.startsAt;

    final now =
        DateTime.now();

    final availableMinutes =
        eventStart
            .difference(now)
            .inMinutes;

    if (availableMinutes <=
        place.durationMinutes) {
      return null;
    }

    final travelBuffer = 20;

    final total =
        place.durationMinutes +
            travelBuffer +
            event.durationMinutes;

    if (total >
        target + 60) {
      return null;
    }

    final score =
        place.score +
            event.score +
            _durationFitBonus(
              total,
              target,
            ) +
            15;

    return _DailyPlan(
      score: score,
      activities: [
        place,
        event,
      ],
    );
  }

  double _durationFitBonus(
    int actual,
    int target,
  ) {
    final difference =
        (actual - target).abs();

    if (difference <= 30) {
      return 40;
    }

    if (difference <= 60) {
      return 25;
    }

    if (difference <= 120) {
      return 10;
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
                    letterSpacing:
                        -0.8,
                  ),
                ),
                const SizedBox(
                  height: 28,
                ),

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
                    style: TextStyle(
                      fontSize: 12,
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

  String _planSubtitle() {
    switch (_duration) {
      case DurationType.short:
        return 'Yaklaşık 1-2 saatlik seçenekler.';

      case DurationType.medium:
        return 'Yaklaşık 3-5 saatlik planlar.';

      case DurationType.fullDay:
        return 'Daha uzun, günün büyük bölümünü değerlendiren planlar.';

      case DurationType.any:
        return 'Süre açısından dengeli seçenekler.';
    }
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
              color:
                  Colors.black54,
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
          onTap: () =>
              setState(
            () {
              _companion =
                  CompanionType.solo;
            },
          ),
        ),
        _Choice(
          label: 'İki kişi',
          selected:
              _companion ==
                  CompanionType.couple,
          onTap: () =>
              setState(
            () {
              _companion =
                  CompanionType.couple;
            },
          ),
        ),
        _Choice(
          label: 'Aile',
          selected:
              _companion ==
                  CompanionType.family,
          onTap: () =>
              setState(
            () {
              _companion =
                  CompanionType.family;
            },
          ),
        ),
        _Choice(
          label: 'Farketmez',
          selected:
              _companion ==
                  CompanionType.any,
          onTap: () =>
              setState(
            () {
              _companion =
                  CompanionType.any;
            },
          ),
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
          onTap: () =>
              setState(
            () {
              _budget =
                  BudgetType.free;
            },
          ),
        ),
        _Choice(
          label: 'Ekonomik',
          selected:
              _budget ==
                  BudgetType.low,
          onTap: () =>
              setState(
            () {
              _budget =
                  BudgetType.low;
            },
          ),
        ),
        _Choice(
          label: 'Orta bütçe',
          selected:
              _budget ==
                  BudgetType.medium,
          onTap: () =>
              setState(
            () {
              _budget =
                  BudgetType.medium;
            },
          ),
        ),
        _Choice(
          label: 'Farketmez',
          selected:
              _budget ==
                  BudgetType.any,
          onTap: () =>
              setState(
            () {
              _budget =
                  BudgetType.any;
            },
          ),
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
          onTap: () =>
              setState(
            () {
              _duration =
                  DurationType.short;
            },
          ),
        ),
        _Choice(
          label: '3-5 saat',
          selected:
              _duration ==
                  DurationType.medium,
          onTap: () =>
              setState(
            () {
              _duration =
                  DurationType.medium;
            },
          ),
        ),
        _Choice(
          label: 'Tüm gün',
          selected:
              _duration ==
                  DurationType.fullDay,
          onTap: () =>
              setState(
            () {
              _duration =
                  DurationType.fullDay;
            },
          ),
        ),
        _Choice(
          label: 'Farketmez',
          selected:
              _duration ==
                  DurationType.any,
          onTap: () =>
              setState(
            () {
              _duration =
                  DurationType.any;
            },
          ),
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
          onTap: () =>
              setState(
            () {
              _interest =
                  InterestType.event;
            },
          ),
        ),
        _Choice(
          label: 'Müzik',
          selected:
              _interest ==
                  InterestType.music,
          onTap: () =>
              setState(
            () {
              _interest =
                  InterestType.music;
            },
          ),
        ),
        _Choice(
          label: 'Doğa',
          selected:
              _interest ==
                  InterestType.nature,
          onTap: () =>
              setState(
            () {
              _interest =
                  InterestType.nature;
            },
          ),
        ),
        _Choice(
          label: 'Park',
          selected:
              _interest ==
                  InterestType.park,
          onTap: () =>
              setState(
            () {
              _interest =
                  InterestType.park;
            },
          ),
        ),
        _Choice(
          label: 'Tarih',
          selected:
              _interest ==
                  InterestType.history,
          onTap: () =>
              setState(
            () {
              _interest =
                  InterestType.history;
            },
          ),
        ),
        _Choice(
          label: 'Müze',
          selected:
              _interest ==
                  InterestType.museum,
          onTap: () =>
              setState(
            () {
              _interest =
                  InterestType.museum;
            },
          ),
        ),
        _Choice(
          label: 'Kültür',
          selected:
              _interest ==
                  InterestType.culture,
          onTap: () =>
              setState(
            () {
              _interest =
                  InterestType.culture;
            },
          ),
        ),
        _Choice(
          label: 'Karışık',
          selected:
              _interest ==
                  InterestType.any,
          onTap: () =>
              setState(
            () {
              _interest =
                  InterestType.any;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    _DailyPlan plan,
  ) {
    final totalMinutes =
        plan.totalDuration;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border:
            Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          17,
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 19,
                ),
                const SizedBox(
                  width: 7,
                ),
                Expanded(
                  child:
                      Text(
                    plan.activities
                                .length ==
                            1
                        ? 'ÖNERİ'
                        : 'GÜN PLANI',
                    style:
                        const TextStyle(
                      fontSize:
                          10,
                      fontWeight:
                          FontWeight
                              .w900,
                      letterSpacing:
                          1,
                    ),
                  ),
                ),
                Text(
                  _formatDuration(
                    totalMinutes,
                  ),
                  style:
                      const TextStyle(
                    fontSize:
                        11,
                    fontWeight:
                        FontWeight.w800,
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
                final activity =
                    plan.activities[
                        index];

                return _buildPlanActivity(
                  activity,
                  index,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanActivity(
    _Activity activity,
    int index,
  ) {
    final isLast =
        index ==
            _plans.first.activities.length -
                1;

    return Column(
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
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
                        _ActivityType
                            .event
                    ? Icons
                        .event_outlined
                    : Icons
                        .place_outlined,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    activity
                            .type ==
                        _ActivityType
                            .event
                        ? activity
                            .event!
                            .title
                        : activity
                            .place!
                            .name,
                    maxLines:
                        2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontSize:
                          15,
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    _activitySubtitle(
                      activity,
                    ),
                    style:
                        TextStyle(
                      fontSize:
                          11,
                      color: Colors
                          .grey
                          .shade600,
                      height:
                          1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              _formatDuration(
                activity.durationMinutes,
              ),
              style:
                  const TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(
            height: 12,
          ),
          Row(
            children: [
              const SizedBox(
                width: 20,
              ),
              Container(
                width: 1,
                height: 22,
                color:
                    Colors.grey.shade300,
              ),
              const SizedBox(
                width: 19,
              ),
              const Text(
                '+ yaklaşık 20 dk ulaşım payı',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
        ],
      ],
    );
  }

  String _activitySubtitle(
    _Activity activity,
  ) {
    if (activity.type ==
        _ActivityType.event) {
      final event =
          activity.event!;

      final time =
          DateFormat(
        'd MMM · HH:mm',
        'tr_TR',
      ).format(
        event.startsAt.toLocal(),
      );

      return [
        time,
        if (event.venueName !=
                null &&
            event.venueName!
                .trim()
                .isNotEmpty)
          event.venueName!,
      ].join(' • ');
    }

    final place =
        activity.place!;

    return [
      place.category,
      if (place.isFree == true)
        'Ücretsiz',
    ].join(' • ');
  }

  String _formatDuration(
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
      return '$hours sa';
    }

    return '$hours sa $remaining dk';
  }

  Widget _buildError() {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child:
          Row(
        children: [
          const Icon(
            Icons.error_outline,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child:
                Text(
              _error!,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
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
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child:
          const Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 44,
          ),
          SizedBox(
            height: 12,
          ),
          Text(
            'Bu tercihlere uygun yeterli plan bulamadık.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize:
                  15,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          SizedBox(
            height: 7,
          ),
          Text(
            'Süre veya bütçe seçeneklerinden birini “Farketmez” yaparak tekrar deneyebilirsin.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize:
                  12,
              color:
                  Colors.grey,
              height:
                  1.4,
            ),
          ),
        ],
      ),
    );
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
    return GestureDetector(
      onTap:
          selected ? null : onTap,
      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds:
              160,
        ),
        padding:
            const EdgeInsets
                .symmetric(
          horizontal:
              14,
          vertical:
              10,
        ),
        decoration:
            BoxDecoration(
          color:
              selected
                  ? Colors.black
                  : Colors.white,
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          border:
              Border.all(
            color:
                selected
                    ? Colors.black
                    : Colors.grey
                        .shade300,
          ),
        ),
        child:
            Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            if (selected)
              const Padding(
                padding:
                    EdgeInsets.only(
                  right: 5,
                ),
                child:
                    Icon(
                  Icons.check,
                  size: 15,
                  color:
                      Colors.white,
                ),
              ),
            Text(
              label,
              style:
                  TextStyle(
                fontSize:
                    12,
                fontWeight:
                    FontWeight.w700,
                color:
                    selected
                        ? Colors.white
                        : Colors.black,
              ),
            ),
          ],
        ),
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

  const _DailyPlan({
    required this.score,
    required this.activities,
  });

  int get totalDuration {
    if (activities.length <= 1) {
      return activities.first.durationMinutes;
    }

    return activities.fold<int>(
          0,
          (sum, activity) =>
              sum +
              activity.durationMinutes,
        ) +
        ((activities.length - 1) * 20);
  }

  String get signature {
    return activities
        .map(
          (activity) =>
              activity.type ==
                      _ActivityType.event
                  ? 'e:${activity.event!.id}'
                  : 'p:${activity.place!.id}',
        )
        .join('|');
  }
}
