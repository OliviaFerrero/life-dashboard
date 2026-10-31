import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/time/app_clock.dart';
import '../core/time/civil_date.dart';

import '../models/life_task.dart';
import '../models/task_occurrence.dart';
import '../models/task_subtask.dart';

/// Timeline editoriale compatta della giornata.
///
/// La posizione verticale NON usa una scala continua minuto -> pixel:
/// gli intervalli liberi restano compatti e leggibili, mentre la durata
/// delle attività è rappresentata soprattutto dalla capsula verticale.
///
/// I confini della giornata sono comunque espliciti e arrivano da Oggi,
/// così in futuro potranno diventare una giornata personale configurabile.
class TaskTimeline extends StatefulWidget {
  final List<TaskOccurrence> occurrences;

  final DateTime windowStart;
  final DateTime windowEnd;

  final String Function(
    TaskOccurrence occurrence,
    DateTime windowStart,
    DateTime windowEnd,
  )
  secondaryLabelBuilder;

  final String? Function(LifeTask task) subtaskProgressBuilder;

  final Color Function(LifeTask task) accentColorBuilder;

  final Color Function(LifeTask task) priorityColorBuilder;

  final IconData Function(LifeTask task) categoryIconBuilder;

  final Future<void> Function(TaskOccurrence occurrence, bool completed)
  onCompletedChanged;

  final Future<void> Function(
    TaskOccurrence occurrence,
    TaskSubtask subtask,
    bool completed,
  )
  onSubtaskCompletedChanged;

  final void Function(TaskOccurrence occurrence) onTaskTap;

  final void Function(TaskOccurrence occurrence) onTaskLongPress;

  const TaskTimeline({
    super.key,
    required this.occurrences,
    required this.windowStart,
    required this.windowEnd,
    required this.secondaryLabelBuilder,
    required this.subtaskProgressBuilder,
    required this.accentColorBuilder,
    required this.priorityColorBuilder,
    required this.categoryIconBuilder,
    required this.onCompletedChanged,
    required this.onSubtaskCompletedChanged,
    required this.onTaskTap,
    required this.onTaskLongPress,
  });

  @override
  State<TaskTimeline> createState() => _TaskTimelineState();
}

class _TaskTimelineState extends State<TaskTimeline> {
  static const double _timeColumnWidth = 58;
  static const double _axisColumnWidth = 58;
  static const double _contentGap = 16;

  static const double _timelineTopInset = 8;
  static const double _timelineBottomInset = 10;
  static const double _boundaryHeight = 24;

  static const double _eventContentMinHeight = 56;

  // La larghezza della capsula è indipendente dalla sua altezza:
  // 44 px mantiene l'ovale presente ma più snello rispetto alla prima
  // iterazione del redesign, senza alterare la scala verticale della durata.
  static const double _capsuleWidth = 44;
  static const double _capsuleMinHeight = 38;
  static const double _capsuleBaseMinutes = 15;
  static const double _capsuleGrowthPerMinute = 1.20;

  // Oltre 2 ore la crescita continua, ma più lentamente per evitare
  // che task molto lunghe rendano Oggi eccessivamente alta.
  static const double _capsuleLongTaskThresholdMinutes = 120;
  static const double _capsuleLongTaskGrowthPerMinute = 0.45;
  static const double _capsuleMaxHeight = 220;

  // I vuoti restano compressi, ma non sono tutti alti uguali:
  // un intervallo di diverse ore deve essere percepito come sensibilmente
  // più ampio di un intervallo breve, senza tornare a una scala minuto/pixel.
  static const double _freeGapBaseHeight = 44;
  static const double _freeGapGrowthPerMinute = 0.30;
  static const double _freeGapMaxHeight = 150;
  static const double _smallFreeGapHeight = 28;
  static const double _tinyFreeGapHeight = 16;

  static const Color _nowColor = Color(0xFFE07A3F);

  DateTime get _now => AppClockScope.read(context).now;

  final GlobalKey _nowMarkerKey = GlobalKey();
  bool _didAutoScrollToNow = false;

  final Map<String, int> _overlapIndexByGroup = {};
  final Map<String, double> _overlapDragDxByGroup = {};
  final Map<String, bool> _overlapDraggingByGroup = {};
  final Map<String, int> _overlapTransitionDirectionByGroup = {};

  @override
  void didUpdateWidget(covariant TaskTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.windowStart != widget.windowStart ||
        oldWidget.windowEnd != widget.windowEnd) {
      _didAutoScrollToNow = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    AppClockScope.watch(context);

    final untimed = <TaskOccurrence>[];
    final timed = <_TimedOccurrence>[];

    for (final occurrence in widget.occurrences) {
      final task = occurrence.displayTask;

      if (task.allDay || task.startTimeMinutes == null) {
        untimed.add(occurrence);
        continue;
      }

      final visibleStart = occurrence.visibleStartInWindow(
        widget.windowStart,
        widget.windowEnd,
      );

      if (visibleStart == null) {
        continue;
      }

      final visibleEnd = occurrence.visibleEndInWindow(
        widget.windowStart,
        widget.windowEnd,
      );

      DateTime effectiveEnd;

      if (visibleEnd != null && visibleEnd.isAfter(visibleStart)) {
        effectiveEnd = visibleEnd;
      } else {
        final provisional = visibleStart.add(const Duration(minutes: 30));

        effectiveEnd = provisional.isAfter(widget.windowEnd)
            ? widget.windowEnd
            : provisional;
      }

      if (!effectiveEnd.isAfter(visibleStart)) {
        continue;
      }

      timed.add(
        _TimedOccurrence(
          occurrence: occurrence,
          start: visibleStart,
          end: effectiveEnd,
        ),
      );
    }

    untimed.sort(_compareUntimed);
    timed.sort((a, b) {
      final startCompare = a.start.compareTo(b.start);

      if (startCompare != 0) {
        return startCompare;
      }

      return a.end.compareTo(b.end);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (timed.isNotEmpty)
          _buildTimedTimeline(context, timed)
        else if (untimed.isNotEmpty)
          _NoTimedTasksMessage(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),

        if (untimed.isNotEmpty) ...[
          if (timed.isNotEmpty) const SizedBox(height: 30),
          _UntimedSection(
            occurrences: untimed,
            subtaskProgressBuilder: widget.subtaskProgressBuilder,
            accentColorBuilder: widget.accentColorBuilder,
            priorityColorBuilder: widget.priorityColorBuilder,
            onCompletedChanged: widget.onCompletedChanged,
            onTaskTap: widget.onTaskTap,
            onTaskLongPress: widget.onTaskLongPress,
          ),
        ],
      ],
    );
  }

  int _compareUntimed(TaskOccurrence a, TaskOccurrence b) {
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }

    return a.displayTask.title.toLowerCase().compareTo(
      b.displayTask.title.toLowerCase(),
    );
  }

  Widget _buildTimedTimeline(
    BuildContext context,
    List<_TimedOccurrence> timed,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final compressed = _buildCompressedLayout(timed);
    final liveCurrentOccurrenceKey = _findLiveCurrentOccurrenceKey(timed);
    final liveNextOccurrenceKey = _findLiveNextOccurrenceKey(timed);

    final visualGroups = _buildVisualGroups(
      compressed,
      liveCurrentOccurrenceKey,
      liveNextOccurrenceKey,
    );

    final visibleEvents = visualGroups
        .map((group) => group.selectedEvent)
        .toList();

    final axisCenterX = _timeColumnWidth + _axisColumnWidth / 2;

    final contentStart = _timeColumnWidth + _axisColumnWidth + _contentGap;

    final startMarkerCenterY = _timelineTopInset + _boundaryHeight / 2;

    final endMarkerCenterY = compressed.endBoundaryTop + _boundaryHeight / 2;

    final nowMarker = _buildNowMarker(compressed, liveCurrentOccurrenceKey);

    if (nowMarker != null) {
      _scheduleAutoScrollToNow();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math
            .max(0.0, constraints.maxWidth - contentStart)
            .toDouble();

        return SizedBox(
          height: compressed.totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: axisCenterX - 1,
                top: startMarkerCenterY,
                height: math
                    .max(0.0, endMarkerCenterY - startMarkerCenterY)
                    .toDouble(),
                width: 2,
                child: ColoredBox(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.58),
                ),
              ),

              for (final gap in compressed.gaps)
                if (gap.durationMinutes >= 60)
                  _buildGapCompressionAxis(context, gap, axisCenterX),

              _buildBoundaryMarker(
                context,
                top: _timelineTopInset,
                label: _clockLabel(widget.windowStart),
                caption: 'Inizio giornata',
              ),

              for (final gap in compressed.gaps)
                if (gap.durationMinutes >= 30)
                  _buildFreeGapLabel(context, gap, contentStart),

              for (var index = 0; index < visibleEvents.length; index++)
                _buildTimeMarkers(
                  context,
                  visibleEvents[index],
                  liveCurrentOccurrenceKey,
                  liveNextOccurrenceKey,
                  showStart: _showStartMarker(visibleEvents, index),
                  showEnd: _showEndMarker(visibleEvents, index),
                ),

              for (final group in visualGroups)
                _buildCapsuleGroup(
                  context,
                  group,
                  axisCenterX,
                  liveCurrentOccurrenceKey,
                  liveNextOccurrenceKey,
                ),

              for (final group in visualGroups)
                _buildEventContent(
                  context,
                  group,
                  contentStart,
                  contentWidth,
                  liveCurrentOccurrenceKey,
                  liveNextOccurrenceKey,
                ),

              _buildBoundaryMarker(
                context,
                top: compressed.endBoundaryTop,
                label: _clockLabel(widget.windowEnd, endBoundary: true),
                caption: 'Fine giornata',
              ),

              if (nowMarker != null) ...[
                Positioned(
                  left: axisCenterX - 8,
                  top: nowMarker.y - 8,
                  width: 16,
                  height: 16,
                  child: SizedBox(
                    key: _nowMarkerKey,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _nowColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _nowColor.withValues(alpha: 0.22),
                            blurRadius: 7,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: _currentTimeLabelTop(
                    compressed,
                    visibleEvents,
                    nowMarker,
                  ),
                  width: _timeColumnWidth - 6,
                  child: Text(
                    _clockLabel(_now),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _nowColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  _CompressedTimeline _buildCompressedLayout(List<_TimedOccurrence> timed) {
    final groups = _groupTimedOccurrences(timed);

    final gaps = <_CompressedGap>[];
    final events = <_CompressedEvent>[];

    var y = _timelineTopInset + _boundaryHeight + 8;
    var previousEnd = widget.windowStart;

    for (final group in groups) {
      if (group.start.isAfter(previousEnd)) {
        final gapMinutes = group.start.difference(previousEnd).inMinutes;

        final gapHeight = _freeGapHeight(gapMinutes);

        gaps.add(
          _CompressedGap(
            start: previousEnd,
            end: group.start,
            top: y,
            height: gapHeight,
          ),
        );

        y += gapHeight;
      }

      final groupStartY = y;
      var groupHeight = _eventContentMinHeight;

      final staged = <_StagedCompressedEvent>[];

      for (final item in group.items) {
        final durationMinutes = math.max(
          1,
          item.end.difference(item.start).inMinutes,
        );

        final capsuleHeight = _capsuleHeight(durationMinutes);

        final startOffsetMinutes = item.start.difference(group.start).inMinutes;

        // Le attività sovrapposte possono iniziare in momenti leggermente
        // diversi, ma non ricreiamo una scala temporale lunga: l'offset è
        // volutamente compresso.
        final eventTopOffset = math
            .min(24.0, math.max(0.0, startOffsetMinutes * 0.28))
            .toDouble();

        final visualHeight = math
            .max(capsuleHeight, _eventContentMinHeight)
            .toDouble();

        groupHeight = math
            .max(groupHeight, eventTopOffset + visualHeight)
            .toDouble();

        staged.add(
          _StagedCompressedEvent(
            timed: item,
            lane: group.laneByKey[item.occurrence.occurrenceKey] ?? 0,
            laneCount: group.laneCount,
            topOffset: eventTopOffset,
            capsuleHeight: capsuleHeight,
            visualHeight: visualHeight,
          ),
        );
      }

      for (final stagedEvent in staged) {
        events.add(
          _CompressedEvent(
            timed: stagedEvent.timed,
            lane: stagedEvent.lane,
            laneCount: stagedEvent.laneCount,
            top: groupStartY + stagedEvent.topOffset,
            height: stagedEvent.visualHeight,
            capsuleHeight: stagedEvent.capsuleHeight,
            groupTop: groupStartY,
            groupHeight: groupHeight,
            groupStart: group.start,
            groupEnd: group.end,
          ),
        );
      }

      y += groupHeight;

      if (group.end.isAfter(previousEnd)) {
        previousEnd = group.end;
      }
    }

    if (previousEnd.isBefore(widget.windowEnd)) {
      final gapMinutes = widget.windowEnd.difference(previousEnd).inMinutes;

      final gapHeight = _freeGapHeight(gapMinutes);

      gaps.add(
        _CompressedGap(
          start: previousEnd,
          end: widget.windowEnd,
          top: y,
          height: gapHeight,
        ),
      );

      y += gapHeight;
    }

    final endBoundaryTop = y + 4;
    final totalHeight = endBoundaryTop + _boundaryHeight + _timelineBottomInset;

    return _CompressedTimeline(
      events: events,
      gaps: gaps,
      endBoundaryTop: endBoundaryTop,
      totalHeight: totalHeight,
    );
  }

  List<_TimedGroup> _groupTimedOccurrences(List<_TimedOccurrence> timed) {
    if (timed.isEmpty) {
      return const [];
    }

    final sorted = timed.toList()
      ..sort((a, b) {
        final startCompare = a.start.compareTo(b.start);

        if (startCompare != 0) {
          return startCompare;
        }

        return a.end.compareTo(b.end);
      });

    final groups = <_TimedGroup>[];
    var index = 0;

    while (index < sorted.length) {
      final items = <_TimedOccurrence>[];
      DateTime? groupEnd;
      var cursor = index;

      while (cursor < sorted.length) {
        final item = sorted[cursor];

        if (groupEnd != null && !item.start.isBefore(groupEnd)) {
          break;
        }

        items.add(item);

        if (groupEnd == null || item.end.isAfter(groupEnd)) {
          groupEnd = item.end;
        }

        cursor++;
      }

      final laneEnds = <DateTime>[];
      final laneByKey = <String, int>{};

      for (final item in items) {
        var lane = -1;

        for (var laneIndex = 0; laneIndex < laneEnds.length; laneIndex++) {
          if (!item.start.isBefore(laneEnds[laneIndex])) {
            lane = laneIndex;
            break;
          }
        }

        if (lane == -1) {
          lane = laneEnds.length;
          laneEnds.add(item.end);
        } else {
          laneEnds[lane] = item.end;
        }

        laneByKey[item.occurrence.occurrenceKey] = lane;
      }

      groups.add(
        _TimedGroup(
          items: items,
          start: items.first.start,
          end: groupEnd ?? items.first.end,
          laneByKey: laneByKey,
          laneCount: math.max(1, laneEnds.length),
        ),
      );

      index = cursor;
    }

    return groups;
  }

  double _capsuleHeight(int durationMinutes) {
    final safeMinutes = math.max(1, durationMinutes).toDouble();

    // Fino a 15 minuti manteniamo la stessa altezza minima di prima.
    if (safeMinutes <= _capsuleBaseMinutes) {
      return _capsuleMinHeight;
    }

    // Da 15 a 120 minuti la scala verticale resta invariata:
    // 15 min -> 38 px
    // 30 min -> 56 px
    // 45 min -> 74 px
    // 60 min -> 92 px
    // 90 min -> 128 px
    // 120 min -> 164 px
    final regularHeight =
        _capsuleMinHeight +
        (math.min(safeMinutes, _capsuleLongTaskThresholdMinutes) -
                _capsuleBaseMinutes) *
            _capsuleGrowthPerMinute;

    if (safeMinutes <= _capsuleLongTaskThresholdMinutes) {
      return regularHeight.clamp(_capsuleMinHeight, _capsuleMaxHeight);
    }

    // Dopo le 2 ore continuiamo a comunicare la durata,
    // ma con una crescita più morbida.
    final longTaskHeight =
        regularHeight +
        (safeMinutes - _capsuleLongTaskThresholdMinutes) *
            _capsuleLongTaskGrowthPerMinute;

    return longTaskHeight.clamp(_capsuleMinHeight, _capsuleMaxHeight);
  }

  double _freeGapHeight(int minutes) {
    if (minutes < 15) {
      return _tinyFreeGapHeight;
    }

    if (minutes < 30) {
      return _smallFreeGapHeight;
    }

    final scaled =
        _freeGapBaseHeight + (minutes - 30) * _freeGapGrowthPerMinute;

    return scaled.clamp(_freeGapBaseHeight, _freeGapMaxHeight);
  }

  List<_VisualEventGroup> _buildVisualGroups(
    _CompressedTimeline layout,
    String? liveCurrentOccurrenceKey,
    String? liveNextOccurrenceKey,
  ) {
    final rawGroups = <List<_CompressedEvent>>[];

    for (final event in layout.events) {
      List<_CompressedEvent>? target;

      for (final group in rawGroups) {
        final first = group.first;

        if (first.groupStart.isAtSameMomentAs(event.groupStart) &&
            first.groupEnd.isAtSameMomentAs(event.groupEnd) &&
            (first.groupTop - event.groupTop).abs() < 0.01) {
          target = group;
          break;
        }
      }

      if (target == null) {
        rawGroups.add(<_CompressedEvent>[event]);
      } else {
        target.add(event);
      }
    }

    return rawGroups.map((events) {
      events.sort((a, b) {
        final startCompare = a.timed.start.compareTo(b.timed.start);

        if (startCompare != 0) {
          return startCompare;
        }

        return a.timed.occurrence.displayTask.title.toLowerCase().compareTo(
          b.timed.occurrence.displayTask.title.toLowerCase(),
        );
      });

      final key = _overlapGroupKey(events);

      var preferredIndex = 0;
      var foundCurrent = false;

      if (liveCurrentOccurrenceKey != null) {
        final currentIndex = events.indexWhere(
          (event) =>
              event.timed.occurrence.occurrenceKey == liveCurrentOccurrenceKey,
        );

        if (currentIndex >= 0) {
          preferredIndex = currentIndex;
          foundCurrent = true;
        }
      }

      if (!foundCurrent && liveNextOccurrenceKey != null) {
        final nextIndex = events.indexWhere(
          (event) =>
              event.timed.occurrence.occurrenceKey == liveNextOccurrenceKey,
        );

        if (nextIndex >= 0) {
          preferredIndex = nextIndex;
        }
      }

      final storedIndex = _overlapIndexByGroup[key];

      final selectedIndex =
          storedIndex != null && storedIndex >= 0 && storedIndex < events.length
          ? storedIndex
          : preferredIndex;

      return _VisualEventGroup(
        key: key,
        events: events,
        selectedIndex: selectedIndex,
      );
    }).toList();
  }

  String _overlapGroupKey(List<_CompressedEvent> events) {
    final ids =
        events.map((event) => event.timed.occurrence.occurrenceKey).toList()
          ..sort();

    final first = events.first;

    return '${first.groupStart.microsecondsSinceEpoch}|'
        '${first.groupEnd.microsecondsSinceEpoch}|'
        '${ids.join(",")}';
  }

  void _beginOverlapDrag(_VisualEventGroup group) {
    if (!group.isOverlap) {
      return;
    }

    setState(() {
      _overlapDragDxByGroup[group.key] = 0;
      _overlapDraggingByGroup[group.key] = true;
    });
  }

  void _updateOverlapDrag(_VisualEventGroup group, DragUpdateDetails details) {
    if (!group.isOverlap) {
      return;
    }

    final current = _overlapDragDxByGroup[group.key] ?? 0;

    final next = (current + details.delta.dx).clamp(-72.0, 72.0).toDouble();

    setState(() {
      _overlapDragDxByGroup[group.key] = next;
    });
  }

  void _endOverlapDrag(_VisualEventGroup group, DragEndDetails details) {
    if (!group.isOverlap) {
      return;
    }

    final dragDx = _overlapDragDxByGroup[group.key] ?? 0;

    final velocity = details.primaryVelocity ?? 0;

    final shouldChange = dragDx.abs() >= 26 || velocity.abs() >= 320;

    if (!shouldChange) {
      setState(() {
        _overlapDraggingByGroup[group.key] = false;
        _overlapDragDxByGroup[group.key] = 0;
      });
      return;
    }

    final moveForward = dragDx.abs() >= 26 ? dragDx < 0 : velocity < 0;

    final direction = moveForward ? 1 : -1;

    final currentIndex = _overlapIndexByGroup[group.key] ?? group.selectedIndex;

    var nextIndex = (currentIndex + direction) % group.events.length;

    if (nextIndex < 0) {
      nextIndex += group.events.length;
    }

    setState(() {
      _overlapTransitionDirectionByGroup[group.key] = direction;
      _overlapIndexByGroup[group.key] = nextIndex;
      _overlapDraggingByGroup[group.key] = false;
      _overlapDragDxByGroup[group.key] = 0;
    });
  }

  void _cancelOverlapDrag(_VisualEventGroup group) {
    if (!group.isOverlap) {
      return;
    }

    setState(() {
      _overlapDraggingByGroup[group.key] = false;
      _overlapDragDxByGroup[group.key] = 0;
    });
  }

  double _laneOffsetForEvent(_CompressedEvent event) {
    if (event.laneCount <= 1) {
      return 0;
    }

    return (event.lane - (event.laneCount - 1) / 2) * 7.0;
  }

  int _previewOverlapIndex(_VisualEventGroup group, double dragDx) {
    if (!group.isOverlap || dragDx.abs() < 0.5) {
      return group.selectedIndex;
    }

    final direction = dragDx < 0 ? 1 : -1;

    var index = (group.selectedIndex + direction) % group.events.length;

    if (index < 0) {
      index += group.events.length;
    }

    return index;
  }

  bool _showStartMarker(List<_CompressedEvent> visibleEvents, int index) {
    final event = visibleEvents[index];

    if (event.timed.start.isAtSameMomentAs(widget.windowStart)) {
      return false;
    }

    for (var otherIndex = 0; otherIndex < visibleEvents.length; otherIndex++) {
      if (otherIndex == index) {
        continue;
      }

      final other = visibleEvents[otherIndex];

      if (other.timed.end.isAtSameMomentAs(event.timed.start)) {
        return false;
      }
    }

    return true;
  }

  bool _showEndMarker(List<_CompressedEvent> visibleEvents, int index) {
    final event = visibleEvents[index];

    if (event.timed.end.isAtSameMomentAs(widget.windowEnd)) {
      return false;
    }

    return true;
  }

  void _scheduleAutoScrollToNow() {
    if (_didAutoScrollToNow) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didAutoScrollToNow) {
        return;
      }

      final markerContext = _nowMarkerKey.currentContext;

      if (markerContext == null) {
        return;
      }

      _didAutoScrollToNow = true;

      Scrollable.ensureVisible(
        markerContext,
        alignment: 0.42,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String? _findLiveCurrentOccurrenceKey(List<_TimedOccurrence> timed) {
    final active =
        timed
            .where(
              (item) =>
                  !item.occurrence.isCompleted &&
                  !_now.isBefore(item.start) &&
                  _now.isBefore(item.end),
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    if (active.isEmpty) {
      return null;
    }

    return active.first.occurrence.occurrenceKey;
  }

  String? _findLiveNextOccurrenceKey(List<_TimedOccurrence> timed) {
    final incomplete =
        timed.where((item) => !item.occurrence.isCompleted).toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    for (final item in incomplete) {
      if (!item.start.isBefore(_now)) {
        return item.occurrence.occurrenceKey;
      }
    }

    return null;
  }

  _NowMarker? _buildNowMarker(
    _CompressedTimeline layout,
    String? liveCurrentOccurrenceKey,
  ) {
    if (_now.isBefore(widget.windowStart) || !_now.isBefore(widget.windowEnd)) {
      return null;
    }

    final active = layout.events.where(
      (event) =>
          !_now.isBefore(event.timed.start) && _now.isBefore(event.timed.end),
    );

    if (active.isNotEmpty) {
      _CompressedEvent event = active.first;

      for (final candidate in active) {
        if (candidate.timed.occurrence.occurrenceKey ==
            liveCurrentOccurrenceKey) {
          event = candidate;
          break;
        }
      }

      final totalMinutes = math.max(
        1,
        event.timed.end.difference(event.timed.start).inMinutes,
      );

      final elapsedMinutes = _now
          .difference(event.timed.start)
          .inMinutes
          .clamp(0, totalMinutes);

      final fraction = elapsedMinutes / totalMinutes;

      return _NowMarker(y: event.top + event.capsuleHeight * fraction);
    }

    for (final gap in layout.gaps) {
      if (!_now.isBefore(gap.start) && _now.isBefore(gap.end)) {
        final totalMinutes = math.max(
          1,
          gap.end.difference(gap.start).inMinutes,
        );

        final elapsedMinutes = _now
            .difference(gap.start)
            .inMinutes
            .clamp(0, totalMinutes);

        final rawFraction = elapsedMinutes / totalMinutes;

        // Il gap è volutamente compresso: manteniamo il pallino dentro
        // il tratto senza far sembrare la linea una scala temporale reale.
        final fraction = rawFraction.clamp(0.15, 0.85);

        return _NowMarker(y: gap.top + gap.height * fraction);
      }
    }

    return null;
  }

  double _currentTimeLabelTop(
    _CompressedTimeline layout,
    List<_CompressedEvent> visibleEvents,
    _NowMarker nowMarker,
  ) {
    const labelHeight = 18.0;
    const collisionDistance = 16.0;
    const shift = 20.0;

    var desiredTop = nowMarker.y - labelHeight / 2;

    double markerTopForEvent(_CompressedEvent event, bool end) {
      final durationMinutes = math.max(
        1,
        event.timed.end.difference(event.timed.start).inMinutes,
      );

      if (durationMinutes <= _capsuleBaseMinutes) {
        return event.top + event.capsuleHeight / 2 - labelHeight / 2;
      }

      if (!end) {
        return event.top + 1;
      }

      return event.top + event.capsuleHeight - labelHeight - 1;
    }

    final occupied = <double>[];

    for (var index = 0; index < visibleEvents.length; index++) {
      final event = visibleEvents[index];

      final durationMinutes = math.max(
        1,
        event.timed.end.difference(event.timed.start).inMinutes,
      );

      final showStart = _showStartMarker(visibleEvents, index);

      final showEnd = _showEndMarker(visibleEvents, index);

      if (durationMinutes <= _capsuleBaseMinutes) {
        if (showStart) {
          occupied.add(markerTopForEvent(event, false));
        }

        continue;
      }

      if (showStart) {
        occupied.add(markerTopForEvent(event, false));
      }

      if (showEnd) {
        occupied.add(markerTopForEvent(event, true));
      }
    }

    bool collides(double candidate) {
      return occupied.any(
        (value) => (candidate - value).abs() < collisionDistance,
      );
    }

    if (collides(desiredTop)) {
      _CompressedEvent? activeEvent;

      for (final event in layout.events) {
        if (!_now.isBefore(event.timed.start) &&
            _now.isBefore(event.timed.end)) {
          activeEvent = event;
          break;
        }
      }

      if (activeEvent != null) {
        final totalMinutes = math.max(
          1,
          activeEvent.timed.end.difference(activeEvent.timed.start).inMinutes,
        );

        final elapsedMinutes = _now
            .difference(activeEvent.timed.start)
            .inMinutes
            .clamp(0, totalMinutes);

        final fraction = elapsedMinutes / totalMinutes;

        final preferred = fraction <= 0.5
            ? desiredTop + shift
            : desiredTop - shift;

        final alternate = fraction <= 0.5
            ? desiredTop - shift
            : desiredTop + shift;

        if (!collides(preferred)) {
          desiredTop = preferred;
        } else if (!collides(alternate)) {
          desiredTop = alternate;
        } else {
          desiredTop = preferred;
        }
      } else {
        final down = desiredTop + shift;
        final up = desiredTop - shift;

        if (!collides(down)) {
          desiredTop = down;
        } else if (!collides(up)) {
          desiredTop = up;
        }
      }
    }

    return desiredTop
        .clamp(0.0, math.max(0.0, layout.totalHeight - labelHeight))
        .toDouble();
  }

  Widget _buildBoundaryMarker(
    BuildContext context, {
    required double top,
    required String label,
    required String caption,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: 0,
      right: 0,
      top: top,
      height: _boundaryHeight,
      child: Row(
        children: [
          SizedBox(
            width: _timeColumnWidth - 7,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: _axisColumnWidth,
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                    width: 1.8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: _contentGap),
          Expanded(
            child: Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGapCompressionAxis(
    BuildContext context,
    _CompressedGap gap,
    double axisCenterX,
  ) {
    final shoulder = math
        .min(40.0, math.max(18.0, gap.height * 0.34))
        .toDouble();

    final dashedHeight = math.max(0.0, gap.height - shoulder * 2).toDouble();

    if (dashedHeight < 18) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: axisCenterX - 4,
      top: gap.top + shoulder,
      width: 8,
      height: dashedHeight,
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: CustomPaint(
          painter: _VerticalDashedLinePainter(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.62),
            strokeWidth: 2,
            dashLength: 6,
            dashGap: 5,
          ),
        ),
      ),
    );
  }

  Widget _buildFreeGapLabel(
    BuildContext context,
    _CompressedGap gap,
    double contentStart,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: contentStart,
      right: 0,
      top: gap.top,
      height: gap.height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            child: Text(
              _freeGapLabel(gap.durationMinutes),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeMarkers(
    BuildContext context,
    _CompressedEvent event,
    String? liveCurrentOccurrenceKey,
    String? liveNextOccurrenceKey, {
    required bool showStart,
    required bool showEnd,
  }) {
    final occurrence = event.timed.occurrence;
    final task = occurrence.displayTask;

    final isCurrent = occurrence.occurrenceKey == liveCurrentOccurrenceKey;
    final isNext = occurrence.occurrenceKey == liveNextOccurrenceKey;

    final accentColor = widget.accentColorBuilder(task);

    final markerColor = isCurrent
        ? accentColor
        : isNext
        ? accentColor.withValues(alpha: 0.78)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    final markerStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: markerColor,
      fontWeight: isCurrent
          ? FontWeight.w800
          : isNext
          ? FontWeight.w700
          : FontWeight.w600,
    );

    final durationMinutes = math.max(
      1,
      event.timed.end.difference(event.timed.start).inMinutes,
    );

    if (durationMinutes <= _capsuleBaseMinutes) {
      if (!showStart) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: 0,
        top: event.top + event.capsuleHeight / 2 - 9,
        width: _timeColumnWidth - 7,
        child: Text(
          _clockLabel(event.timed.start),
          textAlign: TextAlign.right,
          maxLines: 1,
          style: markerStyle,
        ),
      );
    }

    if (!showStart && !showEnd) {
      return const SizedBox.shrink();
    }

    final endsAtWindowBoundary = event.timed.end.isAtSameMomentAs(
      widget.windowEnd,
    );

    return Positioned(
      left: 0,
      top: event.top,
      width: _timeColumnWidth - 7,
      height: event.capsuleHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showStart)
            Positioned(
              top: 1,
              left: 0,
              right: 0,
              child: Text(
                _clockLabel(event.timed.start),
                textAlign: TextAlign.right,
                maxLines: 1,
                style: markerStyle,
              ),
            ),
          if (showEnd)
            Positioned(
              bottom: 1,
              left: 0,
              right: 0,
              child: Text(
                _clockLabel(event.timed.end, endBoundary: endsAtWindowBoundary),
                textAlign: TextAlign.right,
                maxLines: 1,
                style: markerStyle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCapsuleGroup(
    BuildContext context,
    _VisualEventGroup group,
    double axisCenterX,
    String? liveCurrentOccurrenceKey,
    String? liveNextOccurrenceKey,
  ) {
    final event = group.selectedEvent;
    final occurrence = event.timed.occurrence;
    final task = occurrence.displayTask;

    final accentColor = widget.accentColorBuilder(task);

    final progress = _taskProgress(task);

    final isCurrent = occurrence.occurrenceKey == liveCurrentOccurrenceKey;

    final isNext = occurrence.occurrenceKey == liveNextOccurrenceKey;

    final dragDx = _overlapDragDxByGroup[group.key] ?? 0;

    final isDragging = _overlapDraggingByGroup[group.key] ?? false;

    final dragProgress = (dragDx.abs() / 58.0).clamp(0.0, 1.0).toDouble();

    final previewIndex = _previewOverlapIndex(group, dragDx);

    final transitionDirection =
        _overlapTransitionDirectionByGroup[group.key] ?? 1;

    final selectedLaneOffset = _laneOffsetForEvent(event);

    // Abbastanza spazio per mostrare le capsule nelle vecchie posizioni
    // "a ventaglio stretto", senza trasformarle in card separate.
    final deckExtra = group.isOverlap ? 24.0 : 0.0;

    final deckLeft = axisCenterX - _capsuleWidth / 2 - deckExtra / 2;

    final deckTop = event.groupTop - 6;

    final deckHeight = event.groupHeight + 12;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      left: deckLeft,
      top: deckTop,
      width: _capsuleWidth + deckExtra,
      height: deckHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          widget.onCompletedChanged(occurrence, !occurrence.isCompleted);
        },
        onLongPress: () {
          widget.onTaskLongPress(occurrence);
        },
        onHorizontalDragStart: group.isOverlap
            ? (_) {
                _beginOverlapDrag(group);
              }
            : null,
        onHorizontalDragUpdate: group.isOverlap
            ? (details) {
                _updateOverlapDrag(group, details);
              }
            : null,
        onHorizontalDragEnd: group.isOverlap
            ? (details) {
                _endOverlapDrag(group, details);
              }
            : null,
        onHorizontalDragCancel: group.isOverlap
            ? () {
                _cancelOverlapDrag(group);
              }
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (group.isOverlap)
              for (var index = 0; index < group.events.length; index++)
                if (index != group.selectedIndex)
                  Builder(
                    builder: (context) {
                      final backEvent = group.events[index];
                      final backTask = backEvent.timed.occurrence.displayTask;

                      final backColor = widget.accentColorBuilder(backTask);

                      final backProgress = _taskProgress(backTask);

                      final isPreview = index == previewIndex;

                      final baseLaneOffset = _laneOffsetForEvent(backEvent);

                      final targetLaneOffset = selectedLaneOffset;

                      final reveal = isPreview ? dragProgress : 0.0;

                      final laneOffset =
                          baseLaneOffset +
                          (targetLaneOffset - baseLaneOffset) * reveal;

                      final opacity = isPreview ? 0.76 + 0.22 * reveal : 0.58;

                      return Positioned(
                        left: deckExtra / 2 + laneOffset,
                        top: backEvent.top - event.groupTop + 6,
                        width: _capsuleWidth,
                        height: backEvent.capsuleHeight,
                        child: Opacity(
                          opacity: opacity,
                          child: _ProgressCapsule(
                            color: backColor,
                            progress: backProgress,
                            isCurrent: false,
                            isNext: false,
                            icon: widget.categoryIconBuilder(backTask),
                            showIcon: false,
                          ),
                        ),
                      );
                    },
                  ),

            Positioned(
              left: deckExtra / 2 + selectedLaneOffset,
              top: event.top - event.groupTop + 6,
              width: _capsuleWidth,
              height: event.capsuleHeight,
              child: AnimatedContainer(
                duration: isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 190),
                curve: Curves.easeOutBack,
                transformAlignment: Alignment.center,
                transform: Matrix4.translationValues(dragDx * 0.82, 0.0, 0.0)
                  ..rotateZ(dragDx * 0.0028),
                child: Opacity(
                  opacity: 1.0 - dragProgress * 0.16,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 230),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final horizontal = transitionDirection.toDouble() * 0.42;

                      final slide =
                          Tween<Offset>(
                            begin: Offset(horizontal, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          );

                      final turn =
                          Tween<double>(
                            begin: -0.025 * transitionDirection,
                            end: 0,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          );

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: slide,
                          child: RotationTransition(turns: turn, child: child),
                        ),
                      );
                    },
                    child: _ProgressCapsule(
                      key: ValueKey(occurrence.occurrenceKey),
                      color: accentColor,
                      progress: progress,
                      isCurrent: isCurrent,
                      isNext: isNext,
                      icon: widget.categoryIconBuilder(task),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventContent(
    BuildContext context,
    _VisualEventGroup group,
    double contentStart,
    double contentWidth,
    String? liveCurrentOccurrenceKey,
    String? liveNextOccurrenceKey,
  ) {
    final event = group.selectedEvent;
    final occurrence = event.timed.occurrence;
    final task = occurrence.displayTask;

    final dragDx = _overlapDragDxByGroup[group.key] ?? 0;

    final isDragging = _overlapDraggingByGroup[group.key] ?? false;

    final dragProgress = (dragDx.abs() / 58.0).clamp(0.0, 1.0).toDouble();

    final transitionDirection =
        _overlapTransitionDirectionByGroup[group.key] ?? 1;

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 230),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide =
            Tween<Offset>(
              begin: Offset(0.18 * transitionDirection, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        final turn = Tween<double>(begin: 0.010 * transitionDirection, end: 0)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slide,
            child: RotationTransition(turns: turn, child: child),
          ),
        );
      },
      child: _TimedTaskContent(
        key: ValueKey(occurrence.occurrenceKey),
        task: task,
        accentColor: widget.accentColorBuilder(task),
        priorityColor: widget.priorityColorBuilder(task),
        secondaryLabel: widget.secondaryLabelBuilder(
          occurrence,
          widget.windowStart,
          widget.windowEnd,
        ),
        subtaskProgress: widget.subtaskProgressBuilder(task),
        isCurrent: occurrence.occurrenceKey == liveCurrentOccurrenceKey,
        isNext: occurrence.occurrenceKey == liveNextOccurrenceKey,
        overlapLabel: group.isOverlap
            ? '${group.selectedIndex + 1}/${group.events.length}'
            : null,
        onSubtaskCompletedChanged: (subtask, completed) {
          return widget.onSubtaskCompletedChanged(
            occurrence,
            subtask,
            completed,
          );
        },
        onTap: () {
          widget.onTaskTap(occurrence);
        },
        onLongPress: () {
          widget.onTaskLongPress(occurrence);
        },
      ),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      left: contentStart,
      top: event.top,
      width: contentWidth,
      height: math.max(event.height, _eventContentMinHeight),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: group.isOverlap
            ? (_) {
                _beginOverlapDrag(group);
              }
            : null,
        onHorizontalDragUpdate: group.isOverlap
            ? (details) {
                _updateOverlapDrag(group, details);
              }
            : null,
        onHorizontalDragEnd: group.isOverlap
            ? (details) {
                _endOverlapDrag(group, details);
              }
            : null,
        onHorizontalDragCancel: group.isOverlap
            ? () {
                _cancelOverlapDrag(group);
              }
            : null,
        child: AnimatedContainer(
          duration: isDragging
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          transformAlignment: Alignment.centerLeft,
          transform: Matrix4.translationValues(dragDx * 0.24, 0.0, 0.0)
            ..rotateZ(dragDx * 0.0007),
          child: Opacity(opacity: 1.0 - dragProgress * 0.18, child: child),
        ),
      ),
    );
  }

  double _taskProgress(LifeTask task) {
    if (task.isCompleted) {
      return 1;
    }

    if (task.subtasks.isEmpty) {
      return 0;
    }

    final completed = task.subtasks
        .where((subtask) => subtask.isCompleted)
        .length;

    return completed / task.subtasks.length;
  }

  String _clockLabel(DateTime value, {bool endBoundary = false}) {
    if (endBoundary &&
        value.hour == 0 &&
        value.minute == 0 &&
        value.isAfter(widget.windowStart)) {
      final exactDay =
          CivilDate.differenceInDays(widget.windowStart, value) == 1 &&
          widget.windowStart.hour == 0 &&
          widget.windowStart.minute == 0;

      if (exactDay) {
        return '24:00';
      }
    }

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _durationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (hours == 0) {
      return '$remaining min';
    }

    if (remaining == 0) {
      return hours == 1 ? '1 ora' : '$hours ore';
    }

    return '$hours h $remaining min';
  }

  String _freeGapLabel(int minutes) {
    if (minutes == 60) {
      return '1 ora libera';
    }

    if (minutes > 60 && minutes % 60 == 0) {
      return '${minutes ~/ 60} ore libere';
    }

    return '${_durationLabel(minutes)} liberi';
  }
}

class _UntimedSection extends StatelessWidget {
  final List<TaskOccurrence> occurrences;

  final String? Function(LifeTask task) subtaskProgressBuilder;

  final Color Function(LifeTask task) accentColorBuilder;

  final Color Function(LifeTask task) priorityColorBuilder;

  final Future<void> Function(TaskOccurrence occurrence, bool completed)
  onCompletedChanged;

  final void Function(TaskOccurrence occurrence) onTaskTap;

  final void Function(TaskOccurrence occurrence) onTaskLongPress;

  const _UntimedSection({
    required this.occurrences,
    required this.subtaskProgressBuilder,
    required this.accentColorBuilder,
    required this.priorityColorBuilder,
    required this.onCompletedChanged,
    required this.onTaskTap,
    required this.onTaskLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SENZA ORARIO',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < occurrences.length; i++) ...[
          _UntimedTaskRow(
            occurrence: occurrences[i],
            accentColor: accentColorBuilder(occurrences[i].displayTask),
            priorityColor: priorityColorBuilder(occurrences[i].displayTask),
            subtaskProgress: subtaskProgressBuilder(occurrences[i].displayTask),
            onCompletedChanged: onCompletedChanged,
            onTaskTap: onTaskTap,
            onTaskLongPress: onTaskLongPress,
          ),
          if (i != occurrences.length - 1)
            Divider(
              indent: 40,
              color: colorScheme.outlineVariant.withValues(alpha: 0.46),
            ),
        ],
      ],
    );
  }
}

class _UntimedTaskRow extends StatelessWidget {
  final TaskOccurrence occurrence;
  final Color accentColor;
  final Color priorityColor;
  final String? subtaskProgress;

  final Future<void> Function(TaskOccurrence occurrence, bool completed)
  onCompletedChanged;

  final void Function(TaskOccurrence occurrence) onTaskTap;

  final void Function(TaskOccurrence occurrence) onTaskLongPress;

  const _UntimedTaskRow({
    required this.occurrence,
    required this.accentColor,
    required this.priorityColor,
    required this.subtaskProgress,
    required this.onCompletedChanged,
    required this.onTaskTap,
    required this.onTaskLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final task = occurrence.displayTask;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            onCompletedChanged(occurrence, !occurrence.isCompleted);
          },
          child: SizedBox(
            width: 40,
            height: 56,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: occurrence.isCompleted
                      ? accentColor
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 2.2),
                ),
                child: occurrence.isCompleted
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                onTaskTap(occurrence);
              },
              onLongPress: () {
                onTaskLongPress(occurrence);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  task.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        decoration: occurrence.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Icon(
                                Icons.flag_outlined,
                                size: 15,
                                color: priorityColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            task.allDay ? 'Tutto il giorno' : 'Senza orario',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          if (subtaskProgress != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.checklist_rounded,
                                  size: 14,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  subtaskProgress!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: accentColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.58,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimedTaskContent extends StatelessWidget {
  final LifeTask task;
  final Color accentColor;
  final Color priorityColor;
  final String secondaryLabel;
  final String? subtaskProgress;
  final bool isCurrent;
  final bool isNext;
  final String? overlapLabel;
  final Future<void> Function(TaskSubtask subtask, bool completed)
  onSubtaskCompletedChanged;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TimedTaskContent({
    super.key,
    required this.task,
    required this.accentColor,
    required this.priorityColor,
    required this.secondaryLabel,
    required this.subtaskProgress,
    required this.isCurrent,
    required this.isNext,
    required this.overlapLabel,
    required this.onSubtaskCompletedChanged,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final compact = width < 150 || height < 78;
        final veryCompact = width < 105 || height < 60;

        final availableSubtaskRows = ((height - 96) / 25)
            .floor()
            .clamp(0, 4)
            .toInt();

        final visibleSubtasks = availableSubtaskRows <= 0
            ? const <TaskSubtask>[]
            : task.subtasks.take(availableSubtaskRows).toList();

        final hiddenSubtaskCount = math.max(
          0,
          task.subtasks.length - visibleSubtasks.length,
        );

        final showSubtaskRows = visibleSubtasks.isNotEmpty && !veryCompact;

        final panelColor = Color.alphaBlend(
          accentColor.withValues(alpha: isCurrent ? 0.075 : 0.045),
          colorScheme.surface,
        );

        final panelBorder = accentColor.withValues(
          alpha: isCurrent ? 0.22 : 0.12,
        );

        Widget headerContent = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: showSubtaskRows ? 10 : 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: veryCompact ? 14 : 17,
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w700,
                        height: 1.08,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.flag_outlined,
                    size: compact ? 14 : 15,
                    color: priorityColor,
                  ),
                  if (overlapLabel != null && width >= 120) ...[
                    const SizedBox(width: 8),
                    Text(
                      overlapLabel!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),

              if (!veryCompact && secondaryLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  secondaryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: compact ? 12.5 : 13.5,
                    height: 1.15,
                    fontWeight: isNext ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],

              if (subtaskProgress != null && height >= 78) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.checklist_rounded, size: 14, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      subtaskProgress!,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );

        if (!showSubtaskRows && height >= 72) {
          headerContent = Align(
            alignment: Alignment.centerLeft,
            child: headerContent,
          );
        }

        final header = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(14),
            child: headerContent,
          ),
        );

        final subtaskSection = showSubtaskRows
            ? Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 12,
                  0,
                  compact ? 10 : 12,
                  8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.44),
                    ),
                    const SizedBox(height: 4),
                    for (final subtask in visibleSubtasks)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            await onSubtaskCompletedChanged(
                              subtask,
                              !subtask.isCompleted,
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  subtask.isCompleted
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  size: 17,
                                  color: subtask.isCompleted
                                      ? accentColor
                                      : colorScheme.onSurfaceVariant.withValues(
                                          alpha: 0.72,
                                        ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    subtask.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: subtask.isCompleted
                                              ? colorScheme.onSurfaceVariant
                                              : colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                          decoration: subtask.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (hiddenSubtaskCount > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 2, top: 2),
                          child: Text(
                            '+$hiddenSubtaskCount altre',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : null;

        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: panelBorder, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [header, ?subtaskSection],
            ),
          ),
        );
      },
    );
  }
}

class _ProgressCapsule extends StatelessWidget {
  final Color color;
  final double progress;
  final bool isCurrent;
  final bool isNext;
  final IconData icon;
  final bool showIcon;

  const _ProgressCapsule({
    super.key,
    required this.color,
    required this.progress,
    required this.isCurrent,
    required this.isNext,
    required this.icon,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();

    final background = Theme.of(context).scaffoldBackgroundColor;

    final capsuleBase = Color.alphaBlend(
      color.withValues(alpha: 0.12),
      background,
    );

    final fillColor = Color.alphaBlend(
      color.withValues(alpha: 0.92),
      background,
    );

    final borderAlpha = isCurrent
        ? 0.96
        : isNext
        ? 0.78
        : 0.62;

    final borderWidth = isCurrent
        ? 2.8
        : isNext
        ? 2.4
        : 2.2;

    final radius = BorderRadius.circular(999);

    return Container(
      decoration: BoxDecoration(
        color: capsuleBase,
        borderRadius: radius,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      // Il bordo viene disegnato SOPRA base e riempimento. In questo modo
      // il fill arriva fino al contorno senza lasciare il sottile alone
      // chiaro che prima poteva comparire tra progress e bordo.
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: color.withValues(alpha: borderAlpha),
          width: borderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(end: clampedProgress),
            builder: (context, value, child) {
              return ClipRect(
                clipper: _VerticalProgressClipper(value),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: radius,
                  ),
                ),
              );
            },
          ),

          if (showIcon)
            Center(
              child: Icon(
                icon,
                size: 19,
                color: clampedProgress >= 0.50
                    ? (ThemeData.estimateBrightnessForColor(fillColor) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black87)
                    : color,
              ),
            ),
        ],
      ),
    );
  }
}

class _VerticalProgressClipper extends CustomClipper<Rect> {
  final double progress;

  const _VerticalProgressClipper(this.progress);

  @override
  Rect getClip(Size size) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();

    return Rect.fromLTWH(0, 0, size.width, size.height * clamped);
  }

  @override
  bool shouldReclip(covariant _VerticalProgressClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

class _VerticalDashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  const _VerticalDashedLinePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final x = size.width / 2;

    var y = 0.0;

    while (y < size.height) {
      final endY = math.min(size.height, y + dashLength);

      canvas.drawLine(Offset(x, y), Offset(x, endY), paint);

      y = endY + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashGap != dashGap;
  }
}

class _NoTimedTasksMessage extends StatelessWidget {
  final Color color;

  const _NoTimedTasksMessage({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        'Nessuna attività con orario.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

class _VisualEventGroup {
  final String key;
  final List<_CompressedEvent> events;
  final int selectedIndex;

  const _VisualEventGroup({
    required this.key,
    required this.events,
    required this.selectedIndex,
  });

  bool get isOverlap => events.length > 1;

  _CompressedEvent get selectedEvent => events[selectedIndex];
}

class _TimedOccurrence {
  final TaskOccurrence occurrence;
  final DateTime start;
  final DateTime end;

  const _TimedOccurrence({
    required this.occurrence,
    required this.start,
    required this.end,
  });
}

class _TimedGroup {
  final List<_TimedOccurrence> items;
  final DateTime start;
  final DateTime end;
  final Map<String, int> laneByKey;
  final int laneCount;

  const _TimedGroup({
    required this.items,
    required this.start,
    required this.end,
    required this.laneByKey,
    required this.laneCount,
  });
}

class _StagedCompressedEvent {
  final _TimedOccurrence timed;
  final int lane;
  final int laneCount;
  final double topOffset;
  final double capsuleHeight;
  final double visualHeight;

  const _StagedCompressedEvent({
    required this.timed,
    required this.lane,
    required this.laneCount,
    required this.topOffset,
    required this.capsuleHeight,
    required this.visualHeight,
  });
}

class _CompressedEvent {
  final _TimedOccurrence timed;
  final int lane;
  final int laneCount;
  final double top;
  final double height;
  final double capsuleHeight;

  final double groupTop;
  final double groupHeight;
  final DateTime groupStart;
  final DateTime groupEnd;

  const _CompressedEvent({
    required this.timed,
    required this.lane,
    required this.laneCount,
    required this.top,
    required this.height,
    required this.capsuleHeight,
    required this.groupTop,
    required this.groupHeight,
    required this.groupStart,
    required this.groupEnd,
  });
}

class _CompressedGap {
  final DateTime start;
  final DateTime end;
  final double top;
  final double height;

  const _CompressedGap({
    required this.start,
    required this.end,
    required this.top,
    required this.height,
  });

  int get durationMinutes {
    final duration = end.difference(start).inMinutes;
    return duration < 0 ? 0 : duration;
  }
}

class _CompressedTimeline {
  final List<_CompressedEvent> events;
  final List<_CompressedGap> gaps;
  final double endBoundaryTop;
  final double totalHeight;

  const _CompressedTimeline({
    required this.events,
    required this.gaps,
    required this.endBoundaryTop,
    required this.totalHeight,
  });
}

class _NowMarker {
  final double y;

  const _NowMarker({required this.y});
}
