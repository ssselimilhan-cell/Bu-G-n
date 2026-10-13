part of 'recommendation_screen.dart';

extension _RecommendationLogicMethods on _RecommendationScreenState {
  Future<void> _generateRecommendations() async {
    setState(() {
      _loading = true;
      _hasSearched = true;
      _error = null;
      _results = <_Activity>[];
    });

    await _refreshLocation();

    try {
      final selectedCity = await CityPreferenceService().getSelectedCity();
      final response =
          await Future.wait<Object>([
        _eventService
            .getUpcomingEvents(
          city: selectedCity,
          days: 366,
          limit: 500,
        ),
        _placeService.getPlaces(
          city: selectedCity,
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
            _makeEventActivity(
          event,
        );

        if (item != null) {
          activities.add(item);
        }
      }

      for (final place in places) {
        final item =
            _makePlaceActivity(
          place,
        );

        if (item != null) {
          activities.add(item);
        }
      }

      activities.sort(
        (a, b) =>
            b.score.compareTo(
          a.score,
        ),
      );

      final unique =
          <String>{};

      final filtered =
          <_Activity>[];

      for (final activity
          in activities) {
        if (!unique.add(
          activity.id,
        )) {
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

    if (!_isEventInSelectedDate(event)) {
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
    ).toInt();
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
    if (!_matchesInterestForEvent(event)) {
      return 0;
    }

    if (!_matchesBudgetForEvent(event)) {
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

    final minutesUntil =
        event.startsAt
            .toLocal()
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
    if (!_matchesInterestForPlace(place)) {
      return 0;
    }

    if (!_matchesBudgetForPlace(place)) {
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

  bool _containsAny(
    String text,
    List<String> values,
  ) {
    final source =
        text.toLowerCase();

    for (final value in values) {
      if (source.contains(
        value.toLowerCase(),
      )) {
        return true;
      }
    }

    return false;
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


  String _priceLabel(
    Event event,
  ) {
    final min =
        event.priceMin;

    final max =
        event.priceMax;

    if (min == null &&
        max == null) {
      return '';
    }

    if ((min == null ||
            min == 0) &&
        (max == null ||
            max == 0)) {
      return 'Ücretsiz';
    }

    if (min != null &&
        max != null &&
        min != max) {
      return '${_formatPrice(min)}–${_formatPrice(max)} TL';
    }

    final price =
        min ?? max!;

    return '${_formatPrice(price)} TL';
  }

  String _formatPrice(
    double value,
  ) {
    if (value ==
        value.roundToDouble()) {
      return value
          .round()
          .toString();
    }

    return value.toStringAsFixed(
      0,
    );
  }

  String _dateLabel(
    DateTime dateTime,
  ) {
    final local =
        dateTime.toLocal();

    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];

    return '${local.day} '
        '${months[local.month - 1]} '
        '${local.year} · '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
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


}
