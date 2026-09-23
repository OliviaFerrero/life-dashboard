part of 'calendar_page.dart';

// Vista settimanale del Calendario: interazioni, drag, resize, zoom e widget
// dedicati alla griglia Week. È un part della stessa libreria per mantenere
// invariata la visibilità dei membri privati durante questo refactor.
enum _RecurringMoveScope {
  occurrence,
  series,
}

enum _RecurringActionScope {
  occurrence,
  series,
}

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

extension _CalendarWeekViewExtension on _CalendarPageState {
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

    return LifeTask(
      id:
          occurrence.task.id,
      title:
          effective.title,
      description:
          effective.description,
      scheduledDate:
          occurrence.date,
      startTimeMinutes:
          effective.startTimeMinutes,
      durationMinutes:
          effective.durationMinutes,
      categoryId:
          effective.categoryId,
      allDay:
          effective.allDay,
      priority:
          effective.priority,
      recurrence:
          occurrence.task.recurrence,
      subtasks:
          occurrence.subtasks,
      isCompleted:
          occurrence.isCompleted,
    );
  }

  Future<_RecurringActionScope?>
      _showRecurringActionScope({
    required String title,
    bool destructive = false,
  }) {
    return showModalBottomSheet<
        _RecurringActionScope>(
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
                  title.toUpperCase(),
                  style:
                      Theme.of(
                    sheetContext,
                  )
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            color:
                                colorScheme
                                    .onSurfaceVariant,
                            fontWeight:
                                FontWeight.w800,
                            letterSpacing:
                                1,
                          ),
                ),
                const SizedBox(
                  height:
                      8,
                ),
                _WeekActionSheetRow(
                  icon:
                      Icons
                          .event_outlined,
                  label:
                      'Solo questa occorrenza',
                  isDestructive:
                      destructive,
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _RecurringActionScope
                          .occurrence,
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
                      Icons.repeat,
                  label:
                      'Tutta la serie',
                  isDestructive:
                      destructive,
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _RecurringActionScope
                          .series,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmWeekDelete({
    required String title,
    required String message,
  }) async {
    final confirmed =
        await showDialog<bool>(
      context:
          context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title:
              Text(
            title,
          ),
          content:
              Text(
            message,
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text(
                'Annulla',
              ),
            ),
            FilledButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
                  const Text(
                'Elimina',
              ),
            ),
          ],
        );
      },
    );

    return confirmed ==
        true;
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
        await widget.taskRepository
            .deleteTask(
          occurrence.task.id,
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
        await _showRecurringActionScope(
      title:
          'Modifica',
    );

    if (!mounted ||
        scope == null) {
      return;
    }

    if (scope ==
        _RecurringActionScope.occurrence) {
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
      await widget.taskRepository
          .deleteTask(
        occurrence.task.id,
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
          await _confirmWeekDelete(
        title:
            'Eliminare attività?',
        message:
            'Vuoi eliminare "${occurrence.displayTask.title}"?',
      );

      if (!confirmed) {
        return;
      }

      await widget.taskRepository
          .deleteTask(
        occurrence.task.id,
      );
      return;
    }

    final scope =
        await _showRecurringActionScope(
      title:
          'Elimina',
      destructive:
          true,
    );

    if (!mounted ||
        scope == null) {
      return;
    }

    if (scope ==
        _RecurringActionScope.occurrence) {
      final confirmed =
          await _confirmWeekDelete(
        title:
            'Eliminare questa occorrenza?',
        message:
            'Verrà rimossa solo questa data. '
            'Le altre occorrenze della serie resteranno invariate.',
      );

      if (!confirmed) {
        return;
      }

      await widget.taskRepository
          .deleteOccurrence(
        occurrence,
      );
      return;
    }

    final confirmed =
        await _confirmWeekDelete(
      title:
          'Eliminare serie?',
      message:
          'Vuoi eliminare tutta la serie '
          '"${occurrence.task.title}"?',
    );

    if (!confirmed) {
      return;
    }

    await widget.taskRepository
        .deleteTask(
      occurrence.task.id,
    );
  }

  LifeTask _taskTemplateFromOccurrence(
    TaskOccurrence occurrence,
  ) {
    final effective = occurrence.displayTask;

    // Copia/Duplica lavorano sull'occorrenza concreta visibile.
    // Se l'originale appartiene a una serie, il duplicato nasce come
    // attività singola: evita di creare accidentalmente una seconda serie.
    return LifeTask(
      id: effective.id,
      title: effective.title,
      description: effective.description,
      scheduledDate: occurrence.date,
      startTimeMinutes: effective.allDay
          ? null
          : effective.startTimeMinutes,
      durationMinutes: effective.durationMinutes,
      categoryId: effective.categoryId,
      allDay: effective.allDay,
      priority: effective.priority,
      recurrence: const TaskRecurrence.none(),
      subtasks: occurrence.subtasks,
      isCompleted: false,
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

    return LifeTask(
      id:
          seed.toString(),
      title:
          source.title,
      description:
          source.description,
      scheduledDate:
          _dateOnly(date),
      startTimeMinutes:
          startTimeMinutes,
      durationMinutes:
          source.durationMinutes,
      categoryId:
          source.categoryId,
      allDay:
          false,
      priority:
          source.priority,
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
    return LifeTask(
      id:
          source.id,
      title:
          source.title,
      description:
          source.description,
      scheduledDate:
          _dateOnly(date),
      startTimeMinutes:
          startTimeMinutes,
      durationMinutes:
          durationMinutes ??
          source.durationMinutes,
      categoryId:
          source.categoryId,
      allDay:
          false,
      priority:
          source.priority,
      recurrence:
          recurrence ??
          source.recurrence,
      subtasks:
          source.subtasks,
      isCompleted:
          source.isCompleted,
    );
  }

  Future<_RecurringMoveScope?>
      _showRecurringMoveScope() {
    return showModalBottomSheet<
        _RecurringMoveScope>(
      context:
          context,
      backgroundColor:
          Colors.transparent,
      barrierColor:
          Colors.black.withValues(
        alpha: 0.28,
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
                  'SPOSTA ATTIVITÀ',
                  style:
                      Theme.of(
                    sheetContext,
                  )
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            color:
                                colorScheme
                                    .onSurfaceVariant,
                            fontWeight:
                                FontWeight.w800,
                            letterSpacing:
                                1,
                          ),
                ),
                const SizedBox(
                  height:
                      8,
                ),
                _MoveScopeRow(
                  icon:
                      Icons
                          .event_outlined,
                  title:
                      'Solo questa occorrenza',
                  subtitle:
                      'Sposta soltanto questo evento.',
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _RecurringMoveScope
                          .occurrence,
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
                _MoveScopeRow(
                  icon:
                      Icons
                          .repeat,
                  title:
                      'Tutta la serie',
                  subtitle:
                      'Sposta orario e giorni della serie.',
                  onTap:
                      () {
                    Navigator.pop(
                      sheetContext,
                      _RecurringMoveScope
                          .series,
                    );
                  },
                ),
                const SizedBox(
                  height:
                      4,
                ),
                SizedBox(
                  width:
                      double.infinity,
                  child:
                      TextButton(
                    onPressed:
                        () {
                      Navigator.pop(
                        sheetContext,
                      );
                    },
                    child:
                        const Text(
                      'Annulla',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        await _showRecurringMoveScope();

    if (!mounted ||
        scope == null) {
      return;
    }

    if (scope ==
        _RecurringMoveScope.occurrence) {
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
          normalizedTargetDate
              .difference(
                occurrence.date,
              )
              .inDays;

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
            startDate.add(
          Duration(
            days:
                dayDelta,
          ),
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
        await _showRecurringActionScope(
      title:
          'Modifica durata',
    );

    if (!mounted ||
        scope == null) {
      return;
    }

    if (scope ==
        _RecurringActionScope.occurrence) {
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
        final nextStoredDayWidth =
            (_weekPinchStartDayWidth *
                    (1 +
                        horizontalDelta /
                            140))
                .clamp(
                  _CalendarPageState._weekMinDayWidth,
                  _CalendarPageState._weekMaxDayWidth,
                )
                .toDouble();

        final nextRenderedDayWidth =
            math.max(
          _weekPinchFittedDayWidth,
          nextStoredDayWidth,
        ).toDouble();

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

  Widget _buildWeekView(
    BuildContext context,
    List<TaskOccurrence> occurrences,
    Map<String, TaskCategory> categoryMap,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final days =
        _weekDays();

    final untimedByDay =
        <int, List<TaskOccurrence>>{
      for (var i = 0; i < 7; i++)
        i: <TaskOccurrence>[],
    };

    final timedSegmentsByDay =
        <int, List<_WeekTimedSegment>>{
      for (var i = 0; i < 7; i++)
        i: <_WeekTimedSegment>[],
    };

    for (final occurrence
        in occurrences) {
      final task =
          occurrence.displayTask;

      if (task.allDay ||
          task.startTimeMinutes == null) {
        final dayIndex =
            occurrence.date
                .difference(
                  days.first,
                )
                .inDays;

        if (dayIndex >= 0 &&
            dayIndex <= 6) {
          untimedByDay[
                  dayIndex]!
              .add(
            occurrence,
          );
        }

        continue;
      }

      final actualStart =
          occurrence.timedStart;

      if (actualStart == null) {
        continue;
      }

      final actualEnd =
          occurrence.timedEnd;

      for (var dayIndex = 0;
          dayIndex < 7;
          dayIndex++) {
        final dayStart =
            days[dayIndex];
        final dayEnd =
            dayStart.add(
          const Duration(days: 1),
        );

        if (!occurrence.overlapsWindow(
          dayStart,
          dayEnd,
        )) {
          continue;
        }

        final visibleStart =
            occurrence.visibleStartInWindow(
                  dayStart,
                  dayEnd,
                ) ??
                actualStart;

        DateTime visibleEnd;

        if (actualEnd == null) {
          final provisional =
              visibleStart.add(
            const Duration(
              minutes:
                  30,
            ),
          );

          visibleEnd =
              provisional.isAfter(
            dayEnd,
          )
                  ? dayEnd
                  : provisional;
        } else {
          visibleEnd =
              occurrence.visibleEndInWindow(
                    dayStart,
                    dayEnd,
                  ) ??
                  actualEnd;
        }

        final startMinute =
            visibleStart
                .difference(
                  dayStart,
                )
                .inMinutes
                .clamp(
                  0,
                  24 * 60,
                )
                .toInt();

        final endMinute =
            visibleEnd
                .difference(
                  dayStart,
                )
                .inMinutes
                .clamp(
                  0,
                  24 * 60,
                )
                .toInt();

        if (endMinute <=
            startMinute) {
          continue;
        }

        timedSegmentsByDay[
                dayIndex]!
            .add(
          _WeekTimedSegment(
            occurrence:
                occurrence,
            startMinute:
                startMinute,
            endMinute:
                endMinute,
            continuesFromPrevious:
                actualStart.isBefore(
              dayStart,
            ),
            continuesAfter:
                actualEnd != null &&
                actualEnd.isAfter(
                  dayEnd,
                ),
          ),
        );
      }
    }

    final maxUntimed =
        untimedByDay.values
            .fold<int>(
      0,
      (
        currentMax,
        dayItems,
      ) =>
          currentMax >
                  dayItems.length
              ? currentMax
              : dayItems.length,
    );

    final hasUntimed =
        maxUntimed >
        0;

    final untimedScale =
        (_weekHourHeight /
                _CalendarPageState._weekDefaultHourHeight)
            .clamp(
              0.65,
              1.35,
            )
            .toDouble();

    final untimedChipHeight =
        (28.0 *
                untimedScale)
            .clamp(
              22.0,
              34.0,
            )
            .toDouble();

    final untimedGap =
        (5.0 *
                untimedScale)
            .clamp(
              3.0,
              6.0,
            )
            .toDouble();

    final untimedVerticalPadding =
        (6.0 *
                untimedScale)
            .clamp(
              4.0,
              8.0,
            )
            .toDouble();

    final untimedOverlayHeight =
        math.min(
      176.0 *
          untimedScale,
      math.max(
        46.0,
        untimedVerticalPadding *
                2 +
            maxUntimed *
                untimedChipHeight +
            math.max(
                  0,
                  maxUntimed - 1,
                ) *
                untimedGap,
      ),
    ).toDouble();

    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {
        final viewportWidth =
            constraints.maxWidth;

        final fittedDayWidth =
            math.max(
          _CalendarPageState._weekMinDayWidth,
          (viewportWidth -
                  _CalendarPageState._weekGutterWidth) /
              7,
        ).toDouble();

        final dayWidth =
            math.max(
          fittedDayWidth,
          _weekDayWidth,
        ).toDouble();

        final totalWidth =
            _CalendarPageState._weekGutterWidth +
            dayWidth *
                7;

        return Stack(
          children: [
  SingleChildScrollView(
            controller:
                _weekHorizontalController,
            physics:
                _weekPinching
                    ? const NeverScrollableScrollPhysics()
                    : null,
            scrollDirection:
                Axis.horizontal,
            child:
                Padding(
              padding:
                  const EdgeInsets.only(
                right:
                    16,
              ),
              child:
                  SizedBox(
                width:
                    totalWidth,
                height:
                    constraints.maxHeight,
                child:
                    Column(
                children: [
                  _WeekDayHeader(
                    days:
                        days,
                    selectedDay:
                        _selectedDay,
                    gutterWidth:
                        _CalendarPageState._weekGutterWidth,
                    dayWidth:
                        dayWidth,
                    collapsed:
                        _weekHeaderCollapsed,
                    untimedExpanded:
                        _weekUntimedExpanded,
                    untimedByDay:
                        untimedByDay,
                    categoryMap:
                        categoryMap,
                    onVerticalDragUpdate:
                        _handleWeekHeaderDragUpdate,
                    onVerticalDragEnd:
                        _handleWeekHeaderDragEnd,
                    onUntimedToggle:
                        _toggleWeekUntimed,
                    onDaySelected:
                        (day) {
                      _updateCalendarState(() {
                        _selectedDay =
                            day;
                        _focusedDay =
                            day;
                      });
                    },
                  ),
                  Expanded(
                    child:
                        Stack(
                      children: [
                        Positioned.fill(
                          child:
                              Listener(
                            behavior:
                                HitTestBehavior.translucent,
                            onPointerDown:
                                (event) {
                              _handleWeekPointerDown(
                                event,
                                renderedDayWidth:
                                    dayWidth,
                                fittedDayWidth:
                                    fittedDayWidth,
                              );
                            },
                            onPointerMove:
                                _handleWeekPointerMove,
                            onPointerUp:
                                (event) {
                              _handleWeekPointerEnd(
                                event,
                                renderedDayWidth:
                                    dayWidth,
                                fittedDayWidth:
                                    fittedDayWidth,
                              );
                            },
                            onPointerCancel:
                                (event) {
                              _handleWeekPointerEnd(
                                event,
                                renderedDayWidth:
                                    dayWidth,
                                fittedDayWidth:
                                    fittedDayWidth,
                              );
                            },
                            child:
                                SingleChildScrollView(
                              controller:
                                  _weekVerticalController,
                              physics:
                                  _weekPinching
                                      ? const NeverScrollableScrollPhysics()
                                      : null,
                              child:
                                  Padding(
                                padding:
                                    const EdgeInsets.only(
                                  top:
                                      _CalendarPageState._weekGridTopPadding,
                                  bottom:
                                      _CalendarPageState._weekGridBottomPadding,
                                ),
                                child:
                                    _WeekHourlyGrid(
                                  days:
                                      days,
                                  selectedDay:
                                      _selectedDay,
                                  timedByDay:
                                      timedSegmentsByDay,
                                  categoryMap:
                                      categoryMap,
                                  hourHeight:
                                      _weekHourHeight,
                                  gutterWidth:
                                      _CalendarPageState._weekGutterWidth,
                                  dayWidth:
                                      dayWidth,
                                  verticalScrollController:
                                      _weekVerticalController,
                                  horizontalScrollController:
                                      _weekHorizontalController,
                                  viewportContext:
                                      context,
                                  onOpen:
                                      _openTaskDetail,
                                  onMove:
                                      _moveOccurrenceInWeek,
                                  onResize:
                                      _resizeOccurrenceInWeek,
                                  onActions:
                                      _showOccurrenceActions,
                                  onEmptySlotLongPress:
                                      _showWeekEmptySlotActions,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (hasUntimed &&
                            _weekUntimedExpanded)
                          Positioned(
                            left:
                                0,
                            right:
                                0,
                            top:
                                0,
                            height:
                                untimedOverlayHeight,
                            child:
                                _WeekUntimedOverlay(
                              gutterWidth:
                                  _CalendarPageState._weekGutterWidth,
                              dayWidth:
                                  dayWidth,
                              chipHeight:
                                  untimedChipHeight,
                              itemGap:
                                  untimedGap,
                              verticalPadding:
                                  untimedVerticalPadding,
                              untimedByDay:
                                  untimedByDay,
                              categoryMap:
                                  categoryMap,
                              onOpen:
                                  _openTaskDetail,
                              onActions:
                                  _showOccurrenceActions,
                              onClose:
                                  _closeWeekUntimed,
                              backgroundColor:
                                  colorScheme
                                      .surfaceContainerHigh
                                      .withValues(
                                alpha:
                                    0.97,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
            Positioned(
              left:
                  0,
              top:
                  0,
              bottom:
                  0,
              width:
                  _CalendarPageState._weekGutterWidth,
              child:
                  _WeekPinnedGutter(
                width:
                    _CalendarPageState._weekGutterWidth,
                hourHeight:
                    _weekHourHeight,
                gridTopPadding:
                    _CalendarPageState._weekGridTopPadding,
                verticalController:
                    _weekVerticalController,
                untimedExpanded:
                    hasUntimed &&
                    _weekUntimedExpanded,
                untimedOverlayHeight:
                    untimedOverlayHeight,
                onCloseUntimed:
                    _closeWeekUntimed,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WeekActionSheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _WeekActionSheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final color =
        isDestructive
            ? colorScheme.error
            : colorScheme.onSurface;

    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical:
                15,
          ),
          child:
              Row(
            children: [
              SizedBox(
                width:
                    32,
                child:
                    Icon(
                  icon,
                  size:
                      20,
                  color:
                      color,
                ),
              ),
              const SizedBox(
                width:
                    12,
              ),
              Expanded(
                child:
                    Text(
                  label,
                  style:
                      Theme.of(
                    context,
                  )
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            color:
                                color,
                            fontWeight:
                                FontWeight.w600,
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

class _MoveScopeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoveScopeRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical:
                14,
          ),
          child:
              Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              SizedBox(
                width:
                    32,
                child:
                    Icon(
                  icon,
                  size:
                      20,
                  color:
                      colorScheme.primary,
                ),
              ),
              const SizedBox(
                width:
                    12,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          Theme.of(
                        context,
                      )
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                    ),
                    const SizedBox(
                      height:
                          3,
                    ),
                    Text(
                      subtitle,
                      style:
                          Theme.of(
                        context,
                      )
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    colorScheme
                                        .onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekPinnedGutter extends StatelessWidget {
  final double width;
  final double hourHeight;
  final double gridTopPadding;
  final ScrollController verticalController;
  final bool untimedExpanded;
  final double untimedOverlayHeight;
  final VoidCallback onCloseUntimed;

  const _WeekPinnedGutter({
    required this.width,
    required this.hourHeight,
    required this.gridTopPadding,
    required this.verticalController,
    required this.untimedExpanded,
    required this.untimedOverlayHeight,
    required this.onCloseUntimed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final backgroundColor =
        Theme.of(context).scaffoldBackgroundColor;

    return ColoredBox(
      color:
          backgroundColor,
      child:
          Column(
        children: [
          SizedBox(
            height:
                76,
            width:
                width,
          ),
          Expanded(
            child:
                Stack(
              children: [
                Positioned.fill(
                  child:
                      IgnorePointer(
                    child:
                        ColoredBox(
                      color:
                          backgroundColor,
                    ),
                  ),
                ),
                Positioned.fill(
                  child:
                      IgnorePointer(
                    child:
                        ClipRect(
                      child:
                          AnimatedBuilder(
                        animation:
                            verticalController,
                        builder:
                            (context, child) {
                          final offset =
                              verticalController.hasClients
                                  ? verticalController.offset
                                  : 0.0;

                          return Stack(
                            clipBehavior:
                                Clip.hardEdge,
                            children: [
                              for (var hour = 0;
                                  hour < 24;
                                  hour++)
                                Positioned(
                                  left:
                                      0,
                                  right:
                                      7,
                                  top:
                                      gridTopPadding +
                                          hour *
                                              hourHeight -
                                          8 -
                                          offset,
                                  child:
                                      Text(
                                    '${hour.toString().padLeft(2, '0')}:00',
                                    textAlign:
                                        TextAlign.right,
                                    style:
                                        Theme.of(
                                      context,
                                    )
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme
                                                      .onSurfaceVariant,
                                              fontWeight:
                                                  FontWeight.w500,
                                            ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (untimedExpanded)
                  Positioned(
                    left:
                        0,
                    right:
                        0,
                    top:
                        0,
                    height:
                        untimedOverlayHeight,
                    child:
                        Material(
                      color:
                          colorScheme
                              .surfaceContainerHigh
                              .withValues(
                        alpha:
                            0.97,
                      ),
                      elevation:
                          5,
                      shadowColor:
                          colorScheme.shadow.withValues(
                        alpha:
                            0.14,
                      ),
                      child:
                          Center(
                        child:
                            IconButton(
                          tooltip:
                              'Chiudi attività senza orario',
                          visualDensity:
                              VisualDensity.compact,
                          onPressed:
                              onCloseUntimed,
                          icon:
                              const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size:
                                19,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _WeekDayHeader extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selectedDay;
  final double gutterWidth;
  final double dayWidth;
  final bool collapsed;
  final bool untimedExpanded;
  final Map<int, List<TaskOccurrence>> untimedByDay;
  final Map<String, TaskCategory> categoryMap;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final ValueChanged<DateTime> onUntimedToggle;
  final ValueChanged<DateTime> onDaySelected;

  const _WeekDayHeader({
    required this.days,
    required this.selectedDay,
    required this.gutterWidth,
    required this.dayWidth,
    required this.collapsed,
    required this.untimedExpanded,
    required this.untimedByDay,
    required this.categoryMap,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onUntimedToggle,
    required this.onDaySelected,
  });

  bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  Color _indicatorColor(
    BuildContext context,
    TaskOccurrence occurrence,
  ) {
    final task =
        occurrence.displayTask;

    final category =
        task.categoryId == null
            ? null
            : categoryMap[
                task.categoryId];

    if (category == null) {
      return Theme.of(context)
          .colorScheme
          .onSurfaceVariant
          .withValues(
            alpha:
                0.72,
          );
    }

    return Color(
      category.colorValue,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final now =
        DateTime.now();

    final today =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    const shortWeekdays = [
      'LUN',
      'MAR',
      'MER',
      'GIO',
      'VEN',
      'SAB',
      'DOM',
    ];

    return GestureDetector(
      behavior:
          HitTestBehavior.translucent,
      onVerticalDragUpdate:
          onVerticalDragUpdate,
      onVerticalDragEnd:
          onVerticalDragEnd,
      child:
          SizedBox(
        height:
            76,
        child:
            Row(
          children: [
            SizedBox(
              width:
                  gutterWidth,
              child:
                  Center(
                child:
                    Icon(
                  collapsed
                      ? Icons
                          .keyboard_arrow_down_rounded
                      : Icons
                          .keyboard_arrow_up_rounded,
                  size:
                      18,
                  color:
                      colorScheme
                          .onSurfaceVariant
                          .withValues(
                    alpha:
                        0.65,
                  ),
                ),
              ),
            ),
            for (var i = 0;
                i < days.length;
                i++)
              SizedBox(
                width:
                    dayWidth,
                child:
                    Column(
                  children: [
                    Expanded(
                      child:
                          Material(
                        color:
                            Colors.transparent,
                        child:
                            InkWell(
                          onTap:
                              () {
                            onDaySelected(
                              days[i],
                            );
                          },
                          child:
                              Padding(
                            padding:
                                const EdgeInsets.only(
                              top:
                                  7,
                            ),
                            child:
                                Column(
                              children: [
                                Text(
                                  shortWeekdays[i],
                                  style:
                                      Theme.of(
                                    context,
                                  )
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color:
                                                colorScheme
                                                    .onSurfaceVariant,
                                            fontWeight:
                                                FontWeight.w700,
                                            letterSpacing:
                                                0.65,
                                          ),
                                ),
                                const SizedBox(
                                  height:
                                      4,
                                ),
                                Container(
                                  width:
                                      30,
                                  height:
                                      30,
                                  alignment:
                                      Alignment.center,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        _sameDay(
                                      days[i],
                                      selectedDay,
                                    )
                                            ? colorScheme
                                                .primary
                                            : _sameDay(
                                                days[i],
                                                today,
                                              )
                                                ? colorScheme
                                                    .primaryContainer
                                                : Colors
                                                    .transparent,
                                    shape:
                                        BoxShape.circle,
                                  ),
                                  child:
                                      Text(
                                    '${days[i].day}',
                                    style:
                                        Theme.of(
                                      context,
                                    )
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color:
                                                  _sameDay(
                                                days[i],
                                                selectedDay,
                                              )
                                                      ? colorScheme
                                                          .onPrimary
                                                      : _sameDay(
                                                          days[i],
                                                          today,
                                                        )
                                                          ? colorScheme
                                                              .onPrimaryContainer
                                                          : colorScheme
                                                              .onSurface,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height:
                          16,
                      child:
                          Builder(
                        builder:
                            (context) {
                          final items =
                              untimedByDay[i] ??
                                  const <
                                      TaskOccurrence>[];

                          if (items.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final visible =
                              items
                                  .take(
                                    3,
                                  )
                                  .toList();

                          return Tooltip(
                            message:
                                items.length ==
                                        1
                                    ? '1 attività senza orario'
                                    : '${items.length} attività senza orario',
                            child:
                                Material(
                              color:
                                  Colors.transparent,
                              child:
                                  InkWell(
                                onTap:
                                    () {
                                  onUntimedToggle(
                                    days[i],
                                  );
                                },
                                borderRadius:
                                    BorderRadius.circular(
                                  999,
                                ),
                                child:
                                    Center(
                                  child:
                                      AnimatedContainer(
                                    duration:
                                        const Duration(
                                      milliseconds:
                                          160,
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal:
                                          5,
                                      vertical:
                                          3,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          untimedExpanded &&
                                                  _sameDay(
                                                    days[i],
                                                    selectedDay,
                                                  )
                                              ? colorScheme
                                                  .surfaceContainerHigh
                                              : Colors
                                                  .transparent,
                                      borderRadius:
                                          BorderRadius.circular(
                                        999,
                                      ),
                                    ),
                                    child:
                                        Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        for (var dotIndex =
                                                0;
                                            dotIndex <
                                                visible.length;
                                            dotIndex++) ...[
                                          Container(
                                            width:
                                                5,
                                            height:
                                                5,
                                            decoration:
                                                BoxDecoration(
                                              color:
                                                  _indicatorColor(
                                                context,
                                                visible[
                                                    dotIndex],
                                              ),
                                              shape:
                                                  BoxShape.circle,
                                            ),
                                          ),
                                          if (dotIndex !=
                                              visible.length -
                                                  1)
                                            const SizedBox(
                                              width:
                                                  3,
                                            ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekUntimedOverlay extends StatelessWidget {
  final double gutterWidth;
  final double dayWidth;
  final double chipHeight;
  final double itemGap;
  final double verticalPadding;
  final Map<int, List<TaskOccurrence>> untimedByDay;
  final Map<String, TaskCategory> categoryMap;
  final ValueChanged<TaskOccurrence> onOpen;
  final ValueChanged<TaskOccurrence> onActions;
  final VoidCallback onClose;
  final Color backgroundColor;

  const _WeekUntimedOverlay({
    required this.gutterWidth,
    required this.dayWidth,
    required this.chipHeight,
    required this.itemGap,
    required this.verticalPadding,
    required this.untimedByDay,
    required this.categoryMap,
    required this.onOpen,
    required this.onActions,
    required this.onClose,
    required this.backgroundColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color:
          backgroundColor,
      elevation:
          5,
      shadowColor:
          colorScheme.shadow.withValues(
        alpha:
            0.14,
      ),
      child:
          DecoratedBox(
        decoration:
            BoxDecoration(
          border:
              Border(
            top:
                BorderSide(
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha:
                    0.45,
              ),
            ),
            bottom:
                BorderSide(
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha:
                    0.75,
              ),
            ),
          ),
        ),
        child:
            Stack(
          children: [
            Positioned(
              left:
                  0,
              top:
                  0,
              bottom:
                  0,
              width:
                  gutterWidth,
              child:
                  Center(
                child:
                    IconButton(
                  tooltip:
                      'Chiudi attività senza orario',
                  visualDensity:
                      VisualDensity.compact,
                  onPressed:
                      onClose,
                  icon:
                      const Icon(
                    Icons
                        .keyboard_arrow_up_rounded,
                    size:
                        19,
                  ),
                ),
              ),
            ),
            for (var dayIndex =
                    0;
                dayIndex <
                    7;
                dayIndex++)
              Positioned(
                left:
                    gutterWidth +
                    dayIndex *
                        dayWidth,
                top:
                    0,
                bottom:
                    0,
                width:
                    dayWidth,
                child:
                    _UntimedDayLane(
                  occurrences:
                      untimedByDay[
                          dayIndex]!,
                  chipHeight:
                      chipHeight,
                  itemGap:
                      itemGap,
                  verticalPadding:
                      verticalPadding,
                  categoryMap:
                      categoryMap,
                  onOpen:
                      onOpen,
                  onActions:
                      onActions,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UntimedDayLane extends StatelessWidget {
  final List<TaskOccurrence> occurrences;
  final double chipHeight;
  final double itemGap;
  final double verticalPadding;
  final Map<String, TaskCategory> categoryMap;
  final ValueChanged<TaskOccurrence> onOpen;
  final ValueChanged<TaskOccurrence> onActions;

  const _UntimedDayLane({
    required this.occurrences,
    required this.chipHeight,
    required this.itemGap,
    required this.verticalPadding,
    required this.categoryMap,
    required this.onOpen,
    required this.onActions,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration:
          BoxDecoration(
        border:
            Border(
          left:
              BorderSide(
            color:
                colorScheme
                    .outlineVariant
                    .withValues(
              alpha:
                  0.45,
            ),
          ),
        ),
      ),
      child:
          ListView.separated(
        primary:
            false,
        padding:
            EdgeInsets.symmetric(
          horizontal:
              4,
          vertical:
              verticalPadding,
        ),
        itemCount:
            occurrences.length,
        separatorBuilder:
            (_, _) =>
                SizedBox(
          height:
              itemGap,
        ),
        itemBuilder:
            (
          context,
          index,
        ) {
          final occurrence =
              occurrences[
                  index];

          return SizedBox(
            height:
                chipHeight,
            child:
                _UntimedOccurrenceChip(
              occurrence:
                  occurrence,
              height:
                  chipHeight,
              categoryMap:
                  categoryMap,
              onTap:
                  () {
                onOpen(
                  occurrence,
                );
              },
              onLongPress:
                  () {
                onActions(
                  occurrence,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _UntimedOccurrenceChip extends StatelessWidget {
  final TaskOccurrence occurrence;
  final double height;
  final Map<String, TaskCategory> categoryMap;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _UntimedOccurrenceChip({
    required this.occurrence,
    required this.height,
    required this.categoryMap,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final task =
        occurrence.displayTask;

    final category =
        task.categoryId == null
            ? null
            : categoryMap[
                task.categoryId];

    final color =
        category == null
            ? colorScheme
                .onSurfaceVariant
            : Color(
                category.colorValue,
              );

    return Material(
      color:
          color.withValues(
        alpha:
            0.12,
      ),
      borderRadius:
          BorderRadius.circular(
        8,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        onLongPress:
            onLongPress,
        borderRadius:
            BorderRadius.circular(
          8,
        ),
        child:
            Padding(
          padding:
              EdgeInsets.symmetric(
            horizontal:
                height < 25
                    ? 4
                    : 6,
          ),
          child:
              Row(
            children: [
              Icon(
                category == null
                    ? task.allDay
                        ? Icons
                            .wb_sunny_outlined
                        : Icons
                            .schedule_outlined
                    : taskCategoryIcon(
                        category.iconKey,
                      ),
                size:
                    height < 25
                        ? 10
                        : 12,
                color:
                    color,
              ),
              SizedBox(
                width:
                    height < 25
                        ? 3
                        : 4,
              ),
              Expanded(
                child:
                    Text(
                  task.title,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      Theme.of(
                    context,
                  )
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color:
                                color,
                            fontSize:
                                height < 25
                                    ? 9
                                    : null,
                            fontWeight:
                                FontWeight.w700,
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


class _WeekOccurrenceBlock extends StatelessWidget {
  final LifeTask task;
  final TaskCategory? category;
  final Color accentColor;
  final Color priorityColor;
  final String timeText;
  final String? subtaskText;
  final double height;
  final double hourHeight;
  final int startTimeMinutes;
  final int initialDurationMinutes;
  final ScrollController verticalScrollController;
  final _WeekAutoScrollUpdate onAutoScrollUpdate;
  final VoidCallback onAutoScrollEnd;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Future<void> Function(int durationMinutes)? onResizeEnd;

  const _WeekOccurrenceBlock({
    required this.task,
    required this.category,
    required this.accentColor,
    required this.priorityColor,
    required this.timeText,
    required this.subtaskText,
    required this.height,
    required this.hourHeight,
    required this.startTimeMinutes,
    required this.initialDurationMinutes,
    required this.verticalScrollController,
    required this.onAutoScrollUpdate,
    required this.onAutoScrollEnd,
    required this.onTap,
    required this.onLongPress,
    required this.onResizeEnd,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final identityIcon =
        category == null
            ? Icons.circle_outlined
            : taskCategoryIcon(
                category!.iconKey,
              );

    return Material(
      color:
          accentColor.withValues(
        alpha:
            task.isCompleted
                ? 0.08
                : 0.15,
      ),
      borderRadius:
          BorderRadius.circular(
        9,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        onLongPress:
            onLongPress,
        borderRadius:
            BorderRadius.circular(
          9,
        ),
        child:
            Container(
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              9,
            ),
            border:
                Border.all(
              color:
                  accentColor.withValues(
                alpha:
                    0.48,
              ),
            ),
          ),
          child:
              LayoutBuilder(
            builder:
                (
              context,
              constraints,
            ) {
              final width =
                  constraints.maxWidth;

              final ultraNarrow =
                  width < 34;

              if (ultraNarrow) {
                return Center(
                  child:
                      Icon(
                    identityIcon,
                    size:
                        10,
                    color:
                        accentColor,
                  ),
                );
              }

              final compact =
                  width < 60;

              // I blocchi molto bassi (per esempio attività da 15/30 minuti)
              // hanno pochissimo spazio verticale. In quel caso passiamo a una
              // resa minimale: una sola riga di titolo, niente icona interna e
              // padding ridotto. Il resize handle resta sovrapposto in basso.
              final veryShort =
                  constraints.maxHeight < 40;

              final showTime =
                  !veryShort &&
                  width >= 68 &&
                  height >= 46;

              final showFooter =
                  width >= 78 &&
                  height >= 68 &&
                  (subtaskText !=
                          null ||
                      task.priority !=
                          TaskPriority
                              .normal);

              final titleStyle =
                  Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                        color:
                            accentColor,
                        fontSize:
                            veryShort ||
                                    compact
                                ? 8.5
                                : null,
                        fontWeight:
                            FontWeight.w800,
                        height:
                            1.05,
                        decoration:
                            task.isCompleted
                                ? TextDecoration
                                    .lineThrough
                                : null,
                      );

              final content =
                  Padding(
                padding:
                    EdgeInsets.fromLTRB(
                  compact
                      ? 3
                      : 5,
                  veryShort
                      ? 2
                      : 4,
                  compact
                      ? 3
                      : 4,
                  veryShort
                      ? 2
                      : onResizeEnd == null
                          ? 4
                          : 12,
                ),
                child:
                    ClipRect(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      if (veryShort ||
                          compact)
                        Text(
                          task.title,
                          maxLines:
                              veryShort
                                  ? 1
                                  : height >= 46
                                      ? 2
                                      : 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              titleStyle,
                        )
                      else
                        Row(
                          children: [
                            Icon(
                              identityIcon,
                              size:
                                  11,
                              color:
                                  accentColor,
                            ),
                            const SizedBox(
                              width:
                                  3,
                            ),
                            Expanded(
                              child:
                                  Text(
                                task.title,
                                maxLines:
                                    height >= 52
                                        ? 2
                                        : 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style:
                                    titleStyle,
                              ),
                            ),
                          ],
                        ),
                      if (showTime) ...[
                        const SizedBox(
                          height:
                              3,
                        ),
                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              FittedBox(
                            fit:
                                BoxFit.scaleDown,
                            alignment:
                                Alignment.centerLeft,
                            child:
                                Text(
                              timeText,
                              maxLines:
                                  1,
                              style:
                                  Theme.of(
                                context,
                              )
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color:
                                            colorScheme
                                                .onSurfaceVariant,
                                        fontSize:
                                            9,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                            ),
                          ),
                        ),
                      ],
                      if (showFooter) ...[
                        const Spacer(),
                        Row(
                          children: [
                            if (subtaskText !=
                                null) ...[
                              Icon(
                                Icons
                                    .checklist_rounded,
                                size:
                                    10,
                                color:
                                    accentColor,
                              ),
                              const SizedBox(
                                width:
                                    2,
                              ),
                              Flexible(
                                child:
                                    Text(
                                  subtaskText!,
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      Theme.of(
                                    context,
                                  )
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color:
                                                accentColor,
                                            fontSize:
                                                9,
                                            fontWeight:
                                                FontWeight.w700,
                                          ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Icon(
                              Icons
                                  .flag_outlined,
                              size:
                                  10,
                              color:
                                  priorityColor,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );

              if (onResizeEnd == null) {
                return content;
              }

              return Stack(
                clipBehavior:
                    Clip.none,
                children: [
                  Positioned.fill(
                    child:
                        content,
                  ),
                  Positioned(
                    left:
                        0,
                    right:
                        0,
                    bottom:
                        0,
                    height:
                        18,
                    child:
                        _WeekResizeHandle(
                      accentColor:
                          accentColor,
                      hourHeight:
                          hourHeight,
                      startTimeMinutes:
                          startTimeMinutes,
                      initialDurationMinutes:
                          initialDurationMinutes,
                      verticalScrollController:
                          verticalScrollController,
                      onAutoScrollUpdate:
                          onAutoScrollUpdate,
                      onAutoScrollEnd:
                          onAutoScrollEnd,
                      onResizeEnd:
                          onResizeEnd!,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


class _WeekResizeHandle extends StatefulWidget {
  final Color accentColor;
  final double hourHeight;
  final int startTimeMinutes;
  final int initialDurationMinutes;
  final ScrollController verticalScrollController;
  final _WeekAutoScrollUpdate onAutoScrollUpdate;
  final VoidCallback onAutoScrollEnd;
  final Future<void> Function(
    int durationMinutes,
  ) onResizeEnd;

  const _WeekResizeHandle({
    required this.accentColor,
    required this.hourHeight,
    required this.startTimeMinutes,
    required this.initialDurationMinutes,
    required this.verticalScrollController,
    required this.onAutoScrollUpdate,
    required this.onAutoScrollEnd,
    required this.onResizeEnd,
  });

  @override
  State<_WeekResizeHandle> createState() =>
      _WeekResizeHandleState();
}

class _WeekResizeHandleState
    extends State<_WeekResizeHandle> {
  double _dragDy = 0;
  double _initialVerticalScrollOffset = 0;
  bool _dragging = false;
  late int _previewDurationMinutes;

  @override
  void initState() {
    super.initState();
    _previewDurationMinutes =
        widget.initialDurationMinutes;
  }

  @override
  void didUpdateWidget(
    covariant _WeekResizeHandle oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (!_dragging &&
        oldWidget.initialDurationMinutes !=
            widget.initialDurationMinutes) {
      _previewDurationMinutes =
          widget.initialDurationMinutes;
    }
  }

  int _durationForDrag(
    double dragDy,
  ) {
    final rawDuration =
        widget.initialDurationMinutes +
        dragDy /
            widget.hourHeight *
            60;

    final snapped =
        (rawDuration / 15).round() *
        15;

    return math.max(
      15,
      snapped,
    ).toInt();
  }

  String _clockLabel(
    int minutes,
  ) {
    final normalized =
        minutes % (24 * 60);

    final hour =
        (normalized ~/ 60)
            .toString()
            .padLeft(
              2,
              '0',
            );

    final minute =
        (normalized % 60)
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$hour:$minute';
  }

  String _durationLabel(
    int minutes,
  ) {
    final hours =
        minutes ~/ 60;
    final remaining =
        minutes % 60;

    if (hours == 0) {
      return '$remaining min';
    }

    if (remaining == 0) {
      return hours == 1
          ? '1 h'
          : '$hours h';
    }

    return '$hours h $remaining min';
  }

  double _effectiveDragDy() {
    final currentScrollOffset =
        widget.verticalScrollController.hasClients
            ? widget.verticalScrollController.offset
            : _initialVerticalScrollOffset;

    return _dragDy +
        currentScrollOffset -
        _initialVerticalScrollOffset;
  }

  void _refreshPreviewDuration() {
    if (!_dragging ||
        !mounted) {
      return;
    }

    final nextDuration =
        _durationForDrag(
      _effectiveDragDy(),
    );

    if (nextDuration ==
        _previewDurationMinutes) {
      return;
    }

    setState(() {
      _previewDurationMinutes =
          nextDuration;
    });
  }

  void _startDrag(
    DragStartDetails details,
  ) {
    _initialVerticalScrollOffset =
        widget.verticalScrollController.hasClients
            ? widget.verticalScrollController.offset
            : 0;

    setState(() {
      _dragDy = 0;
      _dragging = true;
      _previewDurationMinutes =
          widget.initialDurationMinutes;
    });

    widget.onAutoScrollUpdate(
      details.globalPosition,
      allowHorizontal:
          false,
      allowVertical:
          true,
      onScrolled:
          _refreshPreviewDuration,
    );
  }

  void _updateDrag(
    DragUpdateDetails details,
  ) {
    _dragDy +=
        details.delta.dy;

    widget.onAutoScrollUpdate(
      details.globalPosition,
      allowHorizontal:
          false,
      allowVertical:
          true,
      onScrolled:
          _refreshPreviewDuration,
    );

    _refreshPreviewDuration();
  }

  Future<void> _finishDrag(
    DragEndDetails details,
  ) async {
    final finalDuration =
        _durationForDrag(
      _effectiveDragDy(),
    );

    widget.onAutoScrollEnd();

    setState(() {
      _dragging = false;
      _dragDy = 0;
    });

    if (finalDuration ==
        widget.initialDurationMinutes) {
      return;
    }

    await widget.onResizeEnd(
      finalDuration,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _previewDurationMinutes =
          widget.initialDurationMinutes;
    });
  }

  void _cancelDrag() {
    widget.onAutoScrollEnd();

    if (!_dragging) {
      return;
    }

    setState(() {
      _dragging = false;
      _dragDy = 0;
      _previewDurationMinutes =
          widget.initialDurationMinutes;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final endMinutes =
        widget.startTimeMinutes +
        _previewDurationMinutes;

    final previewOffset =
        (_previewDurationMinutes -
                widget.initialDurationMinutes) /
            60 *
            widget.hourHeight;

    return GestureDetector(
      behavior:
          HitTestBehavior.opaque,
      onVerticalDragStart:
          _startDrag,
      onVerticalDragUpdate:
          _updateDrag,
      onVerticalDragEnd:
          _finishDrag,
      onVerticalDragCancel:
          _cancelDrag,
      child:
          Transform.translate(
        offset:
            Offset(
          0,
          previewOffset,
        ),
        child:
            Stack(
        clipBehavior:
            Clip.none,
        alignment:
            Alignment.bottomCenter,
        children: [
          if (_dragging)
            Positioned(
              bottom:
                  16,
              child:
                  IgnorePointer(
                child:
                    Material(
                  color:
                      colorScheme
                          .surfaceContainerHighest,
                  elevation:
                      2,
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
                  child:
                      Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          7,
                      vertical:
                          4,
                    ),
                    child:
                        Text(
                      '${_clockLabel(widget.startTimeMinutes)}–'
                      '${_clockLabel(endMinutes)} · '
                      '${_durationLabel(_previewDurationMinutes)}',
                      maxLines:
                          1,
                      style:
                          Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color:
                                    colorScheme
                                        .onSurface,
                                fontSize:
                                    9,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment:
                Alignment.bottomCenter,
            child:
                Padding(
              padding:
                  const EdgeInsets.only(
                bottom:
                    3,
              ),
              child:
                  Container(
                width:
                    22,
                height:
                    3,
                decoration:
                    BoxDecoration(
                  color:
                      widget.accentColor
                          .withValues(
                    alpha:
                        _dragging
                            ? 1
                            : 0.72,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    99,
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
}


class _WeekTimedSegment {
  final TaskOccurrence occurrence;
  final int startMinute;
  final int endMinute;
  final bool continuesFromPrevious;
  final bool continuesAfter;

  const _WeekTimedSegment({
    required this.occurrence,
    required this.startMinute,
    required this.endMinute,
    required this.continuesFromPrevious,
    required this.continuesAfter,
  });
}

class _WeekHourlyGrid
    extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selectedDay;
  final Map<int, List<_WeekTimedSegment>> timedByDay;
  final Map<String, TaskCategory> categoryMap;
  final double hourHeight;
  final double gutterWidth;
  final double dayWidth;
  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;
  final BuildContext viewportContext;
  final ValueChanged<TaskOccurrence> onOpen;
  final ValueChanged<TaskOccurrence> onActions;
  final Future<void> Function(
    DateTime targetDate,
    int targetStartMinutes,
  ) onEmptySlotLongPress;
  final Future<void> Function(
    TaskOccurrence occurrence,
    DateTime targetDate,
    int targetStartMinutes,
  ) onMove;
  final Future<void> Function(
    TaskOccurrence occurrence,
    int targetDurationMinutes,
  ) onResize;

  const _WeekHourlyGrid({
    required this.days,
    required this.selectedDay,
    required this.timedByDay,
    required this.categoryMap,
    required this.hourHeight,
    required this.gutterWidth,
    required this.dayWidth,
    required this.verticalScrollController,
    required this.horizontalScrollController,
    required this.viewportContext,
    required this.onOpen,
    required this.onActions,
    required this.onEmptySlotLongPress,
    required this.onMove,
    required this.onResize,
  });

  bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final gridHeight =
        24 * hourHeight;
    final totalWidth =
        gutterWidth +
        dayWidth * 7;

    final gridKey =
        GlobalKey();

    final autoScroller =
        _WeekEdgeAutoScroller(
      verticalController:
          verticalScrollController,
      horizontalController:
          horizontalScrollController,
      viewportContext:
          viewportContext,
      gutterWidth:
          gutterWidth,
      headerHeight:
          76,
    );

    void handleEmptySlotLongPress(
      LongPressStartDetails details,
    ) {
      final gridContext =
          gridKey.currentContext;

      if (gridContext == null) {
        return;
      }

      final renderObject =
          gridContext.findRenderObject();

      if (renderObject is! RenderBox) {
        return;
      }

      // Usiamo la posizione globale convertita rispetto al RenderBox reale
      // della griglia. Così la stessa ora resta la stessa sia con l'header
      // settimanale aperto sia con l'header compresso.
      final position =
          renderObject.globalToLocal(
        details.globalPosition,
      );

      if (position.dx <
              gutterWidth ||
          position.dx >=
              gutterWidth +
                  dayWidth * 7 ||
          position.dy < 0 ||
          position.dy >
              gridHeight) {
        return;
      }

      final targetDayIndex =
          ((position.dx -
                      gutterWidth) /
                  dayWidth)
              .floor()
              .clamp(
                0,
                6,
              )
              .toInt();

      final rawMinutes =
          position.dy /
              hourHeight *
              60;

      final snappedMinutes =
          ((rawMinutes / 15)
                      .round() *
                  15)
              .clamp(
                0,
                24 * 60 - 15,
              )
              .toInt();

      onEmptySlotLongPress(
        days[targetDayIndex],
        snappedMinutes,
      );
    }

    final layoutsByDay =
        <int, List<_WeekBlockLayout>>{
      for (var i = 0; i < 7; i++)
        i: _layoutSegments(
          timedByDay[i] ??
              const <
                  _WeekTimedSegment>[],
        ),
    };

    final now =
        DateTime.now();
    final today =
        DateTime(
      now.year,
      now.month,
      now.day,
    );

    int? todayIndex;

    for (var i = 0;
        i < days.length;
        i++) {
      if (_sameDay(
        days[i],
        today,
      )) {
        todayIndex =
            i;
        break;
      }
    }

    final nowTop =
        (now.hour * 60 +
                now.minute) /
            60 *
            hourHeight;

    return SizedBox(
      key:
          gridKey,
      width:
          totalWidth,
      height:
          gridHeight,
      child: Stack(
        clipBehavior:
            Clip.none,
        children: [
          for (var dayIndex = 0;
              dayIndex < 7;
              dayIndex++)
            if (_sameDay(
              days[dayIndex],
              selectedDay,
            ))
              Positioned(
                left:
                    gutterWidth +
                    dayIndex *
                        dayWidth,
                top:
                    0,
                width:
                    dayWidth,
                height:
                    gridHeight,
                child:
                    ColoredBox(
                  color:
                      colorScheme
                          .primary
                          .withValues(
                    alpha:
                        0.035,
                  ),
                ),
              ),
          CustomPaint(
            size:
                Size(
              totalWidth,
              gridHeight,
            ),
            painter:
                _WeekGridPainter(
              hourHeight:
                  hourHeight,
              gutterWidth:
                  gutterWidth,
              dayWidth:
                  dayWidth,
              lineColor:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha:
                    0.55,
              ),
            ),
          ),
          for (var hour = 0;
              hour < 24;
              hour++)
            Positioned(
              left:
                  0,
              top:
                  hour *
                          hourHeight -
                      8,
              width:
                  gutterWidth -
                  7,
              child:
                  Text(
                '${hour.toString().padLeft(2, '0')}:00',
                textAlign:
                    TextAlign.right,
                style:
                    Theme.of(
                  context,
                )
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                          fontWeight:
                              FontWeight.w500,
                        ),
              ),
            ),
          Positioned.fill(
            child:
                GestureDetector(
              behavior:
                  HitTestBehavior.translucent,
              onLongPressStart:
                  handleEmptySlotLongPress,
            ),
          ),
          for (var dayIndex = 0;
              dayIndex < 7;
              dayIndex++)
            for (final layout
                in layoutsByDay[
                    dayIndex]!)
              _buildOccurrenceBlock(
                context,
                dayIndex,
                layout,
                gridKey,
                autoScroller,
              ),
          if (todayIndex !=
              null)
            Positioned(
              left:
                  gutterWidth +
                  todayIndex *
                      dayWidth,
              top:
                  nowTop,
              width:
                  dayWidth,
              child:
                  Row(
                children: [
                  Container(
                    width:
                        7,
                    height:
                        7,
                    decoration:
                        BoxDecoration(
                      color:
                          colorScheme
                              .error,
                      shape:
                          BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child:
                        Container(
                      height:
                          1.4,
                      color:
                          colorScheme
                              .error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOccurrenceBlock(
    BuildContext context,
    int dayIndex,
    _WeekBlockLayout layout,
    GlobalKey gridKey,
    _WeekEdgeAutoScroller autoScroller,
  ) {
    final segment =
        layout.segment;
    final task =
        segment
            .occurrence
            .displayTask;

    final category =
        task.categoryId ==
                null
            ? null
            : categoryMap[
                task.categoryId];

    final colorScheme =
        Theme.of(context).colorScheme;

    final color =
        category == null
            ? colorScheme
                .onSurfaceVariant
            : Color(
                category.colorValue,
              );

    final segmentDuration =
        segment.endMinute -
        segment.startMinute;

    final rawTop =
        segment.startMinute /
            60 *
            hourHeight;
    final gridHeight =
        24 * hourHeight;

    final top =
        math.min(
      rawTop,
      gridHeight -
          28,
    ).toDouble();

    final rawHeight =
        math.max(
      segmentDuration /
          60 *
          hourHeight,
      28.0,
    ).toDouble();

    final height =
        math.max(
      28.0,
      math.min(
        rawHeight,
        gridHeight -
            top,
      ),
    ).toDouble();

    final availableWidth =
        dayWidth -
        8;
    final laneWidth =
        availableWidth /
        layout.laneCount;

    final left =
        gutterWidth +
        dayIndex *
            dayWidth +
        4 +
        layout.lane *
            laneWidth;

    final width =
        math.max(
      laneWidth -
          3,
      24.0,
    ).toDouble();

    final subtaskText =
        task.subtasks.isEmpty
            ? null
            : '${task.subtasks.where((subtask) => subtask.isCompleted).length}'
                '/${task.subtasks.length}';

    final continuityPrefix =
        segment.continuesFromPrevious
            ? '↳ '
            : '';

    final continuitySuffix =
        segment.continuesAfter
            ? ' →'
            : '';

    final timeText =
        '$continuityPrefix'
        '${_clock(segment.startMinute)}–'
        '${_clock(segment.endMinute)}'
        '$continuitySuffix';

    final block =
        _WeekOccurrenceBlock(
      task:
          task,
      category:
          category,
      accentColor:
          color,
      priorityColor:
          _priorityColor(
        task.priority,
        colorScheme,
      ),
      timeText:
          timeText,
      subtaskText:
          subtaskText,
      height:
          height,
      hourHeight:
          hourHeight,
      startTimeMinutes:
          task.startTimeMinutes ??
          segment.startMinute,
      initialDurationMinutes:
          math.max(
        15,
        task.durationMinutes ??
            30,
      ).toInt(),
      verticalScrollController:
          verticalScrollController,
      onAutoScrollUpdate:
          autoScroller.update,
      onAutoScrollEnd:
          autoScroller.stop,
      onTap:
          () {
        onOpen(
          segment.occurrence,
        );
      },
      onLongPress:
          segment.continuesFromPrevious
              ? () {
                  onActions(
                    segment.occurrence,
                  );
                }
              : null,
      onResizeEnd:
          segment.continuesAfter
              ? null
              : (durationMinutes) {
                  return onResize(
                    segment.occurrence,
                    durationMinutes,
                  );
                },
    );

    Widget draggableBlock =
        block;

    // Un segmento che arriva dal giorno precedente è solo la continuazione
    // visiva della stessa attività: lo si può aprire, ma il drag parte
    // dal segmento che contiene l'inizio reale dell'occorrenza.
    if (!segment.continuesFromPrevious) {
      draggableBlock =
          LongPressDraggable<
              TaskOccurrence>(
        data:
            segment.occurrence,
        delay:
            const Duration(
          milliseconds:
              380,
        ),
        dragAnchorStrategy:
            childDragAnchorStrategy,
        feedback:
            Material(
          color:
              Colors.transparent,
          child:
              Opacity(
            opacity:
                0.92,
            child:
                SizedBox(
              width:
                  width,
              height:
                  height -
                  2,
              child:
                  block,
            ),
          ),
        ),
        childWhenDragging:
            Opacity(
          opacity:
              0.22,
          child:
              block,
        ),
        onDragUpdate:
            (details) {
          autoScroller.update(
            details.globalPosition,
            allowHorizontal:
                true,
            allowVertical:
                true,
          );
        },
        onDragEnd:
            (details) {
          autoScroller.stop();

          final gridContext =
              gridKey.currentContext;

          if (gridContext ==
              null) {
            return;
          }

          final renderObject =
              gridContext.findRenderObject();

          if (renderObject
              is! RenderBox) {
            return;
          }

          final localOffset =
              renderObject.globalToLocal(
            details.offset,
          );

          final originalOffset =
              Offset(
            left,
            top + 1,
          );

          if ((localOffset -
                      originalOffset)
                  .distance <
              10) {
            onActions(
              segment.occurrence,
            );
            return;
          }

          final blockCenterX =
              localOffset.dx +
              width / 2;

          if (blockCenterX <
                  gutterWidth ||
              blockCenterX >=
                  gutterWidth +
                      dayWidth *
                          7 ||
              localOffset.dy <
                  0 ||
              localOffset.dy >
                  24 *
                      hourHeight) {
            return;
          }

          final targetDayIndex =
              ((blockCenterX -
                          gutterWidth) /
                      dayWidth)
                  .floor()
                  .clamp(
                    0,
                    6,
                  )
                  .toInt();

          final rawMinutes =
              localOffset.dy /
                  hourHeight *
                  60;

          final snappedMinutes =
              ((rawMinutes /
                              15)
                          .round() *
                      15)
                  .clamp(
                    0,
                    24 * 60 -
                        15,
                  )
                  .toInt();

          onMove(
            segment.occurrence,
            days[targetDayIndex],
            snappedMinutes,
          );
        },
        child:
            block,
      );
    }

    return Positioned(
      left:
          left,
      top:
          top +
          1,
      width:
          width,
      height:
          height -
          2,
      child:
          draggableBlock,
    );
  }

  Color _priorityColor(
    TaskPriority priority,
    ColorScheme colorScheme,
  ) {
    switch (priority) {
      case TaskPriority.low:
        return const Color(
          0xFF5F8F73,
        );
      case TaskPriority.normal:
        return colorScheme.primary;
      case TaskPriority.high:
        return const Color(
          0xFFC65B61,
        );
    }
  }

  String _clock(
    int minutes,
  ) {
    if (minutes ==
        24 * 60) {
      return '00:00';
    }

    final normalized =
        minutes %
        (24 * 60);

    final hour =
        (normalized ~/ 60)
            .toString()
            .padLeft(
              2,
              '0',
            );
    final minute =
        (normalized % 60)
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$hour:$minute';
  }

  List<_WeekBlockLayout>
      _layoutSegments(
    List<_WeekTimedSegment> segments,
  ) {
    if (segments.isEmpty) {
      return const [];
    }

    final sorted =
        segments.toList()
          ..sort(
            (a, b) {
              final startCompare =
                  a.startMinute
                      .compareTo(
                b.startMinute,
              );

              if (startCompare !=
                  0) {
                return startCompare;
              }

              return a.endMinute
                  .compareTo(
                b.endMinute,
              );
            },
          );

    final result =
        <_WeekBlockLayout>[];
    var index =
        0;

    while (index <
        sorted.length) {
      final group =
          <_WeekTimedSegment>[];
      var groupEnd =
          -1;
      var cursor =
          index;

      while (cursor <
          sorted.length) {
        final segment =
            sorted[cursor];

        if (group.isNotEmpty &&
            segment.startMinute >=
                groupEnd) {
          break;
        }

        group.add(
          segment,
        );

        if (segment.endMinute >
            groupEnd) {
          groupEnd =
              segment.endMinute;
        }

        cursor++;
      }

      final laneEnds =
          <int>[];
      final laneByKey =
          <String, int>{};

      for (final segment
          in group) {
        var lane =
            -1;

        for (var laneIndex =
                0;
            laneIndex <
                laneEnds.length;
            laneIndex++) {
          if (laneEnds[
                  laneIndex] <=
              segment.startMinute) {
            lane =
                laneIndex;
            break;
          }
        }

        if (lane ==
            -1) {
          lane =
              laneEnds.length;
          laneEnds.add(
            segment.endMinute,
          );
        } else {
          laneEnds[lane] =
              segment.endMinute;
        }

        laneByKey[
                segment
                    .occurrence
                    .occurrenceKey] =
            lane;
      }

      final laneCount =
          laneEnds.isEmpty
              ? 1
              : laneEnds.length;

      for (final segment
          in group) {
        result.add(
          _WeekBlockLayout(
            segment:
                segment,
            lane:
                laneByKey[
                        segment
                            .occurrence
                            .occurrenceKey] ??
                    0,
            laneCount:
                laneCount,
          ),
        );
      }

      index =
          cursor;
    }

    return result;
  }
}

class _WeekBlockLayout {
  final _WeekTimedSegment segment;
  final int lane;
  final int laneCount;

  const _WeekBlockLayout({
    required this.segment,
    required this.lane,
    required this.laneCount,
  });
}

class _WeekGridPainter extends CustomPainter {
  final double hourHeight;
  final double gutterWidth;
  final double dayWidth;
  final Color lineColor;

  const _WeekGridPainter({
    required this.hourHeight,
    required this.gutterWidth,
    required this.dayWidth,
    required this.lineColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    for (var hour = 0; hour <= 24; hour++) {
      final y = hour * hourHeight;

      canvas.drawLine(
        Offset(
          gutterWidth,
          y,
        ),
        Offset(
          size.width,
          y,
        ),
        paint,
      );
    }

    for (var day = 0; day <= 7; day++) {
      final x = gutterWidth + day * dayWidth;

      canvas.drawLine(
        Offset(
          x,
          0,
        ),
        Offset(
          x,
          size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _WeekGridPainter oldDelegate,
  ) {
    return oldDelegate.hourHeight != hourHeight ||
        oldDelegate.gutterWidth != gutterWidth ||
        oldDelegate.dayWidth != dayWidth ||
        oldDelegate.lineColor != lineColor;
  }
}
