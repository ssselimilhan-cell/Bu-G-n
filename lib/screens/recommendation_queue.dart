part of 'recommendation_screen.dart';

extension _RecommendationQueueMethods on _RecommendationScreenState {
  bool _isQueued(
    _Activity activity,
  ) {
    return _queue.any(
      (item) => item.id == activity.id,
    );
  }

  void _toggleQueue(
    _Activity activity,
  ) {
    setState(() {
      final index =
          _queue.indexWhere(
        (item) =>
            item.id == activity.id,
      );

      if (index >= 0) {
        _queue.removeAt(index);
      } else {
        _queue.add(activity);
      }
    });
  }

  double? _activityLatitude(
    _Activity activity,
  ) {
    return activity.event?.latitude ??
        activity.place?.latitude;
  }

  double? _activityLongitude(
    _Activity activity,
  ) {
    return activity.event?.longitude ??
        activity.place?.longitude;
  }

  Future<void> _openTicket(
    Event event,
  ) async {
    final url =
        event.ticketUrl;

    if (url == null ||
        url.trim().isEmpty) {
      _showMessage(
        'Bu etkinlik için bilet bağlantısı bulunmuyor.',
      );
      return;
    }

    try {
      final uri =
          Uri.tryParse(url);

      if (uri == null) {
        _showMessage(
          'Bilet bağlantısı geçersiz.',
        );
        return;
      }

      final opened =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!opened) {
        _showMessage(
          'Bilet sayfası açılamadı.',
        );
      }
    } catch (_) {
      _showMessage(
        'Bilet sayfası açılamadı.',
      );
    }
  }

  Future<void> _buildRoute() async {
    final navigable =
        _queue
            .where(
              (activity) =>
                  _activityLatitude(
                    activity,
                  ) !=
                      null &&
                  _activityLongitude(
                    activity,
                  ) !=
                      null,
            )
            .toList();

    if (navigable.isEmpty) {
      _showMessage(
        'Seçtiğin seçeneklerde kullanılabilir konum bilgisi yok.',
      );
      return;
    }

    final destination =
        '${_activityLatitude(navigable.last)},'
        '${_activityLongitude(navigable.last)}';

    // Include the first selected stop as the origin, not just as a waypoint.
    final parameters = <String, String>{
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    };

    if (navigable.length > 1) {
      parameters['origin'] =
          '${_activityLatitude(navigable.first)},'
          '${_activityLongitude(navigable.first)}';
    }

    final waypoints = navigable.length > 2
        ? navigable
            .sublist(1, navigable.length - 1)
            .map(
              (item) =>
                  '${_activityLatitude(item)},'
                  '${_activityLongitude(item)}',
            )
            .join('|')
        : null;

    if (waypoints != null && waypoints.isNotEmpty) {
      parameters['waypoints'] = waypoints;
    }

    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      parameters,
    );

    try {
      final opened =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!opened) {
        _showMessage(
          'Harita açılamadı.',
        );
      }
    } catch (_) {
      _showMessage(
        'Rota açılamadı.',
      );
    }
  }

  void _openActivity(
    _Activity activity,
  ) {
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
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }


  Widget _buildQueueBar() {
    if (_queue.isEmpty) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child:
          Container(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          10,
        ),
        decoration:
            const BoxDecoration(
          color:
              Colors.white,
          boxShadow: [
            BoxShadow(
              color:
                  Color(0x16000000),
              blurRadius:
                  15,
              offset:
                  Offset(0, -5),
            ),
          ],
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
                  Text(
                    '${_queue.length} aktivite seçildi',
                    style:
                        const TextStyle(
                      fontSize:
                          13,
                      fontWeight:
                          FontWeight
                              .w900,
                    ),
                  ),
                  const SizedBox(
                    height:
                        3,
                  ),
                  Text(
                    '${_queue.where((item) => _activityLatitude(item) != null && _activityLongitude(item) != null).length} konum rotaya eklenecek',
                    maxLines:
                        1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        TextStyle(
                      fontSize:
                          10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width:
                  10,
            ),
            FilledButton.icon(
              onPressed:
                  _buildRoute,
              icon:
                  const Icon(
                Icons.route,
                size:
                    18,
              ),
              label:
                  const Text(
                'ROTAYI AÇ',
                style:
                    TextStyle(
                  fontSize:
                      10,
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
                minimumSize:
                    const Size(
                  0,
                  45,
                ),
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal:
                      14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}
