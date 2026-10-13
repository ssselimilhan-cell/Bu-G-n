part of 'recommendation_screen.dart';

extension _RecommendationFilterWidgetMethods on _RecommendationScreenState {
  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _section(
          'NE ZAMAN?',
          _buildDateFilters(),
        ),
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
                    'Yeme-İçme',
                selected:
                    _interests.contains(
                  InterestType.food,
                ),
                onTap: () =>
                    _toggleInterest(
                  InterestType.food,
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


}
