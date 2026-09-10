import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/place.dart';
import '../services/event_service.dart';
import '../services/place_service.dart';
import 'event_detail_screen.dart';
import 'explore_screen.dart';
import 'place_detail_screen.dart';
import 'profile_screen.dart';
import 'recommendation_screen.dart';
import 'saved_screen.dart';

enum EventPeriod {
  today,
  week,
  month,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  final EventService _eventService =
      EventService();

  final PlaceService _placeService =
      PlaceService();

  final TextEditingController
      _eventSearchController =
      TextEditingController();

  List<Event> _events =
      <Event>[];

  List<Place> _places =
      <Place>[];

  bool _eventsLoading = true;
  bool _placesLoading = true;

  String? _eventsError;
  String? _placesError;

  EventPeriod _selectedPeriod =
      EventPeriod.today;

  int _selectedIndex = 0;

  String _eventSearch = '';

  @override
  void initState() {
    super.initState();
    _loadHome();
    _eventSearchController.addListener(
      _onSearchChanged,
    );
  }

  @override
  void dispose() {
    _eventSearchController
        .removeListener(
      _onSearchChanged,
    );

    _eventSearchController.dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _eventSearch =
          _eventSearchController.text
              .trim()
              .toLowerCase();
    });
  }

  Future<void> _loadHome() async {
    await Future.wait([
      _loadEvents(),
      _loadPlaces(),
    ]);
  }

  Future<void> _loadEvents() async {
    setState(() {
      _eventsLoading = true;
      _eventsError = null;
    });

    try {
      final events =
          await _eventService
              .getUpcomingEvents(
        city: 'Ankara',
        days: 31,
        limit: 200,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _events = events;
        _eventsLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _eventsLoading = false;
        _eventsError =
            'Etkinlikler yüklenemedi.';
      });
    }
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _placesLoading = true;
      _placesError = null;
    });

    try {
      final places =
          await _placeService.getPlaces(
        city: 'Ankara',
        limit: 50,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _places = places;
        _placesLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _placesLoading = false;
        _placesError =
            'Yerler yüklenemedi.';
      });
    }
  }

  Future<void> _selectPeriod(
    EventPeriod period,
  ) async {
    setState(() {
      _selectedPeriod = period;
      _eventSearchController.clear();
      _eventsLoading = true;
      _eventsError = null;
    });

    try {
      late List<Event> events;

      switch (period) {
        case EventPeriod.today:
          events =
              await _eventService
                  .getTodayEvents(
            city: 'Ankara',
            limit: 100,
          );
          break;

        case EventPeriod.week:
          events =
              await _eventService
                  .getThisWeekEvents(
            city: 'Ankara',
            limit: 100,
          );
          break;

        case EventPeriod.month:
          events =
              await _eventService
                  .getThisMonthEvents(
            city: 'Ankara',
            limit: 200,
          );
          break;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _events = events;
        _eventsLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _eventsLoading = false;
        _eventsError =
            'Etkinlikler yüklenemedi.';
      });
    }
  }

  List<Event> get _filteredEvents {
    if (_eventSearch.isEmpty) {
      return _events;
    }

    return _events.where(
      (event) {
        final text = [
          event.title,
          event.category,
          event.description ?? '',
          event.venueName ?? '',
          event.address ?? '',
        ].join(' ').toLowerCase();

        return text.contains(
          _eventSearch,
        );
      },
    ).toList();
  }

  void _openRecommendation() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            const RecommendationScreen(),
      ),
    );
  }

  void _openCategory(
    String category,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ExploreScreen(
          initialCategory:
              category,
        ),
      ),
    );
  }

  void _openEvent(
    Event event,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            EventDetailScreen(
          event: event,
        ),
      ),
    );
  }

  void _openPlace(
    Place place,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            PlaceDetailScreen(
          place: place,
        ),
      ),
    );
  }

  void _setMainTab(
    int index,
  ) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return PopScope(
      canPop:
          _selectedIndex == 0,
      onPopInvokedWithResult:
          (didPop, result) {
        if (didPop) {
          return;
        }

        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: _buildCurrentPage(),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 1:
        return const ExploreScreen();

      case 2:
        return const SavedScreen();

      case 3:
        return const ProfileScreen();

      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
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
          'BUGÜN',
          style: TextStyle(
            fontSize: 27,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(
              right: 12,
            ),
            child: IconButton(
              onPressed: () =>
                  setState(() {
                _selectedIndex = 3;
              }),
              icon: const Icon(
                Icons
                    .person_outline_rounded,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHome,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              30,
            ),
            children: [
              Text(
                'Ankara',
                style:
                    TextStyle(
                  fontSize: 14,
                  color:
                      Colors.grey.shade600,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              const Text(
                'Bugün Ankara’da\nne yapmak istersin?',
                style:
                    TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w900,
                  height: 1.06,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              _buildRecommendationButton(),
              const SizedBox(
                height: 25,
              ),
              _buildCategories(),
              const SizedBox(
                height: 28,
              ),
              _buildEventsSection(),
              const SizedBox(
                height: 30,
              ),
              _buildPlacesSection(),
              const SizedBox(
                height: 25,
              ),
              _buildExploreButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            _selectedIndex,
        onDestinationSelected:
            _setMainTab,
        backgroundColor:
            Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon:
                Icon(Icons.home),
            label: 'Bugün',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.explore_outlined,
            ),
            selectedIcon:
                Icon(Icons.explore),
            label: 'Keşfet',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.bookmark_outline,
            ),
            selectedIcon:
                Icon(Icons.bookmark),
            label: 'Kayıt',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon:
                Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton.icon(
        onPressed:
            _openRecommendation,
        icon:
            const Icon(
          Icons.auto_awesome,
        ),
        label:
            const Text(
          'Bugün ne yapayım?',
          style:
              TextStyle(
            fontSize: 16,
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
              18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    const categories = [
      {
        'name': 'Doğa',
        'icon': Icons
            .park_outlined,
      },
      {
        'name': 'Park',
        'icon': Icons
            .grass_outlined,
      },
      {
        'name': 'Tarih',
        'icon': Icons
            .account_balance_outlined,
      },
      {
        'name': 'Müze',
        'icon': Icons
            .museum_outlined,
      },
      {
        'name': 'Kültür',
        'icon': Icons
            .theater_comedy_outlined,
      },
      {
        'name': 'Sinema',
        'icon': Icons
            .movie_outlined,
      },
    ];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'KATEGORİLER',
          style:
              TextStyle(
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
        GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount:
              categories.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.45,
          ),
          itemBuilder:
              (context, index) {
            final item =
                categories[index];

            return InkWell(
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              onTap: () =>
                  _openCategory(
                item['name']
                    as String,
              ),
              child:
                  Container(
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.grey.shade200,
                  ),
                ),
                child:
                    Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      item['icon']
                          as IconData,
                      size: 23,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      item['name']
                          as String,
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
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEventsSection() {
    final title =
        _selectedPeriod ==
                EventPeriod.today
            ? 'BUGÜN ANKARA’DA'
            : _selectedPeriod ==
                    EventPeriod.week
                ? 'BU HAFTA ANKARA’DA'
                : 'BU AY ANKARA’DA';

    final events =
        _filteredEvents;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child:
                  Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        _buildPeriodSelector(),
        if (_selectedPeriod ==
            EventPeriod.month) ...[
          const SizedBox(
            height: 10,
          ),
          _buildEventSearch(),
        ],
        const SizedBox(
          height: 14,
        ),
        if (_eventsLoading)
          const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical: 45,
            ),
            child: Center(
              child:
                  CircularProgressIndicator(),
            ),
          )
        else if (_eventsError != null)
          _buildEmptyCard(
            _eventsError!,
          )
        else if (events.isEmpty)
          _buildEmptyCard(
            _selectedPeriod ==
                    EventPeriod.month &&
                _eventSearch.isNotEmpty
                ? 'Aramana uygun etkinlik bulunamadı.'
                : 'Bu zaman aralığında etkinlik bulunmuyor.',
          )
        else
          ...events
              .take(
            _selectedPeriod ==
                    EventPeriod.month
                ? 30
                : 10,
          )
              .map(
            _buildEventCard,
          ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: _periodButton(
            'Bugün',
            EventPeriod.today,
          ),
        ),
        const SizedBox(
          width: 7,
        ),
        Expanded(
          child: _periodButton(
            'Bu Hafta',
            EventPeriod.week,
          ),
        ),
        const SizedBox(
          width: 7,
        ),
        Expanded(
          child: _periodButton(
            'Bu Ay',
            EventPeriod.month,
          ),
        ),
      ],
    );
  }

  Widget _periodButton(
    String label,
    EventPeriod period,
  ) {
    final selected =
        _selectedPeriod ==
            period;

    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: selected
            ? null
            : () =>
                _selectPeriod(
                  period,
                ),
        style:
            OutlinedButton.styleFrom(
          backgroundColor:
              selected
                  ? Colors.black
                  : Colors.white,
          foregroundColor:
              selected
                  ? Colors.white
                  : Colors.black,
          disabledForegroundColor:
              Colors.white,
          side:
              BorderSide(
            color: selected
                ? Colors.black
                : Colors.grey.shade300,
          ),
          padding:
              EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),
        ),
        child:
            Text(
          label,
          style:
              const TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildEventSearch() {
    return TextField(
      controller:
          _eventSearchController,
      textInputAction:
          TextInputAction.search,
      decoration:
          InputDecoration(
        hintText:
            'Bu ay etkinliklerde ara...',
        prefixIcon:
            const Icon(
          Icons.search,
        ),
        suffixIcon:
            _eventSearch.isNotEmpty
                ? IconButton(
                    onPressed:
                        _eventSearchController
                            .clear,
                    icon:
                        const Icon(
                      Icons.clear,
                    ),
                  )
                : null,
        filled: true,
        fillColor:
            Colors.white,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          borderSide:
              BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildEventCard(
    Event event,
  ) {
    final local =
        event.startsAt.toLocal();

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

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        onTap:
            () => _openEvent(
          event,
        ),
        child:
            Padding(
          padding:
              const EdgeInsets.all(
            14,
          ),
          child:
              Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.black,
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child:
                    Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Text(
                      '$day.$month',
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            13,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      '$hour:$minute',
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                        fontSize:
                            10,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
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
                      event.title,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        fontSize:
                            14,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      [
                        event.category,
                        if (event
                                .venueName !=
                            null)
                          event.venueName!,
                      ].join(' · '),
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          TextStyle(
                        fontSize:
                            10,
                        color:
                            Colors.grey
                                .shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacesSection() {
    if (_placesLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_placesError != null ||
        _places.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'KEŞFEDİLECEK YERLER',
          style:
              TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        SizedBox(
          height: 145,
          child: ListView.separated(
            scrollDirection:
                Axis.horizontal,
            itemCount:
                _places.length > 6
                    ? 6
                    : _places.length,
            separatorBuilder:
                (_, __) =>
                    const SizedBox(
              width: 10,
            ),
            itemBuilder:
                (context, index) {
              final place =
                  _places[index];

              return SizedBox(
                width: 205,
                child:
                    _buildPlaceCard(
                  place,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceCard(
    Place place,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      onTap:
          () => _openPlace(
        place,
      ),
      child:
          Container(
        padding:
            const EdgeInsets.all(
          14,
        ),
        decoration:
            BoxDecoration(
          color:
              Colors.white,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          border:
              Border.all(
            color:
                Colors.grey.shade200,
          ),
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.place_outlined,
              size: 26,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              place.name,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              place.category,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  TextStyle(
                fontSize: 10,
                color:
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child:
          OutlinedButton.icon(
        onPressed: () =>
            setState(() {
          _selectedIndex = 1;
        }),
        icon:
            const Icon(
          Icons.map_outlined,
        ),
        label:
            const Text(
          'Haritada keşfet',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              Colors.black,
          backgroundColor:
              Colors.white,
          side:
              BorderSide(
            color:
                Colors.grey.shade300,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              17,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(
    String text,
  ) {
    return Container(
      width: double.infinity,
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
          18,
        ),
        border:
            Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child:
          Text(
        text,
        style:
            const TextStyle(
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}
