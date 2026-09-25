part of 'calendar_page.dart';

// Vista settimanale del Calendario: interazioni, drag, resize, zoom e widget
// dedicati alla griglia Week. È un part della stessa libreria per mantenere
// invariata la visibilità dei membri privati durante questo refactor.
enum _WeekOccurrenceAction {
  edit,
  duplicate,
  copy,
  delete,
}

enum _WeekEmptySlotAction {
  create,
  paste,
}

enum _WeekPinchAxis {
  horizontal,
  vertical,
}

typedef _WeekAutoScrollUpdate = void Function(
  Offset globalPosition, {
  required bool allowHorizontal,
  required bool allowVertical,
  VoidCallback? onScrolled,
});

class _WeekEdgeAutoScroller {
  final ScrollController verticalController;
  final ScrollController horizontalController;
  final BuildContext viewportContext;
  final double gutterWidth;
  final double headerHeight;

  Offset? _globalPosition;
  bool _allowHorizontal = false;
  bool _allowVertical = false;
  VoidCallback? _onScrolled;
  bool _active = false;
  bool _frameScheduled = false;

  _WeekEdgeAutoScroller({
    required this.verticalController,
    required this.horizontalController,
    required this.viewportContext,
    required this.gutterWidth,
    required this.headerHeight,
  });

  void update(
    Offset globalPosition, {
    required bool allowHorizontal,
    required bool allowVertical,
    VoidCallback? onScrolled,
  }) {
    _globalPosition = globalPosition;
    _allowHorizontal = allowHorizontal;
    _allowVertical = allowVertical;
    _onScrolled = onScrolled;
    _active = true;
    _scheduleFrame();
  }

  void stop() {
    _active = false;
    _globalPosition = null;
    _onScrolled = null;
  }

  void _scheduleFrame() {
    if (!_active || _frameScheduled) {
      return;
    }

    _frameScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _frameScheduled = false;

        if (!_active) {
          return;
        }

        final keepScrolling =
            _step();

        if (_active &&
            keepScrolling) {
          _scheduleFrame();
        }
      },
    );

    WidgetsBinding.instance.scheduleFrame();
  }

  bool _step() {
    final pointer = _globalPosition;

    if (pointer == null ||
        !viewportContext.mounted) {
      return false;
    }

    final renderObject =
        viewportContext.findRenderObject();

    if (renderObject is! RenderBox) {
      return false;
    }

    final origin =
        renderObject.localToGlobal(
      Offset.zero,
    );

    final viewportRect =
        origin & renderObject.size;

    // L'header dei giorni resta fisso sopra la griglia oraria.
    // Il gutter delle ore resta fisso a sinistra.
    final contentLeft =
        viewportRect.left + gutterWidth;
    final contentTop =
        viewportRect.top + headerHeight;

    var moved = false;
    var edgeActive = false;

    if (_allowVertical &&
        verticalController.hasClients) {
      final delta =
          _edgeStep(
        position:
            pointer.dy,
        leading:
            contentTop,
        trailing:
            viewportRect.bottom,
        zone:
            72,
        maxStep:
            18,
      );

      edgeActive =
          edgeActive ||
          delta.abs() >= 0.01;

      moved =
          _jumpBy(
            verticalController,
            delta,
          ) ||
          moved;
    }

    if (_allowHorizontal &&
        horizontalController.hasClients) {
      final delta =
          _edgeStep(
        position:
            pointer.dx,
        leading:
            contentLeft,
        trailing:
            viewportRect.right,
        zone:
            54,
        maxStep:
            10,
      );

      edgeActive =
          edgeActive ||
          delta.abs() >= 0.01;

      moved =
          _jumpBy(
            horizontalController,
            delta,
          ) ||
          moved;
    }

    if (moved) {
      _onScrolled?.call();
    }

    return edgeActive;
  }

  double _edgeStep({
    required double position,
    required double leading,
    required double trailing,
    required double zone,
    required double maxStep,
  }) {
    if (trailing <= leading) {
      return 0;
    }

    if (position < leading + zone) {
      final strength =
          ((leading + zone - position) / zone)
              .clamp(
                0.0,
                1.0,
              )
              .toDouble();

      return -maxStep *
          strength *
          strength;
    }

    if (position > trailing - zone) {
      final strength =
          ((position - (trailing - zone)) / zone)
              .clamp(
                0.0,
                1.0,
              )
              .toDouble();

      return maxStep *
          strength *
          strength;
    }

    return 0;
  }

  bool _jumpBy(
    ScrollController controller,
    double delta,
  ) {
    if (delta.abs() < 0.01 ||
        !controller.hasClients) {
      return false;
    }

    final position =
        controller.position;

    final target =
        (controller.offset + delta)
            .clamp(
              position.minScrollExtent,
              position.maxScrollExtent,
            )
            .toDouble();

    if ((target - controller.offset)
            .abs() <
        0.01) {
      return false;
    }

    controller.jumpTo(
      target,
    );

    return true;
  }
}

extension _CalendarWeekInteractionsExtension on _CalendarPageState {
  void _handleWeekHeaderDragUpdate(
    DragUpdateDetails details,
  ) {
    final nextValue =
        (_weekHeaderCollapseController.value -
                details.delta.dy /
                    _CalendarPageState._weekHeaderDragDistance)
            .clamp(
              0.0,
              1.0,
            )
            .toDouble();

    _weekHeaderCollapseController.value =
        nextValue;
  }

  void _handleWeekHeaderDragEnd(
    DragEndDetails details,
  ) {
    final velocity =
        details.primaryVelocity ??
            0.0;

    final shouldCollapse =
        velocity < -120
            ? true
            : velocity > 120
                ? false
                : _weekHeaderCollapseController
                        .value >=
                    0.5;

    _weekHeaderCollapsed =
        shouldCollapse;

    _weekHeaderCollapseController.animateTo(
      shouldCollapse
          ? 1.0
          : 0.0,
      duration:
          _CalendarPageState._weekHeaderSettleDuration,
      curve:
          Curves.easeOutCubic,
    );
  }

  void _toggleWeekUntimed(
    DateTime day,
  ) {
    final normalized =
        _dateOnly(day);

    final sameSelected =
        _selectedDay.year == normalized.year &&
        _selectedDay.month == normalized.month &&
        _selectedDay.day == normalized.day;

    _updateCalendarState(() {
      _selectedDay = normalized;
      _focusedDay = normalized;
      _weekUntimedExpanded =
          sameSelected
              ? !_weekUntimedExpanded
              : true;
    });
  }

  void _closeWeekUntimed() {
    if (!_weekUntimedExpanded) {
      return;
    }

    _updateCalendarState(() {
      _weekUntimedExpanded = false;
    });
  }

  LifeTask _taskForOccurrenceEditing(
    TaskOccurrence occurrence,
  ) {
    final effective =
        occurrence.displayTask;

    return effective.copyWith(
      scheduledDate:
          occurrence.date,
      recurrence:
          occurrence.task.recurrence,
      subtasks:
          occurrence.subtasks,
      isCompleted:
          occurrence.isCompleted,
    );
  }


  Future<void> _editOccurrenceFromWeek(
    TaskOccurrence occurrence,
  ) async {
    if (!occurrence.isRecurring) {
      final result =
          await Navigator.push<
              TaskFormResult>(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  TaskFormPage(
            categoryRepository:
                widget.categoryRepository,
            initialTask:
                _taskForOccurrenceEditing(
              occurrence,
            ),
          ),
        ),
      );

      if (result == null) {
        return;
      }

      if (result.shouldDelete) {
        await _taskActions.delete(
          task:
              occurrence.task,
          scope:
              TaskSeriesScope.series,
        );
        return;
      }

      if (result.task != null) {
        await widget.taskRepository
            .updateTask(
          result.task!,
        );
      }

      return;
    }

    final scope =
        await TaskPrompts
            .chooseSeriesScope(
      context,
      action:
          TaskSeriesPromptAction.edit,
    );

    if (!mounted ||
        scope == null) {
      return;
    }

    if (scope ==
        TaskSeriesScope.occurrence) {
      final result =
          await Navigator.push<
              TaskFormResult>(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  TaskFormPage(
            categoryRepository:
                widget.categoryRepository,
            initialTask:
                _taskForOccurrenceEditing(
              occurrence,
            ),
            occurrenceOnly:
                true,
          ),
        ),
      );

      final edited =
          result?.task;

      if (edited == null) {
        return;
      }

      await widget.taskRepository
          .saveOccurrenceOverride(
        occurrence:
            occurrence,
        editedTask:
            edited,
      );

      return;
    }

    final result =
        await Navigator.push<
            TaskFormResult>(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                TaskFormPage(
          categoryRepository:
              widget.categoryRepository,
          initialTask:
              occurrence.task,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    if (result.shouldDelete) {
      await _taskActions.delete(
        task:
            occurrence.task,
        scope:
            TaskSeriesScope.series,
      );
      return;
    }

    if (result.task != null) {
      await widget.taskRepository
          .updateTask(
        result.task!,
      );
    }
  }

  Future<void> _deleteOccurrenceFromWeek(
    TaskOccurrence occurrence,
  ) async {
    if (!occurrence.isRecurring) {
      final confirmed =
          await TaskPrompts
              .confirmDeleteTask(
        context,
        task:
            occurrence.task,
      );

      if (!confirmed) {
        return;
      }

      await _taskActions.delete(
        task:
            occurrence.task,
        scope:
            TaskSeriesScope.series,
      );
      return;
    }

    final scope =
        await TaskPrompts
            .chooseSeriesScope(
      context,
      action:
          TaskSeriesPromptAction.delete,
    );

    if (!mounted ||
        scope == null) {
      return;
    }

    if (scope ==
        TaskSeriesScope.occurrence) {
      final confirmed =
          await TaskPrompts
              .confirmDeleteOccurrence(
        context,
      );

      if (!confirmed) {
        return;
      }

      await _taskActions.delete(
        task:
            occurrence.task,
        occurrence:
            occurrence,
        scope:
            TaskSeriesScope.occurrence,
      );
      return;
    }

    final confirmed =
        await TaskPrompts
            .confirmDeleteTask(
      context,
      task:
          occurrence.task,
    );

    if (!confirmed) {
      return;
    }

    await _taskActions.delete(
      task:
          occurrence.task,
      scope:
          TaskSeriesScope.series,
    );
  }

  LifeTask _taskTemplateFromOccurrence(
    TaskOccurrence occurrence,
  ) {
    final effective = occurrence.displayTask;

    // Copia/Duplica lavorano sull'occorrenza concreta visibile.
    // Se l'originale appartiene a una serie, il duplicato nasce come
    // attività singola: evita di creare accidentalmente una seconda serie.
    return effective.copyWith(
      scheduledDate:
          occurrence.date,
      recurrence:
          const TaskRecurrence.none(),
      subtasks:
          occurrence.subtasks,
      isCompleted:
          false,
    );
  }

  Future<void> _duplicateOccurrenceFromWeek(
    TaskOccurrence occurrence,
  ) async {
    final draft = _taskTemplateFromOccurrence(
      occurrence,
    );

    final result = await Navigator.push<TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormPage(
          categoryRepository: widget.categoryRepository,
          initialTask: draft,
          duplicateMode: true,
        ),
      ),
    );

    if (!mounted ||
        result == null ||
        result.shouldDelete ||
        result.task == null) {
      return;
    }

    await widget.taskRepository.addTask(
      result.task!,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(
          milliseconds: 1400,
        ),
        content: Text(
          'Duplicata "${result.task!.title}"',
        ),
      ),
    );
  }

  void _copyOccurrenceFromWeek(
    TaskOccurrence occurrence,
  ) {
    _weekClipboardTask = _taskTemplateFromOccurrence(
      occurrence,
    );

    final copiedTitle = _weekClipboardTask!.title;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(
          milliseconds: 1400,
        ),
        content: Text(
          'Copiata "$copiedTitle" negli appunti del calendario.',
        ),
      ),
    );
  }

  LifeTask _taskForWeekPaste({
    required LifeTask source,
    required DateTime date,
    required int startTimeMinutes,
  }) {
    final seed =
        DateTime.now()
            .microsecondsSinceEpoch;

    final copiedSubtasks =
        <TaskSubtask>[
      for (var index = 0;
          index < source.subtasks.length;
          index++)
        TaskSubtask(
          id:
              'subtask_${seed}_$index',
          title:
              source.subtasks[index].title,
          sortOrder:
              index,
          isCompleted:
              false,
        ),
    ];

    return source.copyWith(
      id:
          seed.toString(),
      scheduledDate:
          _dateOnly(date),
      startTimeMinutes:
          startTimeMinutes,
      allDay:
          false,
      recurrence:
          const TaskRecurrence.none(),
      subtasks:
          copiedSubtasks,
      isCompleted:
          false,
    );
  }

  Future<void> _createTaskFromWeekSlot(
    DateTime date,
    int centerTimeMinutes,
  ) async {
    final result =
        await Navigator.push<TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskFormPage(
          categoryRepository:
              widget.categoryRepository,
          initialDate:
              _dateOnly(date),
          initialCenterTimeMinutes:
              centerTimeMinutes,
        ),
      ),
    );

    if (!mounted ||
        result == null ||
        result.shouldDelete ||
        result.task == null) {
      return;
    }

    await widget.taskRepository.addTask(
      result.task!,
    );

    final createdDate =
        result.task!.scheduledDate;

    if (!mounted) {
      return;
    }

    if (createdDate != null) {
      _updateCalendarState(() {
        _selectedDay =
            _dateOnly(createdDate);
        _focusedDay =
            _dateOnly(createdDate);
      });
    }
  }

  int _preferredWeekStartMinutes(
    double rawMinutes,
  ) {
    final nearestQuarter =
        (rawMinutes / 15).round() * 15;

    final nearestHalfHour =
        (rawMinutes / 30).round() * 30;

    // Preferenza leggera per orari :00 / :30, senza sacrificare
    // il centraggio del blocco quando servirebbe uno spostamento evidente.
    final preferred =
        (rawMinutes - nearestHalfHour).abs() <= 8
            ? nearestHalfHour
            : nearestQuarter;

    return preferred
        .clamp(
          0,
          24 * 60 - 15,
        )
        .toInt();
  }

  int _weekPasteStartFromCenter({
    required LifeTask source,
    required int centerMinutes,
  }) {
    // L'utente posiziona visivamente il BLOCCO sul punto premuto:
    // quindi il punto scelto rappresenta il centro dell'attività,
    // non il suo orario di inizio.
    //
    // Se manca una durata, usiamo i 30 minuti con cui la Week rende
    // già visivamente una task senza durata.
    final duration =
        source.durationMinutes != null &&
                source.durationMinutes! > 0
            ? source.durationMinutes!
            : 30;

    final rawStart =
        centerMinutes -
        duration / 2;

    return _preferredWeekStartMinutes(
      rawStart,
    );
  }

  Future<void> _pasteClipboardAtWeekSlot(
    DateTime date,
    int centerTimeMinutes,
  ) async {
    final source =
        _weekClipboardTask;

    if (source == null) {
      return;
    }

    final startTimeMinutes =
        _weekPasteStartFromCenter(
      source:
          source,
      centerMinutes:
          centerTimeMinutes,
    );

    final pasted =
        _taskForWeekPaste(
      source:
          source,
      date:
          date,
      startTimeMinutes:
          startTimeMinutes,
    );

    await widget.taskRepository.addTask(
      pasted,
    );

    if (!mounted) {
      return;
    }

    _updateCalendarState(() {
      _selectedDay =
          _dateOnly(date);
      _focusedDay =
          _dateOnly(date);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration:
            const Duration(
          milliseconds:
              1400,
        ),
        content:
            Text(
          'Incollata "${pasted.title}" alle ${_clockLabel(startTimeMinutes)}',
        ),
      ),
    );
  }

  Future<void> _showWeekEmptySlotActions(
    DateTime date,
    int centerTimeMinutes,
  ) async {
    final clipboardTask =
        _weekClipboardTask;

    final action =
        await showModalBottomSheet<
            _WeekEmptySlotAction>(
      context:
          context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha:
            0.28,
      ),
      useSafeArea:
          true,
      builder:
          (sheetContext) {
        final colorScheme =
            Theme.of(
          sheetContext,
        ).colorScheme;

        return SafeArea(
          top:
              false,
          child:
              Container(
            margin:
                const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12,
            ),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              10,
            ),
            decoration:
                BoxDecoration(
              color:
                  colorScheme.surface,
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
              border:
                  Border.all(
                color:
                    colorScheme
                        .outlineVariant
                        .withValues(
                  alpha:
                      0.55,
                ),
              ),
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedAgendaDateLabel(date)} · '
                  '${_clockLabel(centerTimeMinutes)}',
                  style:
                      Theme.of(
                    sheetContext,
                  )
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                          ),
                ),
                const SizedBox(
                  height:
                      8,
                ),
                _WeekActionSheetRow(
                  icon:
                      Icons.add_circle_outline,
                  label:
                      'Nuova attività',
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _WeekEmptySlotAction.create,
                    );
                  },
                ),
                if (clipboardTask != null) ...[
                  Divider(
                    height:
                        1,
                    indent:
                        44,
                    color:
                        colorScheme
                            .outlineVariant
                            .withValues(
                      alpha:
                          0.5,
                    ),
                  ),
                  _WeekActionSheetRow(
                    icon:
                        Icons.content_paste_outlined,
                    label:
                        'Incolla qui · ${clipboardTask.title}',
                    onTap:
                        () {
                      Navigator.pop(
                        sheetContext,
                        _WeekEmptySlotAction.paste,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (!mounted ||
        action == null) {
      return;
    }

    switch (action) {
      case _WeekEmptySlotAction.create:
        await _createTaskFromWeekSlot(
          date,
          centerTimeMinutes,
        );
        break;

      case _WeekEmptySlotAction.paste:
        await _pasteClipboardAtWeekSlot(
          date,
          centerTimeMinutes,
        );
        break;
    }
  }

  Future<void> _showOccurrenceActions(
    TaskOccurrence occurrence,
  ) async {
    final action =
        await showModalBottomSheet<
            _WeekOccurrenceAction>(
      context:
          context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha:
            0.28,
      ),
      useSafeArea:
          true,
      builder:
          (sheetContext) {
        final colorScheme =
            Theme.of(
          sheetContext,
        ).colorScheme;

        return SafeArea(
          top:
              false,
          child:
              Container(
            margin:
                const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12,
            ),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              10,
            ),
            decoration:
                BoxDecoration(
              color:
                  colorScheme.surface,
              borderRadius:
                  BorderRadius.circular(
                24,
              ),
              border:
                  Border.all(
                color:
                    colorScheme
                        .outlineVariant
                        .withValues(
                  alpha:
                      0.55,
                ),
              ),
            ),
            child:
                Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  occurrence
                      .displayTask
                      .title,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      Theme.of(
                    sheetContext,
                  )
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                          ),
                ),
                const SizedBox(
                  height:
                      8,
                ),
                _WeekActionSheetRow(
                  icon:
                      Icons
                          .edit_outlined,
                  label:
                      'Modifica',
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _WeekOccurrenceAction
                          .edit,
                    );
                  },
                ),
                Divider(
                  height:
                      1,
                  indent:
                      44,
                  color:
                      colorScheme
                          .outlineVariant
                          .withValues(
                    alpha:
                        0.5,
                  ),
                ),
                _WeekActionSheetRow(
                  icon:
                      Icons
                          .library_add_outlined,
                  label:
                      'Duplica',
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _WeekOccurrenceAction
                          .duplicate,
                    );
                  },
                ),
                Divider(
                  height:
                      1,
                  indent:
                      44,
                  color:
                      colorScheme
                          .outlineVariant
                          .withValues(
                    alpha:
                        0.5,
                  ),
                ),
                _WeekActionSheetRow(
                  icon:
                      Icons
                          .content_copy_outlined,
                  label:
                      'Copia',
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _WeekOccurrenceAction
                          .copy,
                    );
                  },
                ),
                Divider(
                  height:
                      1,
                  indent:
                      44,
                  color:
                      colorScheme
                          .outlineVariant
                          .withValues(
                    alpha:
                        0.5,
                  ),
                ),
                _WeekActionSheetRow(
                  icon:
                      Icons
                          .delete_outline,
                  label:
                      'Elimina',
                  isDestructive:
                      true,
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _WeekOccurrenceAction
                          .delete,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted ||
        action == null) {
      return;
    }

    switch (action) {
      case _WeekOccurrenceAction.edit:
        await _editOccurrenceFromWeek(
          occurrence,
        );
        break;

      case _WeekOccurrenceAction.duplicate:
        await _duplicateOccurrenceFromWeek(
          occurrence,
        );
        break;

      case _WeekOccurrenceAction.copy:
        _copyOccurrenceFromWeek(
          occurrence,
        );
        break;

      case _WeekOccurrenceAction.delete:
        await _deleteOccurrenceFromWeek(
          occurrence,
        );
        break;
    }
  }

  String _clockLabel(
    int minutes,
  ) {
    final normalized =
        minutes % (24 * 60);

    final hour =
        (normalized ~/ 60)
            .toString()
            .padLeft(2, '0');

    final minute =
        (normalized % 60)
            .toString()
            .padLeft(2, '0');

    return '$hour:$minute';
  }

  TaskRecurrence _shiftRecurrence(
    LifeTask series,
    int dayDelta,
  ) {
    final recurrence =
        series.recurrence;

    if (recurrence.type !=
        TaskRecurrenceType.weekly ||
        dayDelta % 7 == 0) {
      return recurrence;
    }

    final sourceWeekdays =
        recurrence.weekdays.isEmpty
            ? <int>[
                series.scheduledDate?.weekday ??
                    DateTime.monday,
              ]
            : recurrence.weekdays;

    final shift =
        dayDelta % 7;

    final shifted =
        sourceWeekdays.map(
      (weekday) {
        final zeroBased =
            weekday -
            DateTime.monday;

        final shiftedZeroBased =
            (zeroBased + shift) % 7;

        return shiftedZeroBased +
            DateTime.monday;
      },
    );

    return TaskRecurrence.weekly(
      shifted,
    );
  }

  LifeTask _copyTaskForMove({
    required LifeTask source,
    required DateTime date,
    required int startTimeMinutes,
    int? durationMinutes,
    TaskRecurrence? recurrence,
  }) {
    return source.copyWith(
      scheduledDate:
          _dateOnly(date),
      startTimeMinutes:
          startTimeMinutes,
      durationMinutes:
          durationMinutes,
      allDay:
          false,
      recurrence:
          recurrence,
    );
  }


  Future<void> _moveOccurrenceInWeek(
    TaskOccurrence occurrence,
    DateTime targetDate,
    int targetStartMinutes,
  ) async {
    final effectiveTask =
        occurrence.displayTask;

    final currentStart =
        effectiveTask.startTimeMinutes;

    if (currentStart == null ||
        effectiveTask.allDay) {
      return;
    }

    final normalizedTargetDate =
        _dateOnly(
      targetDate,
    );

    final sameDate =
        occurrence.date.year ==
                normalizedTargetDate.year &&
            occurrence.date.month ==
                normalizedTargetDate.month &&
            occurrence.date.day ==
                normalizedTargetDate.day;

    if (sameDate &&
        currentStart ==
            targetStartMinutes) {
      return;
    }

    if (!occurrence.isRecurring) {
      final moved =
          _copyTaskForMove(
        source:
            effectiveTask,
        date:
            normalizedTargetDate,
        startTimeMinutes:
            targetStartMinutes,
      );

      await widget.taskRepository
          .updateTask(
        moved,
      );

      if (!mounted) {
        return;
      }

      _updateCalendarState(() {
        _selectedDay =
            normalizedTargetDate;
        _focusedDay =
            normalizedTargetDate;
      });

      _showMoveConfirmation(
        normalizedTargetDate,
        targetStartMinutes,
      );
      return;
    }

    final scope =
        await TaskPrompts
            .chooseSeriesScope(
      context,
      action:
          TaskSeriesPromptAction.move,
    );

    if (!mounted ||
        scope == null) {
      return;
    }

    if (scope ==
        TaskSeriesScope.occurrence) {
      final editedOccurrence =
          _copyTaskForMove(
        source:
            effectiveTask,
        date:
            normalizedTargetDate,
        startTimeMinutes:
            targetStartMinutes,
        recurrence:
            occurrence.task.recurrence,
      );

      await widget.taskRepository
          .saveOccurrenceOverride(
        occurrence:
            occurrence,
        editedTask:
            editedOccurrence,
      );
    } else {
      final series =
          occurrence.task;

      final startDate =
          series.scheduledDate;

      if (startDate == null) {
        return;
      }

      final dayDelta =
          CivilDate.differenceInDays(
        occurrence.date,
        normalizedTargetDate,
      );

      final shiftedRecurrence =
          _shiftRecurrence(
        series,
        dayDelta,
      );

      final movedSeries =
          _copyTaskForMove(
        source:
            series,
        date:
            CivilDate.addDays(
          startDate,
          dayDelta,
        ),
        startTimeMinutes:
            targetStartMinutes,
        recurrence:
            shiftedRecurrence,
      );

      await widget.taskRepository
          .updateTask(
        movedSeries,
      );

      if (occurrence.hasOverride) {
        await widget.taskRepository
            .clearOccurrenceOverride(
          occurrence,
        );
      }
    }

    if (!mounted) {
      return;
    }

    _updateCalendarState(() {
      _selectedDay =
          normalizedTargetDate;
      _focusedDay =
          normalizedTargetDate;
    });

    _showMoveConfirmation(
      normalizedTargetDate,
      targetStartMinutes,
    );
  }

  Future<void> _resizeOccurrenceInWeek(
    TaskOccurrence occurrence,
    int targetDurationMinutes,
  ) async {
    final effectiveTask =
        occurrence.displayTask;

    final currentStart =
        effectiveTask.startTimeMinutes;

    if (currentStart == null ||
        effectiveTask.allDay) {
      return;
    }

    final normalizedDuration =
        math.max(
      15,
      targetDurationMinutes,
    ).toInt();

    final currentDuration =
        effectiveTask.durationMinutes ??
        30;

    if (currentDuration ==
        normalizedDuration) {
      return;
    }

    if (!occurrence.isRecurring) {
      final resized =
          _copyTaskForMove(
        source:
            effectiveTask,
        date:
            occurrence.date,
        startTimeMinutes:
            currentStart,
        durationMinutes:
            normalizedDuration,
      );

      await widget.taskRepository
          .updateTask(
        resized,
      );

      if (!mounted) {
        return;
      }

      _showResizeConfirmation(
        normalizedDuration,
      );
      return;
    }

    final scope =
        await TaskPrompts
            .chooseSeriesScope(
      context,
      action:
          TaskSeriesPromptAction.resize,
    );

    if (!mounted ||
        scope == null) {
      return;
    }

    if (scope ==
        TaskSeriesScope.occurrence) {
      final editedOccurrence =
          _copyTaskForMove(
        source:
            effectiveTask,
        date:
            occurrence.date,
        startTimeMinutes:
            currentStart,
        durationMinutes:
            normalizedDuration,
        recurrence:
            occurrence.task.recurrence,
      );

      await widget.taskRepository
          .saveOccurrenceOverride(
        occurrence:
            occurrence,
        editedTask:
            editedOccurrence,
      );
    } else {
      final series =
          occurrence.task;

      final seriesDate =
          series.scheduledDate;
      final seriesStart =
          series.startTimeMinutes;

      if (seriesDate == null ||
          seriesStart == null) {
        return;
      }

      final resizedSeries =
          _copyTaskForMove(
        source:
            series,
        date:
            seriesDate,
        startTimeMinutes:
            seriesStart,
        durationMinutes:
            normalizedDuration,
        recurrence:
            series.recurrence,
      );

      await widget.taskRepository
          .updateTask(
        resizedSeries,
      );
    }

    if (!mounted) {
      return;
    }

    _showResizeConfirmation(
      normalizedDuration,
    );
  }

  void _showResizeConfirmation(
    int durationMinutes,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        duration:
            const Duration(
          milliseconds:
              1400,
        ),
        content:
            Text(
          'Durata aggiornata: ${_durationLabel(durationMinutes)}',
        ),
      ),
    );
  }

  void _showMoveConfirmation(
    DateTime date,
    int startTimeMinutes,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        duration:
            const Duration(
          milliseconds:
              1600,
        ),
        content:
            Text(
          'Spostata a ${_selectedDateLabel(date)}, '
          '${_clockLabel(startTimeMinutes)}',
        ),
      ),
    );
  }

  void _startWeekPinchIfPossible({
    required double renderedDayWidth,
    required double fittedDayWidth,
  }) {
    if (_weekPointers.length != 2) {
      return;
    }

    final positions =
        _weekPointers.values.toList();

    final first =
        positions[0];
    final second =
        positions[1];

    _weekPinchStartHorizontalSpan =
        (first.dx - second.dx).abs();
    _weekPinchStartVerticalSpan =
        (first.dy - second.dy).abs();

    _weekPinchStartHourHeight =
        _weekHourHeight;
    _weekPinchStartDayWidth =
        renderedDayWidth;
    _weekPinchFittedDayWidth =
        fittedDayWidth;

    _weekPinchAxis = null;

    final focalX =
        (first.dx + second.dx) / 2;
    final focalY =
        (first.dy + second.dy) / 2;

    final verticalScrollOffset =
        _weekVerticalController.hasClients
            ? _weekVerticalController.offset
            : 0.0;

    final gridY =
        math.max(
      0.0,
      verticalScrollOffset +
          focalY -
          _CalendarPageState._weekGridTopPadding,
    ).toDouble();

    _weekPinchAnchorMinutes =
        gridY /
            _weekHourHeight *
            60;

    final horizontalScrollOffset =
        _weekHorizontalController.hasClients
            ? _weekHorizontalController.offset
            : 0.0;

    _weekPinchViewportFocalX =
        focalX -
            horizontalScrollOffset;

    _weekPinchAnchorDayPosition =
        ((focalX -
                    _CalendarPageState._weekGutterWidth) /
                renderedDayWidth)
            .clamp(
              0.0,
              7.0,
            )
            .toDouble();

    if (!_weekPinching) {
      _updateCalendarState(() {
        _weekPinching = true;
      });
    }
  }

  void _handleWeekPointerDown(
    PointerDownEvent event, {
    required double renderedDayWidth,
    required double fittedDayWidth,
  }) {
    _weekPointers[event.pointer] =
        event.localPosition;

    if (_weekPointers.length == 2) {
      _startWeekPinchIfPossible(
        renderedDayWidth:
            renderedDayWidth,
        fittedDayWidth:
            fittedDayWidth,
      );
    }
  }

  void _handleWeekPointerMove(
    PointerMoveEvent event,
  ) {
    if (!_weekPointers.containsKey(
      event.pointer,
    )) {
      return;
    }

    _weekPointers[event.pointer] =
        event.localPosition;

    if (_weekPointers.length != 2 ||
        !_weekPinching) {
      return;
    }

    final positions =
        _weekPointers.values.toList();

    final first =
        positions[0];
    final second =
        positions[1];

    final currentHorizontalSpan =
        (first.dx - second.dx).abs();
    final currentVerticalSpan =
        (first.dy - second.dy).abs();

    final horizontalDelta =
        currentHorizontalSpan -
            _weekPinchStartHorizontalSpan;

    final verticalDelta =
        currentVerticalSpan -
            _weekPinchStartVerticalSpan;

    if (_weekPinchAxis == null) {
      final horizontalIntent =
          horizontalDelta.abs();
      final verticalIntent =
          verticalDelta.abs();

      // Piccola dead-zone: evita che il normale tremolio delle dita
      // scelga subito un asse.
      if (math.max(
            horizontalIntent,
            verticalIntent,
          ) <
          8) {
        return;
      }

      _weekPinchAxis =
          horizontalIntent >
                  verticalIntent
              ? _WeekPinchAxis.horizontal
              : _WeekPinchAxis.vertical;
    }

    switch (_weekPinchAxis!) {
      case _WeekPinchAxis.vertical:
        final nextHourHeight =
            (_weekPinchStartHourHeight *
                    (1 +
                        verticalDelta /
                            140))
                .clamp(
                  _CalendarPageState._weekMinHourHeight,
                  _CalendarPageState._weekMaxHourHeight,
                )
                .toDouble();

        if ((nextHourHeight -
                    _weekHourHeight)
                .abs() <
            0.05) {
          return;
        }

        final focalY =
            (first.dy + second.dy) / 2;

        final anchorMinutes =
            _weekPinchAnchorMinutes;

        if (anchorMinutes == null) {
          return;
        }

        _updateCalendarState(() {
          _weekHourHeight =
              nextHourHeight;
        });

        WidgetsBinding.instance
            .addPostFrameCallback(
          (_) {
            if (!mounted ||
                !_weekVerticalController
                    .hasClients) {
              return;
            }

            final targetOffset =
                _CalendarPageState._weekGridTopPadding +
                    anchorMinutes /
                        60 *
                        nextHourHeight -
                    focalY;

            final clampedOffset =
                targetOffset
                    .clamp(
                      0.0,
                      _weekVerticalController
                          .position
                          .maxScrollExtent,
                    )
                    .toDouble();

            _weekVerticalController
                .jumpTo(
              clampedOffset,
            );
          },
        );
        break;

      case _WeekPinchAxis.horizontal:
        // Finché la settimana è più larga del viewport manteniamo la
        // sensibilità attuale. Quando i sette giorni sono già tutti visibili,
        // il pinch continua nell'overview con un controllo un po' più fine.
        final horizontalSensitivity =
            _weekPinchStartDayWidth <=
                    _weekPinchFittedDayWidth + 0.5
                ? 190.0
                : 140.0;

        final nextStoredDayWidth =
            (_weekPinchStartDayWidth *
                    (1 +
                        horizontalDelta /
                            horizontalSensitivity))
                .clamp(
                  _CalendarPageState._weekMinDayWidth,
                  _CalendarPageState._weekMaxDayWidth,
                )
                .toDouble();

        // Non imponiamo più fittedDayWidth come minimo renderizzato:
        // sotto quella soglia si entra davvero nella modalità overview.
        final nextRenderedDayWidth =
            nextStoredDayWidth;

        if ((nextStoredDayWidth -
                    _weekDayWidth)
                .abs() <
            0.05) {
          return;
        }

        final anchorDayPosition =
            _weekPinchAnchorDayPosition;
        final viewportFocalX =
            _weekPinchViewportFocalX;

        if (anchorDayPosition == null ||
            viewportFocalX == null) {
          return;
        }

        _updateCalendarState(() {
          _weekDayWidth =
              nextStoredDayWidth;
        });

        WidgetsBinding.instance
            .addPostFrameCallback(
          (_) {
            if (!mounted ||
                !_weekHorizontalController
                    .hasClients) {
              return;
            }

            final targetOffset =
                _CalendarPageState._weekGutterWidth +
                    anchorDayPosition *
                        nextRenderedDayWidth -
                    viewportFocalX;

            final clampedOffset =
                targetOffset
                    .clamp(
                      0.0,
                      _weekHorizontalController
                          .position
                          .maxScrollExtent,
                    )
                    .toDouble();

            _weekHorizontalController
                .jumpTo(
              clampedOffset,
            );
          },
        );
        break;
    }
  }

  void _handleWeekPointerEnd(
    PointerEvent event, {
    required double renderedDayWidth,
    required double fittedDayWidth,
  }) {
    _weekPointers.remove(
      event.pointer,
    );

    _weekPinchAxis = null;
    _weekPinchAnchorMinutes = null;
    _weekPinchAnchorDayPosition = null;
    _weekPinchViewportFocalX = null;

    if (_weekPinching) {
      _updateCalendarState(() {
        _weekPinching = false;
      });
    }

    if (_weekPointers.length == 2) {
      _startWeekPinchIfPossible(
        renderedDayWidth:
            renderedDayWidth,
        fittedDayWidth:
            fittedDayWidth,
      );
    }
  }
}
