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
    if (mounted) {
      setState(() {
        _eventsLoading = true;
        _eventsError = null;
        _selectedPeriod = period;
      });
    }

    try {
      late final List<Event> events;

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

  void _openExplore() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _openSaved() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  void _openProfile() {
    setState(() {
      _selectedIndex = 3;
    });
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
                  height: 24,
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
                  height: 4,
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
                  size: 23,
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
            height: 18,
          ),
          GestureDetector(
            onTap:
                _openExplore,
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
                    BorderRadius
                        .circular(
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
                    color:
                        Colors.white,
                    size:
                        16,
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
        bottom: 24,
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
              _categories
                  .length,
          separatorBuilder:
              (_, __) =>
                  const SizedBox(
            width: 12,
          ),
          itemBuilder:
              (context, index) {
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
                    color: Colors
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
                      textAlign:
                          TextAlign
                              .center,
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
        _periodTitle();

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
          _buildPeriodSelector(),
          const SizedBox(
            height:
                12,
          ),
          _buildEventContent(),
        ],
      ),
    );
  }

  String _periodTitle() {
    switch (
        _selectedPeriod) {
      case EventPeriod.today:
        return 'BUGÜN ANKARA’DA';

      case EventPeriod.week:
        return 'BU HAFTA ANKARA’DA';

      case EventPeriod.month:
        return 'BU AY ANKARA’DA';
    }
  }

  Widget _buildPeriodSelector() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.only(
          right: 20,
        ),
        children: [
          _PeriodChip(
            label: 'Bugün',
            selected:
                _selectedPeriod ==
                    EventPeriod.today,
            onTap: () =>
                _reloadEventsForPeriod(
              EventPeriod.today,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          _PeriodChip(
            label: 'Bu Hafta',
            selected:
                _selectedPeriod ==
                    EventPeriod.week,
            onTap: () =>
                _reloadEventsForPeriod(
              EventPeriod.week,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          _PeriodChip(
            label: 'Bu Ay',
            selected:
                _selectedPeriod ==
                    EventPeriod.month,
            onTap: () =>
                _reloadEventsForPeriod(
              EventPeriod.month,
            ),
          ),
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
          padding:
              const EdgeInsets
                  .only(
            right:
                20,
          ),
          scrollDirection:
              Axis.horizontal,
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
            const EdgeInsets.only(
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
            Row(
          children: [
            const Icon(
              Icons
                  .error_outline,
            ),
            const SizedBox(
              width:
                  12,
            ),
            Expanded(
              child:
                  Text(
                _eventsError!,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),
            ),
            IconButton(
              onPressed:
                  () =>
                      _reloadEventsForPeriod(
                _selectedPeriod,
              ),
              icon:
                  const Icon(
                Icons
                    .refresh,
              ),
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return Container(
        margin:
            const EdgeInsets.only(
          right:
              20,
        ),
        width:
            double.infinity,
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
          border:
              Border.all(
            color: Colors
                .grey
                .shade200,
          ),
        ),
        child:
            Row(
          children: [
            const Icon(
              Icons
                  .event_available_outlined,
              size:
                  28,
            ),
            const SizedBox(
              width:
                  12,
            ),
            Expanded(
              child:
                  Text(
                _emptyEventText(),
                style:
                    const TextStyle(
                  fontSize:
                      13,
                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height:
          190,
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
            _events.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width:
              12,
        ),
        itemBuilder:
            (context, index) {
          final event =
              _events[
                  index];

          return _HomeEventCard(
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

  String _emptyEventText() {
    switch (
        _selectedPeriod) {
      case EventPeriod.today:
        return 'Bugün için henüz devam eden veya başlayacak etkinlik bulunmuyor.';

      case EventPeriod.week:
        return 'Bu hafta için henüz başlayacak etkinlik bulunmuyor.';

      case EventPeriod.month:
        return 'Bu ay için henüz başlayacak etkinlik bulunmuyor.';
    }
  }

  Widget _buildPlacesSection() {
    if (_placesLoading) {
      return Padding(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          20,
          0,
          0,
        ),
        child:
            SizedBox(
          height:
              155,
          child:
              ListView
                  .separated(
            scrollDirection:
                Axis.horizontal,
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
                    const _LoadingPlaceCard(),
          ),
        ),
      );
    }

    if (_placesError != null ||
        _places.isEmpty) {
      return const SizedBox
          .shrink();
    }

    final places =
        _places.take(6).toList();

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        20,
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
                  places.length,
              separatorBuilder:
                  (_, __) =>
                      const SizedBox(
                width:
                    12,
              ),
              itemBuilder:
                  (context, index) {
                final place =
                    places[
                        index];

                return _SmallPlaceCard(
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
                Icons
                    .map_outlined,
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
                            FontWeight
                                .w700,
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
                  FontWeight
                      .w800,
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
                    FontWeight
                        .w700,
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
          selected
              ? null
              : onTap,
      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds:
              180,
        ),
        padding:
            const EdgeInsets
                .symmetric(
          horizontal:
              16,
          vertical:
              9,
        ),
        decoration:
            BoxDecoration(
          color: selected
              ? Colors.black
              : Colors.white,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          border:
              Border.all(
            color: selected
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
            fontSize:
                12,
            fontWeight:
                FontWeight
                    .w700,
            color: selected
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _HomeEventCard
    extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _HomeEventCard({
    required this.event,
    required this.onTap,
  });

  IconData _icon() {
    final category =
        event.category.toLowerCase();

    if (category.contains(
          'music',
        ) ||
        category.contains(
          'müzik',
        )) {
      return Icons
          .music_note_outlined;
    }

    if (category.contains(
          'sports',
        ) ||
        category.contains(
          'spor',
        )) {
      return Icons
          .sports_outlined;
    }

    if (category.contains(
          'theatre',
        ) ||
        category.contains(
          'tiyatro',
        )) {
      return Icons
          .theater_comedy_outlined;
    }

    return Icons
        .event_outlined;
  }

  String _time() {
    return DateFormat(
      'd MMM · HH:mm',
      'tr_TR',
    ).format(
      event.startsAt
          .toLocal(),
    );
  }

  String _price() {
    final min =
        event.priceMin;

    final max =
        event.priceMax;

    if (min == null &&
        max == null) {
      return '';
    }

    if (min == 0 &&
        (max == null ||
            max == 0)) {
      return 'Ücretsiz';
    }

    if (min != null &&
        max != null &&
        min != max) {
      return '${min.round()}-${max.round()} TL';
    }

    final price =
        min ?? max;

    if (price == null) {
      return '';
    }

    return '${price.round()} TL';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final price =
        _price();

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
              color: Colors
                  .grey
                  .shade200,
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
                        ? Container(
                            color:
                                Colors.grey.shade100,
                            child:
                                Center(
                              child:
                                  Icon(
                                _icon(),
                                size:
                                    34,
                              ),
                            ),
                          )
                        : Image.network(
                            event.imageUrl!,
                            fit:
                                BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) {
                              return Container(
                                color:
                                    Colors.grey.shade100,
                                child:
                                    Center(
                                  child:
                                      Icon(
                                    _icon(),
                                    size:
                                        34,
                                  ),
                                ),
                              );
                            },
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
                      Row(
                        children: [
                          Expanded(
                            child:
                                Text(
                              event.category
                                  .toUpperCase(),
                              maxLines:
                                  1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
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
                          ),
                          Text(
                            _time(),
                            style:
                                const TextStyle(
                              fontSize:
                                  11,
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                        ],
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
                          height:
                              1.1,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          if (event.venueName !=
                                  null &&
                              event.venueName!
                                  .trim()
                                  .isNotEmpty) ...[
                            const Icon(
                              Icons
                                  .location_on_outlined,
                              size:
                                  14,
                            ),
                            const SizedBox(
                              width:
                                  4,
                            ),
                            Expanded(
                              child:
                                  Text(
                                event.venueName!,
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
                          ] else
                            const Spacer(),
                          if (price.isNotEmpty)
                            Text(
                              price,
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
        border:
            Border.all(
          color: Colors
              .grey
              .shade200,
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

class _LoadingPlaceCard
    extends StatelessWidget {
  const _LoadingPlaceCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          190,
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
          color: Colors
              .grey
              .shade200,
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

class _SmallPlaceCard
    extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _SmallPlaceCard({
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
              const EdgeInsets.all(
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
              color: Colors
                  .grey
                  .shade200,
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
                  Container(
                    padding:
                        const EdgeInsets
                            .all(
                      8,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors
                          .grey
                          .shade100,
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                    child:
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
                          20,
                    ),
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
                    TextOverflow.ellipsis,
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
                place.placeType ??
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

class _AllEventsScreen
    extends StatefulWidget {
  const _AllEventsScreen();

  @override
  State<_AllEventsScreen>
      createState() =>
          _AllEventsScreenState();
}

class _AllEventsScreenState
    extends State<_AllEventsScreen> {
  final EventService
      _eventService =
      EventService();

  List<Event> _events =
      [];

  bool _loading =
      true;

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
        _events =
            events;
        _loading =
            false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading =
            false;
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
      appBar:
          AppBar(
        backgroundColor:
            const Color(
                0xFFF7F7F5),
        surfaceTintColor:
            Colors
                .transparent,
        elevation:
            0,
        title:
            const Text(
          'Ankara Etkinlikleri',
          style:
              TextStyle(
            fontWeight:
                FontWeight
                    .w800,
          ),
        ),
      ),
      body:
          _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child:
            FilledButton(
          onPressed:
              _loadEvents,
          child:
              const Text(
            'Tekrar dene',
          ),
        ),
      );
    }

    if (_events.isEmpty) {
      return const Center(
        child:
            Padding(
          padding:
              EdgeInsets.all(
            24,
          ),
          child:
              Text(
            'Önümüzdeki günlerde Ankara için başlayacak etkinlik bulunamadı.',
            textAlign:
                TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
          _loadEvents,
      child:
          ListView
              .separated(
        padding:
            const EdgeInsets
                .fromLTRB(
          16,
          16,
          16,
          24,
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
            (context, index) {
          final event =
              _events[
                  index];

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
                  () =>
                      Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EventDetailScreen(
                    event:
                        event,
                  ),
                ),
              ),
              child:
                  Padding(
                padding:
                    const EdgeInsets
                        .all(
                  12,
                ),
                child:
                    Row(
                  children: [
                    Container(
                      width:
                          82,
                      height:
                          92,
                      clipBehavior:
                          Clip.antiAlias,
                      decoration:
                          BoxDecoration(
                        color: Colors
                            .grey
                            .shade100,
                        borderRadius:
                            BorderRadius
                                .circular(
                          15,
                        ),
                      ),
                      child:
                          event.imageUrl ==
                                      null ||
                                  event.imageUrl!
                                      .trim()
                                      .isEmpty
                              ? const Icon(
                                  Icons
                                      .event_outlined,
                                  size:
                                      30,
                                )
                              : Image.network(
                                  event.imageUrl!,
                                  fit:
                                      BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) {
                                    return const Icon(
                                      Icons
                                          .event_outlined,
                                      size:
                                          30,
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(
                      width:
                          13,
                    ),
                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            DateFormat(
                              'd MMM · HH:mm',
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
                          const SizedBox(
                            height:
                                5,
                          ),
                          Text(
                            event.title,
                            maxLines:
                                3,
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
                          if (event
                                  .venueName !=
                              null) ...[
                            const SizedBox(
                              height:
                                  6,
                            ),
                            Text(
                              event.venueName!,
                              maxLines:
                                  1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
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
                        ],
                      ),
                    ),
                    const Icon(
                      Icons
                          .chevron_right,
                      color:
                          Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
