import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event.dart';
import '../models/place.dart';
import '../services/event_service.dart';
import '../services/place_service.dart';
import '../services/city_preference_service.dart';
import 'event_detail_screen.dart';
import 'place_detail_screen.dart';

part 'recommendation_location.dart';
part 'recommendation_filter_controls.dart';
part 'recommendation_filter_widgets.dart';
part 'recommendation_logic.dart';
part 'recommendation_matching.dart';
part 'recommendation_queue.dart';
part 'recommendation_card_image.dart';
part 'recommendation_cards.dart';

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

enum _DateFilter {
  today,
  tomorrow,
  thisWeek,
  thisMonth,
  custom,
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

  List<_Activity> _results =
      <_Activity>[];

  final List<_Activity> _queue =
      <_Activity>[];

  _DateFilter _dateFilter = _DateFilter.today;
  DateTime? _customDate;

  @override
  void initState() {
    super.initState();
    _tryGetLocationSilently();
  }


  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F5),
      appBar:
          AppBar(
        backgroundColor:
            const Color(0xFFF7F7F5),
        surfaceTintColor:
            Colors.transparent,
        elevation:
            0,
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
      body:
          _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : SafeArea(
                  child:
                      Padding(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      14,
                      2,
                      14,
                      4,
                    ),
                    child:
                        Column(
                      children: [
                        Expanded(
                          child:
                              ListView(
                            padding:
                                const EdgeInsets
                                    .only(
                              bottom:
                                  12,
                            ),
                            children: [
                              const Text(
                                'Planını kendine göre seç',
                                style:
                                    TextStyle(
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                  height: 1.0,
                                  letterSpacing:
                                      -0.8,
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              _buildLocationStatus(),
                              _buildFilterChips(),
                              if (_error !=
                                  null)
                                Container(
                                  margin:
                                      const EdgeInsets
                                          .only(
                                    bottom:
                                        16,
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
                              if (_results
                                  .isNotEmpty)
                                const Text(
                                  'ÖNERİLER',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        11,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                    letterSpacing:
                                        1,
                                    color:
                                        Colors
                                            .black54,
                                  ),
                                ),
                              if (_results
                                  .isNotEmpty)
                                const SizedBox(
                                  height:
                                      10,
                                ),
                              ..._results.map(
                                _buildResultCard,
                              ),
                              if (_hasSearched &&
                                  _results
                                      .isEmpty &&
                                  _error ==
                                      null)
                                Container(
                                  margin:
                                      const EdgeInsets
                                          .only(
                                    top:
                                        10,
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
                                        Icons
                                            .search_off_rounded,
                                        size:
                                            42,
                                      ),
                                      SizedBox(
                                        height:
                                            10,
                                      ),
                                      Text(
                                        'Bu kriterlere uygun sonuç bulamadım.',
                                        textAlign:
                                            TextAlign
                                                .center,
                                        style:
                                            TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .w800,
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
          FloatingActionButtonLocation
              .centerFloat,
    );
  }

  Widget _buildRecommendationButton() {
    return SafeArea(
      child:
          Padding(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal:
              20,
        ),
        child:
            SizedBox(
          width:
              double.infinity,
          height:
              53,
          child:
              FilledButton
                  .icon(
            onPressed:
                _generateRecommendations,
            icon:
                const Icon(
              Icons.auto_awesome,
            ),
            label:
                Text(
              '${_dateFilterLabel().toUpperCase()} İÇİN PLAN ÖNER',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight
                        .w900,
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
                    BorderRadius
                        .circular(
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

class _InfoPill
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal:
            9,
        vertical:
            6,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF4F4F2,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size:
                13,
            color:
                Colors.black54,
          ),
          const SizedBox(
            width:
                4,
          ),
          Flexible(
            child:
                Text(
              text,
              maxLines:
                  1,
              overflow:
                  TextOverflow
                      .ellipsis,
              style:
                  const TextStyle(
                fontSize:
                    10,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}