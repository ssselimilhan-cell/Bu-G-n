// ignore_for_file: invalid_use_of_protected_member

part of 'recommendation_screen.dart';

extension _RecommendationFilterControlMethods on _RecommendationScreenState {
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

  DateTime _dateOnly(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  DateTimeRange _selectedDateRange() {
    final today = _dateOnly(DateTime.now());

    switch (_dateFilter) {
      case _DateFilter.today:
        return DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        );
      case _DateFilter.tomorrow:
        final start = today.add(const Duration(days: 1));
        return DateTimeRange(
          start: start,
          end: start.add(const Duration(days: 1)),
        );
      case _DateFilter.thisWeek:
        final start = today.subtract(
          Duration(days: today.weekday - 1),
        );
        return DateTimeRange(
          start: start,
          end: start.add(const Duration(days: 7)),
        );
      case _DateFilter.thisMonth:
        final start = DateTime(today.year, today.month, 1);
        final end = today.month == 12
            ? DateTime(today.year + 1, 1, 1)
            : DateTime(today.year, today.month + 1, 1);
        return DateTimeRange(start: start, end: end);
      case _DateFilter.custom:
        final selected = _dateOnly(_customDate ?? today);
        return DateTimeRange(
          start: selected,
          end: selected.add(const Duration(days: 1)),
        );
    }
  }

  void _setDateFilter(_DateFilter filter) {
    if (filter == _DateFilter.custom) {
      _selectCustomDate();
      return;
    }

    setState(() {
      _dateFilter = filter;
      _results = <_Activity>[];
      _hasSearched = false;
      _error = null;
    });
  }

  Future<void> _selectCustomDate() async {
    final today = _dateOnly(DateTime.now());
    final current = _dateOnly(_customDate ?? today);
    final initialDate = current.isBefore(today) ? today : current;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'PLANLAMA TARİHİNİ SEÇ',
      cancelText: 'VAZGEÇ',
      confirmText: 'SEÇ',
      locale: const Locale('tr', 'TR'),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _dateFilter = _DateFilter.custom;
      _customDate = _dateOnly(picked);
      _results = <_Activity>[];
      _hasSearched = false;
      _error = null;
    });
  }

  String _dateFilterLabel() {
    switch (_dateFilter) {
      case _DateFilter.today:
        return 'Bugün';
      case _DateFilter.tomorrow:
        return 'Yarın';
      case _DateFilter.thisWeek:
        return 'Bu Hafta';
      case _DateFilter.thisMonth:
        return 'Bu Ay';
      case _DateFilter.custom:
        return _customDate == null ? 'Tarih Seç' : _shortDateLabel(_customDate!);
    }
  }

  String _shortDateLabel(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool _isEventInSelectedDate(Event event) {
    final range = _selectedDateRange();
    final start = event.startsAt.toLocal();
    final end = event.endsAt?.toLocal() ?? start;

    return start.isBefore(range.end) && !end.isBefore(range.start);
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
        label:
            Text(label),
        selected:
            selected,
        onSelected:
            (_) => onTap(),
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
        side:
            BorderSide(
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
      child:
          Column(
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

  Widget _buildDateFilters() {
    return Wrap(
      children: [
        _dateChoice(
          label: 'Bugün',
          filter: _DateFilter.today,
        ),
        _dateChoice(
          label: 'Yarın',
          filter: _DateFilter.tomorrow,
        ),
        _dateChoice(
          label: 'Bu Hafta',
          filter: _DateFilter.thisWeek,
        ),
        _dateChoice(
          label: 'Bu Ay',
          filter: _DateFilter.thisMonth,
        ),
        _dateChoice(
          label: _dateFilter == _DateFilter.custom
              ? _dateFilterLabel()
              : 'Tarih Seç',
          filter: _DateFilter.custom,
          icon: Icons.calendar_month_outlined,
        ),
      ],
    );
  }

  Widget _dateChoice({
    required String label,
    required _DateFilter filter,
    IconData? icon,
  }) {
    final selected = _dateFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 7, bottom: 7),
      child: ChoiceChip(
        avatar: icon == null ? null : Icon(icon, size: 16),
        label: Text(label),
        selected: selected,
        onSelected: (_) => _setDateFilter(filter),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : Colors.black,
        ),
        selectedColor: Colors.black,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? Colors.black : Colors.grey.shade300,
        ),
      ),
    );
  }


}
