part of 'recommendation_screen.dart';

extension _RecommendationMatchingMethods on _RecommendationScreenState {
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

      case InterestType.food:
        return _containsAny(
          text,
          [
            'yemek',
            'yeme-içme',
            'restoran',
            'restaurant',
            'kafe',
            'cafe',
            'kahve',
            'coffee',
            'gastronomi',
            'tadım',
            'food',
            'drink',
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

      case InterestType.food:
        return _containsAny(
          text,
          [
            'yemek',
            'yeme-içme',
            'restoran',
            'restaurant',
            'kafe',
            'cafe',
            'kahve',
            'coffee',
            'gastronomi',
            'tadım',
            'food',
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

      if (price == null &&
          (budget ==
                  BudgetType.low ||
              budget ==
                  BudgetType.medium)) {
        return true;
      }

      if (budget ==
              BudgetType.low &&
          price != null &&
          price <= 1000) {
        return true;
      }

      if (budget ==
              BudgetType.medium &&
          price != null &&
          price <= 2500) {
        return true;
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


}
