import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final PlaceService _placeService =
      PlaceService();

  final EventService _eventService =
      EventService();

  List<Place> _places = [];
  List<Event> _events = [];

  bool _placesLoading = true;
  bool _eventsLoading = true;

  String? _placesError;
  String? _eventsError;

  int _selectedIndex = 0;

  EventPeriod _selectedPeriod =
      EventPeriod.today;

  final List<Map<String, dynamic>>
      _categories = const [
    {
      'title': 'Doğa',
      'icon': Icons.park_outlined,
    },
    {
      'title': 'Park',
      'icon': Icons.grass_outlined,
    },
    {
      'title': 'Tarih',
      'icon':
          Icons.account_balance_outlined,
    },
    {
      'title': 'Müze',
      'icon':
          Icons.museum_outlined,
    },
    {
      'title': 'Kültür',
      'icon':
          Icons.theater_comedy_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    await Future.wait([
      _loadPlaces(),
      _loadEvents(),
    ]);
  }

  Future<void> _loadPlaces() async {
    if (mounted) {
      setState(() {
        _placesLoading = true;
        _placesError = null;
      });
    }

    try {
      final places =
          await _placeService.getPlaces(
        city: 'Ankara',
        limit: 50,
      );

      if (!mounted) return;

      setState(() {
        _places = places;
        _placesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _placesLoading = false;
        _placesError =
            'Yerler yüklenemedi.';
      });
    }
  }

  Future<void> _loadEvents() async {
    if (mounted) {
      setState(() {
        _eventsLoading = true;
        _eventsError = null;
      });
    }

    try {
      final events =
          await _eventService
              .getUpcomingEvents(
        city: 'Ankara',
        days: 31,
        limit: 200,
      );

      if (!mounted) return;

      setState(() {
        _events = events;
        _eventsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _eventsLoading = false;
        _eventsError =
            'Etkinlikler yüklenemedi.';
      });
    }
  }

  Future<void> _reloadEventsForPeriod(
    EventPeriod period,
  ) async {
    setState(() {
      _selectedPeriod = period;
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

      if (!mounted) return;

      setState(() {
        _events = events;
        _eventsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _eventsLoading = false;
        _eventsError =
            'Etkinlikler yüklenemedi.';
      });
    }
  }

  Future<void> _refreshHome() async {
    await Future.wait([
      _loadPlaces(),
      _loadEvents(),
    ]);
  }

  void _openRecommendation() {
    Navigator.push(
      context,
      MaterialPageRoute(
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
      MaterialPageRoute(
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
      MaterialPageRoute(
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
      MaterialPageRoute(
        builder: (_) =>
            PlaceDetailScreen(
          place: place,
        ),
      ),
    );
  }

  void _openExplore() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _openProfile() {
    setState(() {
      _selectedIndex = 3;
    });
  }

  void _openAllEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const _AllEventsScreen(),
      ),
    );
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
        if (didPop) return;

        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child:
          _buildCurrentPage(),
    );
  }

  Widget _buildCurrentPage() {
    if (_selectedIndex == 1) {
      return const ExploreScreen();
    }

    if (_selectedIndex == 2) {
      return const SavedScreen();
    }

    if (_selectedIndex == 3) {
      return const ProfileScreen();
    }

    return _buildHomePage();
  }

  Widget _buildHomePage() {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F5),
      body: SafeArea(
        child:
            RefreshIndicator(
          onRefresh:
              _refreshHome,
          child:
              CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child:
                    _buildHeader(),
              ),
              SliverToBoxAdapter(
                child:
                    _buildMainQuestion(),
              ),
              SliverToBoxAdapter(
                child:
                    _buildCategories(),
              ),
              SliverToBoxAdapter(
                child:
                    _buildEventsSection(),
              ),
              SliverToBoxAdapter(
                child:
                    _buildPlacesSection(),
              ),
              SliverToBoxAdapter(
                child:
                    _buildMapButton(),
              ),
              const SliverToBoxAdapter(
                child:
                    SizedBox(
                  height:
                      24,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            _selectedIndex,
        onDestinationSelected:
            (index) {
          setState(() {
            _selectedIndex =
                index;
          });
        },
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

  Widget _buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        8,
      ),
      child:
          Row(
        children: [
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'BUGÜN',
                  style:
                      TextStyle(
                    fontSize:
                        28,
                    fontWeight:
                        FontWeight
                            .w800,
                    letterSpacing:
                        -0.8,
                  ),
                ),
                const SizedBox(
                  height:
                      4,
                ),
                Text(
                  'Ankara',
                  style:
                      TextStyle(
                    fontSize:
                        15,
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color:
                Colors.white,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            child:
                InkWell(
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              onTap:
                  _openProfile,
              child:
                  const Padding(
                padding:
                    EdgeInsets.all(
                  11,
                ),
                child:
                    Icon(
                  Icons
                      .person_outline,
                  size:
                      23,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainQuestion() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        22,
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          const Text(
            'Bugün Ankara’da\nne yapmak istersin?',
            style:
                TextStyle(
              fontSize:
                  31,
              fontWeight:
                  FontWeight
                      .w800,
              height:
                  1.06,
              letterSpacing:
                  -1,
            ),
          ),
          const SizedBox(
            height:
                18,
          ),
          GestureDetector(
            onTap:
                _openRecommendation,
            child:
                Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal:
                    18,
                vertical:
                    17,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.black,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child:
                  const Row(
                children: [
                  Icon(
                    Icons
                        .auto_awesome,
                    color:
                        Colors.white,
                  ),
                  SizedBox(
                    width:
                        12,
                  ),
                  Expanded(
                    child:
                        Text(
                      'Bugün ne yapayım?',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            16,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons
                        .arrow_forward_ios,
                    size:
                        16,
                    color:
                        Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom:
            24,
      ),
      child:
          SizedBox(
        height:
            98,
        child:
            ListView
                .separated(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                20,
          ),
          scrollDirection:
              Axis.horizontal,
          itemCount:
              _categories.length,
          separatorBuilder:
              (_, __) =>
                  const SizedBox(
            width:
                12,
          ),
          itemBuilder:
              (context,
                  index) {
            final category =
                _categories[
                    index];

            return GestureDetector(
              onTap:
                  () =>
                      _openCategory(
                category[
                        'title']
                    as String,
              ),
              child:
                  Container(
                width:
                    92,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal:
                      10,
                  vertical:
                      12,
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
                  border:
                      Border.all(
                    color:
                        Colors
                            .grey
                            .shade200,
                  ),
                ),
                child:
                    Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      category[
                              'icon']
                          as IconData,
                      size:
                          25,
                    ),
                    const SizedBox(
                      height:
                          8,
                    ),
                    Text(
                      category[
                              'title']
                          as String,
                      style:
                          const TextStyle(
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        0,
        0,
        8,
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Padding(
            padding:
                const EdgeInsets
                    .only(
              right:
                  20,
            ),
            child:
                _sectionTitle(
              title,
              onTap:
                  _openAllEvents,
            ),
          ),
          const SizedBox(
            height:
                12,
          ),
          SizedBox(
            height:
                40,
            child:
                ListView(
              scrollDirection:
                  Axis.horizontal,
              padding:
                  const EdgeInsets
                      .only(
                right:
                    20,
              ),
              children: [
                _PeriodChip(
                  label:
                      'Bugün',
                  selected:
                      _selectedPeriod ==
                          EventPeriod
                              .today,
                  onTap: () =>
                      _reloadEventsForPeriod(
                    EventPeriod
                        .today,
                  ),
                ),
                const SizedBox(
                  width:
                      8,
                ),
                _PeriodChip(
                  label:
                      'Bu Hafta',
                  selected:
                      _selectedPeriod ==
                          EventPeriod
                              .week,
                  onTap: () =>
                      _reloadEventsForPeriod(
                    EventPeriod
                        .week,
                  ),
                ),
                const SizedBox(
                  width:
                      8,
                ),
                _PeriodChip(
                  label:
                      'Bu Ay',
                  selected:
                      _selectedPeriod ==
                          EventPeriod
                              .month,
                  onTap: () =>
                      _reloadEventsForPeriod(
                    EventPeriod
                        .month,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height:
                12,
          ),
          _buildEventContent(),
        ],
      ),
    );
  }

  Widget _buildEventContent() {
    if (_eventsLoading) {
      return SizedBox(
        height:
            190,
        child:
            ListView
                .separated(
          scrollDirection:
              Axis.horizontal,
          padding:
              const EdgeInsets
                  .only(
            right:
                20,
          ),
          itemCount:
              2,
          separatorBuilder:
              (_, __) =>
                  const SizedBox(
            width:
                12,
          ),
          itemBuilder:
              (_, __) =>
                  const _LoadingEventCard(),
        ),
      );
    }

    if (_eventsError != null) {
      return Container(
        margin:
            const EdgeInsets
                .only(
          right:
              20,
        ),
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
            Text(
          _eventsError!,
        ),
      );
    }

    if (_events.isEmpty) {
      return Container(
        margin:
            const EdgeInsets
                .only(
          right:
              20,
        ),
        padding:
            const EdgeInsets.all(
          20,
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
            const Text(
          'Bu zaman aralığında başlayacak etkinlik bulunmuyor.',
        ),
      );
    }

    return SizedBox(
      height:
          190,
      child:
          ListView.separated(
        padding:
            const EdgeInsets
                .only(
          right:
              20,
        ),
        scrollDirection:
            Axis.horizontal,
        itemCount:
            _events.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width:
              12,
        ),
        itemBuilder:
            (context,
                index) {
          final event =
              _events[index];

          return _EventCard(
            event:
                event,
            onTap:
                () =>
                    _openEvent(
              event,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlacesSection() {
    if (_placesLoading) {
      return const SizedBox(
        height:
            180,
        child:
            Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_placesError != null ||
        _places.isEmpty) {
      return const SizedBox
          .shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        24,
        0,
        0,
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Padding(
            padding:
                const EdgeInsets
                    .only(
              right:
                  20,
            ),
            child:
                _sectionTitle(
              'KEŞFEDİLECEK YERLER',
              onTap:
                  _openExplore,
            ),
          ),
          const SizedBox(
            height:
                12,
          ),
          SizedBox(
            height:
                155,
            child:
                ListView
                    .separated(
              padding:
                  const EdgeInsets
                      .only(
                right:
                    20,
              ),
              scrollDirection:
                  Axis.horizontal,
              itemCount:
                  _places.length > 6
                      ? 6
                      : _places.length,
              separatorBuilder:
                  (_, __) =>
                      const SizedBox(
                width:
                    12,
              ),
              itemBuilder:
                  (context,
                      index) {
                final place =
                    _places[index];

                return _PlaceCard(
                  place:
                      place,
                  onTap:
                      () =>
                          _openPlace(
                    place,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        28,
        20,
        0,
      ),
      child:
          GestureDetector(
        onTap:
            _openExplore,
        child:
            Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                18,
            vertical:
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
            border:
                Border.all(
              color:
                  Colors.grey.shade200,
            ),
          ),
          child:
              const Row(
            children: [
              Icon(
                Icons.map_outlined,
              ),
              SizedBox(
                width:
                    12,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Haritada keşfet',
                      style:
                          TextStyle(
                        fontSize:
                            15,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    SizedBox(
                      height:
                          3,
                    ),
                    Text(
                      'Ankara’daki yerleri harita üzerinde gör',
                      style:
                          TextStyle(
                        fontSize:
                            12,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons
                    .arrow_forward_ios,
                size:
                    15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title, {
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child:
              Text(
            title,
            style:
                const TextStyle(
              fontSize:
                  13,
              fontWeight:
                  FontWeight.w800,
              letterSpacing:
                  0.8,
            ),
          ),
        ),
        if (onTap !=
            null)
          GestureDetector(
            onTap:
                onTap,
            child:
                const Text(
              'Tümü',
              style:
                  TextStyle(
                fontSize:
                    13,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _PeriodChip
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
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
          Container(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal:
              15,
          vertical:
              9,
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
                    : Colors
                        .grey
                        .shade300,
          ),
        ),
        child:
            Text(
          label,
          style:
              TextStyle(
            color:
                selected
                    ? Colors.white
                    : Colors.black,
            fontWeight:
                FontWeight.w700,
            fontSize:
                12,
          ),
        ),
      ),
    );
  }
}

class _EventCard
    extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.white,
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      child:
          InkWell(
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        onTap:
            onTap,
        child:
            Container(
          width:
              275,
          decoration:
              BoxDecoration(
            color:
                Colors.white,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border:
                Border.all(
              color:
                  Colors.grey.shade200,
            ),
          ),
          clipBehavior:
              Clip.antiAlias,
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              SizedBox(
                height:
                    84,
                width:
                    double.infinity,
                child:
                    event.imageUrl ==
                                null ||
                            event.imageUrl!
                                .trim()
                                .isEmpty
                        ? const Center(
                            child:
                                Icon(
                              Icons
                                  .event_outlined,
                              size:
                                  34,
                            ),
                          )
                        : Image.network(
                            event.imageUrl!,
                            fit:
                                BoxFit.cover,
                          ),
              ),
              Expanded(
                child:
                    Padding(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    14,
                    10,
                    14,
                    10,
                  ),
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        event.category
                            .toUpperCase(),
                        style:
                            TextStyle(
                          fontSize:
                              9,
                          fontWeight:
                              FontWeight
                                  .w900,
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                      const SizedBox(
                        height:
                            5,
                      ),
                      Text(
                        event.title,
                        maxLines:
                            2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize:
                              14,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child:
                                Text(
                              event.venueName ??
                                  '',
                              maxLines:
                                  1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  TextStyle(
                                fontSize:
                                    10,
                                color: Colors
                                    .grey
                                    .shade700,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat(
                              'HH:mm',
                              'tr_TR',
                            ).format(
                              event.startsAt
                                  .toLocal(),
                            ),
                            style:
                                const TextStyle(
                              fontSize:
                                  10,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceCard
    extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.white,
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      child:
          InkWell(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        onTap:
            onTap,
        child:
            Container(
          width:
              190,
          padding:
              const EdgeInsets
                  .all(
            15,
          ),
          decoration:
              BoxDecoration(
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
                CrossAxisAlignment
                    .start,
            children: [
              Row(
                children: [
                  Icon(
                    place.category ==
                            'Müze'
                        ? Icons
                            .museum_outlined
                        : place.outdoor ==
                                true
                            ? Icons
                                .park_outlined
                            : Icons
                                .place_outlined,
                    size:
                        24,
                  ),
                  const Spacer(),
                  if (place.isFree ==
                      true)
                    const Text(
                      'ÜCRETSİZ',
                      style:
                          TextStyle(
                        fontSize:
                            9,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(
                height:
                    14,
              ),
              Text(
                place.name,
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
              const Spacer(),
              Text(
                place.category,
                style:
                    TextStyle(
                  fontSize:
                      11,
                  color: Colors
                      .grey
                      .shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingEventCard
    extends StatelessWidget {
  const _LoadingEventCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          275,
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
          const Center(
        child:
            CircularProgressIndicator(),
      ),
    );
  }
}

class _AllEventsScreen
    extends StatefulWidget {
  const _AllEventsScreen();

  @override
  State<_AllEventsScreen> createState() =>
      _AllEventsScreenState();
}

class _AllEventsScreenState
    extends State<_AllEventsScreen> {
  final EventService _eventService =
      EventService();

  List<Event> _events = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final events =
          await _eventService
              .getUpcomingEvents(
        city: 'Ankara',
        days: 31,
        limit: 200,
      );

      if (!mounted) return;

      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'Etkinlikler yüklenemedi.';
      });
    }
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
          'Ankara Etkinlikleri',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
      body:
          _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : _error != null
                  ? Center(
                      child:
                          Text(
                        _error!,
                      ),
                    )
                  : ListView
                      .separated(
                      padding:
                          const EdgeInsets
                              .all(
                        16,
                      ),
                      itemCount:
                          _events.length,
                      separatorBuilder:
                          (_, __) =>
                              const SizedBox(
                        height:
                            12,
                      ),
                      itemBuilder:
                          (context,
                              index) {
                        final event =
                            _events[
                                index];

                        return Material(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                          child:
                              InkWell(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                            onTap:
                                () =>
                                    Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        EventDetailScreen(
                                  event:
                                      event,
                                ),
                              ),
                            ),
                            child:
                                ListTile(
                              title:
                                  Text(
                                event.title,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                              subtitle:
                                  Text(
                                DateFormat(
                                  'd MMM · HH:mm',
                                  'tr_TR',
                                ).format(
                                  event.startsAt
                                      .toLocal(),
                                ),
                              ),
                              trailing:
                                  const Icon(
                                Icons
                                    .chevron_right,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
