part of 'recommendation_screen.dart';

extension _RecommendationCardMethods on _RecommendationScreenState {
  Widget _buildResultCard(
    _Activity activity,
  ) {
    final queued =
        _isQueued(activity);

    final isEvent =
        activity.type ==
            _ActivityType.event;

    final distance =
        _distanceFromUser(
      _activityLatitude(
        activity,
      ),
      _activityLongitude(
        activity,
      ),
    );

    final distanceText =
        _distanceLabel(
      distance,
    );

    final placeName =
        activity.event?.venueName ??
            activity.place?.address;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom:
            16,
      ),
      clipBehavior:
          Clip.antiAlias,
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
              queued
                  ? Colors.black
                  : Colors.grey
                      .shade200,
          width:
              queued
                  ? 1.4
                  : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color:
                Color(0x08000000),
            blurRadius:
                14,
            offset:
                Offset(0, 5),
          ),
        ],
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Stack(
            children: [
              _buildCardImage(
                activity,
              ),
              Positioned(
                left:
                    12,
                top:
                    12,
                child:
                    Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        10,
                    vertical:
                        7,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.black87,
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),
                  child:
                      Text(
                    isEvent
                        ? 'ETKİNLİK'
                        : 'KEŞİF',
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          9,
                      fontWeight:
                          FontWeight
                              .w900,
                      letterSpacing:
                          0.8,
                    ),
                  ),
                ),
              ),
              if (queued)
                Positioned(
                  right:
                      12,
                  top:
                      12,
                  child:
                      Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal:
                          10,
                      vertical:
                          7,
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
                        const Row(
                      mainAxisSize:
                          MainAxisSize
                              .min,
                      children: [
                        Icon(
                          Icons.check,
                          size:
                              14,
                        ),
                        SizedBox(
                          width:
                              4,
                        ),
                        Text(
                          'KUYRUKTA',
                          style:
                              TextStyle(
                            fontSize:
                                9,
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding:
                const EdgeInsets
                    .all(
              15,
            ),
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  activity.event?.title ??
                      activity.place?.name ??
                      '',
                  maxLines:
                      2,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight
                            .w900,
                    height:
                        1.15,
                  ),
                ),
                const SizedBox(
                  height:
                      8,
                ),
                Wrap(
                  spacing:
                      6,
                  runSpacing:
                      6,
                  children: [
                    _InfoPill(
                      icon:
                          isEvent
                              ? Icons
                                  .schedule_outlined
                              : Icons
                                  .timelapse_outlined,
                      text:
                          isEvent
                              ? _dateLabel(
                                  activity
                                      .event!
                                      .startsAt,
                                )
                              : _durationLabel(
                                  activity
                                      .durationMinutes,
                                ),
                    ),
                    if (distanceText
                        .isNotEmpty)
                      _InfoPill(
                        icon:
                            Icons
                                .near_me_outlined,
                        text:
                            distanceText,
                      ),
                  ],
                ),
                if (isEvent) ...[
                  const SizedBox(
                    height:
                        8,
                  ),
                  Wrap(
                    spacing:
                        6,
                    runSpacing:
                        6,
                    children: [
                      if (_priceLabel(
                        activity.event!,
                      ).isNotEmpty)
                        _InfoPill(
                          icon:
                              Icons
                                  .payments_outlined,
                          text:
                              _priceLabel(
                            activity
                                .event!,
                          ),
                        ),
                      if (activity
                          .event!
                          .category
                          .trim()
                          .isNotEmpty)
                        _InfoPill(
                          icon:
                              Icons
                                  .category_outlined,
                          text:
                              activity
                                  .event!
                                  .category,
                        ),
                    ],
                  ),
                ] else if (activity.place != null) ...[
                  const SizedBox(
                    height:
                        8,
                  ),
                  Wrap(
                    spacing:
                        6,
                    runSpacing:
                        6,
                    children: [
                      if (activity
                              .place!
                              .isFree ==
                          true)
                        const _InfoPill(
                          icon:
                              Icons
                                  .local_offer_outlined,
                          text:
                              'Ücretsiz',
                        ),
                      if (activity
                          .place!
                          .category
                          .trim()
                          .isNotEmpty)
                        _InfoPill(
                          icon:
                              Icons
                                  .category_outlined,
                          text:
                              activity
                                  .place!
                                  .category,
                        ),
                    ],
                  ),
                ],
                if (placeName !=
                        null &&
                    placeName
                        .trim()
                        .isNotEmpty) ...[
                  const SizedBox(
                    height:
                        9,
                  ),
                  Text(
                    placeName,
                    maxLines:
                        2,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        TextStyle(
                      fontSize:
                          11,
                      color:
                          Colors
                              .grey
                              .shade600,
                    ),
                  ),
                ],
                const SizedBox(
                  height:
                      14,
                ),
                Row(
                  children: [
                    Expanded(
                      child:
                          OutlinedButton(
                        onPressed:
                            () =>
                                _toggleQueue(
                          activity,
                        ),
                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              Colors.black,
                          minimumSize:
                              const Size(
                            0,
                            44,
                          ),
                          side:
                              BorderSide(
                            color:
                                queued
                                    ? Colors.black
                                    : Colors.grey
                                        .shade300,
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
                        child:
                            Text(
                          queued
                              ? 'Kuyruktan çıkar'
                              : 'Kuyruğa ekle',
                          style:
                              const TextStyle(
                            fontSize:
                                11,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width:
                          8,
                    ),
                    Expanded(
                      child:
                          isEvent &&
                                  activity
                                          .event!
                                          .ticketUrl !=
                                      null &&
                                  activity
                                      .event!
                                      .ticketUrl!
                                      .trim()
                                      .isNotEmpty
                              ? FilledButton.icon(
                                  onPressed:
                                      () =>
                                          _openTicket(
                                    activity
                                        .event!,
                                  ),
                                  icon:
                                      const Icon(
                                    Icons
                                        .confirmation_number_outlined,
                                    size:
                                        17,
                                  ),
                                  label:
                                      const Text(
                                    'BİLET AL',
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
                                      44,
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
                                )
                              : FilledButton(
                                  onPressed:
                                      () =>
                                          _openActivity(
                                    activity,
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
                                      44,
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
                                  child:
                                      const Text(
                                    'DETAY',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          10,
                                      fontWeight:
                                          FontWeight
                                              .w900,
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
