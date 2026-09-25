import 'package:flutter/material.dart';

import '../../application/task_actions.dart';
import '../../core/time/app_clock.dart';
import '../../core/time/civil_date.dart';
import '../../models/life_task.dart';
import '../../models/task_category.dart';
import '../../models/task_occurrence.dart';
import '../../models/task_recurrence.dart';
import '../../models/task_series_scope.dart';
import '../../models/task_subtask.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/task_repository.dart';
import '../../utils/task_category_icons.dart';
import '../../widgets/task_prompts.dart';
import 'task_editor_mode.dart';
import 'task_form_page.dart';

class TaskDetailPage extends StatefulWidget {
  final LifeTask task;
  final TaskOccurrence? occurrence;
  final TaskRepository taskRepository;
  final CategoryRepository categoryRepository;

  const TaskDetailPage({
    super.key,
    required this.task,
    this.occurrence,
    required this.taskRepository,
    required this.categoryRepository,
  });

  @override
  State<TaskDetailPage> createState() =>
      _TaskDetailPageState();
}

class _TaskDetailPageState
    extends State<TaskDetailPage> {
  TaskActions get _taskActions =>
      TaskActions(
        widget.taskRepository,
      );

  late LifeTask _seriesTask;
  late LifeTask _task;
  late bool _isCompleted;
  late List<TaskSubtask> _subtasks;

  /// Data effettiva mostrata per questa occorrenza.
  DateTime? _occurrenceDate;

  /// Data originaria generata dalla regola della serie.
  /// Rimane stabile anche se l'occorrenza viene spostata.
  DateTime? _seriesDate;

  @override
  void initState() {
    super.initState();

    _seriesTask =
        widget.occurrence?.task ??
            widget.task;

    _task =
        widget.occurrence?.displayTask ??
            widget.task;

    _occurrenceDate =
        widget.occurrence?.date ??
            _task.scheduledDate;

    _seriesDate =
        widget.occurrence?.seriesDate ??
            _task.scheduledDate;

    _isCompleted =
        widget.occurrence?.isCompleted ??
            _task.isCompleted;

    _subtasks =
        (widget.occurrence?.subtasks ??
                _task.subtasks)
            .toList()
          ..sort(
            (a, b) =>
                a.sortOrder.compareTo(
              b.sortOrder,
            ),
          );
  }

  String _twoDigits(
    int value,
  ) {
    return value
        .toString()
        .padLeft(2, '0');
  }

  String _formatClockMinutes(
    int minutes,
  ) {
    final normalized =
        minutes % (24 * 60);

    return '${_twoDigits(normalized ~/ 60)}:'
        '${_twoDigits(normalized % 60)}';
  }

  String _formatEndTime(
    LifeTask task,
  ) {
    final start =
        task.startTimeMinutes;
    final duration =
        task.durationMinutes;

    if (start == null ||
        duration == null) {
      return '';
    }

    final total =
        start + duration;
    final extraDays =
        total ~/ (24 * 60);

    final suffix =
        extraDays == 0
            ? ''
            : extraDays == 1
                ? ' (+1 giorno)'
                : ' (+$extraDays giorni)';

    return '${_formatClockMinutes(total)}'
        '$suffix';
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
          ? '1 ora'
          : '$hours ore';
    }

    return '$hours h $remaining min';
  }

  String _dateLabel(
    DateTime date,
  ) {
    const weekdays = [
      'Lunedì',
      'Martedì',
      'Mercoledì',
      'Giovedì',
      'Venerdì',
      'Sabato',
      'Domenica',
    ];

    const months = [
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
    ];

    return '${weekdays[date.weekday - 1]} '
        '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  String _priorityLabel(
    TaskPriority priority,
  ) {
    switch (priority) {
      case TaskPriority.low:
        return 'Bassa';
      case TaskPriority.normal:
        return 'Normale';
      case TaskPriority.high:
        return 'Alta';
    }
  }

  Color _priorityColor(
    BuildContext context,
    TaskPriority priority,
  ) {
    switch (priority) {
      case TaskPriority.low:
        return const Color(
          0xFF5F8F73,
        );

      case TaskPriority.normal:
        return Theme.of(context)
            .colorScheme
            .primary;

      case TaskPriority.high:
        return const Color(
          0xFFC65B61,
        );
    }
  }

  String _recurrenceLabel(
    TaskRecurrence recurrence,
  ) {
    switch (recurrence.type) {
      case TaskRecurrenceType.none:
        return 'Non ricorrente';

      case TaskRecurrenceType.daily:
        return 'Ogni giorno';

      case TaskRecurrenceType.weekly:
        final days =
            recurrence.weekdays;

        if (days.isEmpty) {
          return 'Ogni settimana';
        }

        if (days.length == 1) {
          const names = {
            DateTime.monday:
                'lunedì',
            DateTime.tuesday:
                'martedì',
            DateTime.wednesday:
                'mercoledì',
            DateTime.thursday:
                'giovedì',
            DateTime.friday:
                'venerdì',
            DateTime.saturday:
                'sabato',
            DateTime.sunday:
                'domenica',
          };

          return 'Ogni '
              '${names[days.first]}';
        }

        const short = {
          DateTime.monday:
              'Lun',
          DateTime.tuesday:
              'Mar',
          DateTime.wednesday:
              'Mer',
          DateTime.thursday:
              'Gio',
          DateTime.friday:
              'Ven',
          DateTime.saturday:
              'Sab',
          DateTime.sunday:
              'Dom',
        };

        return days
            .map(
              (day) =>
                  short[day]!,
            )
            .join(' · ');
    }
  }

  bool _isPastUnfinished() {
    if (_isCompleted ||
        _task.recurrence.isRecurring) {
      return false;
    }

    final dateValue =
        _occurrenceDate ??
            _task.scheduledDate;

    if (dateValue == null) {
      return false;
    }

    final now =
        AppClockScope.read(
      context,
    ).now;

    final today =
        CivilDate.dateOnly(
      now,
    );

    final date =
        CivilDate.dateOnly(
      dateValue,
    );

    if (date.isBefore(today)) {
      return true;
    }

    if (date.isAfter(today)) {
      return false;
    }

    if (_task.allDay ||
        _task.startTimeMinutes ==
            null) {
      return false;
    }

    final cutoffMinutes =
        _task.startTimeMinutes! +
        (_task.durationMinutes ?? 0);

    final cutoff =
        date.add(
      Duration(
        minutes:
            cutoffMinutes,
      ),
    );

    return now.isAfter(
      cutoff,
    );
  }

  int get _completedSubtaskCount =>
      _subtasks
          .where(
            (subtask) =>
                subtask.isCompleted,
          )
          .length;


  Future<void> _toggleSubtask(
    TaskSubtask subtask,
  ) async {
    final completed =
        !subtask.isCompleted;

    final parentBecameIncomplete =
        !completed &&
            _isCompleted;

    await _taskActions
        .setSubtaskCompleted(
      task:
          _seriesTask,
      subtask:
          subtask,
      completed:
          completed,
      occurrence:
          _currentOccurrence(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      final index =
          _subtasks.indexWhere(
        (item) =>
            item.id == subtask.id,
      );

      if (index >= 0) {
        _subtasks[index] =
            _subtasks[index].copyWith(
          isCompleted:
              completed,
        );
      }

      if (parentBecameIncomplete) {
        _isCompleted =
            false;

        if (!_seriesTask.recurrence
            .isRecurring) {
          final reopenedTask =
              _task.copyWith(
            isCompleted:
                false,
          );

          _task =
              reopenedTask;
          _seriesTask =
              reopenedTask;
        }
      }
    });
  }

  Future<void> _setCompleted(
    bool completed,
  ) async {
    if (completed) {
      final confirmed =
          await TaskPrompts
              .confirmCompletionIfNeeded(
        context,
        subtasks:
            _subtasks,
      );

      if (!confirmed ||
          !mounted) {
        return;
      }
    }

    await _taskActions
        .setCompleted(
      task:
          _seriesTask,
      occurrence:
          _currentOccurrence(),
      completed:
          completed,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isCompleted =
          completed;

      if (completed) {
        _subtasks = [
          for (final subtask
              in _subtasks)
            subtask.copyWith(
              isCompleted:
                  true,
            ),
        ];
      }

      if (!_seriesTask.recurrence
          .isRecurring) {
        final updatedTask =
            _task.copyWith(
          isCompleted:
              completed,
        );

        _task =
            updatedTask;
        _seriesTask =
            updatedTask;
      }
    });
  }

  LifeTask _seriesTaskForEditing() {
    return LifeTask(
      id:
          _seriesTask.id,
      title:
          _seriesTask.title,
      description:
          _seriesTask.description,
      scheduledDate:
          _seriesTask.scheduledDate,
      startTimeMinutes:
          _seriesTask.startTimeMinutes,
      durationMinutes:
          _seriesTask.durationMinutes,
      categoryId:
          _seriesTask.categoryId,
      allDay:
          _seriesTask.allDay,
      priority:
          _seriesTask.priority,
      recurrence:
          _seriesTask.recurrence,
      subtasks:
          _seriesTask.subtasks,
      isCompleted:
          _seriesTask.isCompleted,
    );
  }

  LifeTask _occurrenceTaskForEditing() {
    return LifeTask(
      id:
          _seriesTask.id,
      title:
          _task.title,
      description:
          _task.description,
      scheduledDate:
          _occurrenceDate ??
              _task.scheduledDate,
      startTimeMinutes:
          _task.startTimeMinutes,
      durationMinutes:
          _task.durationMinutes,
      categoryId:
          _task.categoryId,
      allDay:
          _task.allDay,
      priority:
          _task.priority,
      recurrence:
          _seriesTask.recurrence,
      subtasks:
          _subtasks,
      isCompleted:
          _isCompleted,
    );
  }

  TaskOccurrence? _currentOccurrence() {
    final date =
        _occurrenceDate ??
            _task.scheduledDate;

    final seriesDate =
        _seriesDate ??
            _seriesTask.scheduledDate;

    if (date == null ||
        seriesDate == null) {
      return null;
    }

    return TaskOccurrence(
      task:
          _seriesTask,
      date:
          date,
      seriesDate:
          seriesDate,
      isCompleted:
          _isCompleted,
      subtasks:
          _subtasks,
      effectiveTask:
          _task,
    );
  }

  Future<void> _editSeries() async {
    final result =
        await Navigator.push<
            TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskFormPage(
          categoryRepository:
              widget.categoryRepository,
          mode:
              TaskEditorMode.edit,
          initialTask:
              _seriesTaskForEditing(),
        ),
      ),
    );

    if (result == null) {
      return;
    }

    if (result.shouldDelete) {
      await _taskActions.delete(
        task:
            _seriesTask,
        scope:
            TaskSeriesScope.series,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
      );
      return;
    }

    final updatedTask =
        result.task;

    if (updatedTask == null) {
      return;
    }

    await widget.taskRepository
        .updateTask(
      updatedTask,
    );

    if (!mounted) {
      return;
    }

    if (_seriesTask.recurrence
        .isRecurring) {
      // Torniamo alla lista/calendario: la sorgente reattiva ricostruisce
      // l'occorrenza con eventuali eccezioni ancora applicabili.
      Navigator.pop(
        context,
      );
      return;
    }

    setState(() {
      _seriesTask =
          updatedTask;
      _task =
          updatedTask;
      _occurrenceDate =
          updatedTask.scheduledDate;
      _seriesDate =
          updatedTask.scheduledDate;
      _isCompleted =
          updatedTask.isCompleted;
      _subtasks =
          updatedTask.subtasks
              .toList()
            ..sort(
              (a, b) =>
                  a.sortOrder.compareTo(
                b.sortOrder,
              ),
            );
    });
  }

  Future<void> _editOccurrence() async {
    final occurrence =
        _currentOccurrence();

    if (occurrence == null ||
        !occurrence.isRecurring) {
      return;
    }

    final result =
        await Navigator.push<
            TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskFormPage(
          categoryRepository:
              widget.categoryRepository,
          mode:
              TaskEditorMode.editOccurrence,
          initialTask:
              _occurrenceTaskForEditing(),
        ),
      ),
    );

    final editedTask =
        result?.task;

    if (editedTask == null) {
      return;
    }

    await widget.taskRepository
        .saveOccurrenceOverride(
      occurrence:
          occurrence,
      editedTask:
          editedTask,
    );

    if (!mounted) {
      return;
    }

    // La pagina sorgente è reattiva e ricostruirà l'occorrenza con
    // titolo/data/orario/categoria/priorità effettivi aggiornati.
    Navigator.pop(
      context,
    );
  }

  Future<void> _rescheduleTask() async {
    if (_seriesTask.recurrence.isRecurring) {
      return;
    }

    final result =
        await Navigator.push<
            TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskFormPage(
          categoryRepository:
              widget.categoryRepository,
          mode:
              TaskEditorMode.reschedule,
          initialTask:
              _seriesTaskForEditing(),
        ),
      ),
    );

    final updatedTask =
        result?.task;

    if (updatedTask == null) {
      return;
    }

    await widget.taskRepository
        .updateTask(
      updatedTask,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _seriesTask =
          updatedTask;
      _task =
          updatedTask;
      _occurrenceDate =
          updatedTask.scheduledDate;
      _seriesDate =
          updatedTask.scheduledDate;
      _isCompleted =
          updatedTask.isCompleted;
      _subtasks =
          updatedTask.subtasks
              .toList()
            ..sort(
              (a, b) =>
                  a.sortOrder.compareTo(
                b.sortOrder,
              ),
            );
    });
  }

  Future<void> _deleteSeries() async {
    final confirmed =
        await TaskPrompts
            .confirmDeleteTask(
      context,
      task:
          _seriesTask,
    );

    if (!confirmed) {
      return;
    }

    await _taskActions.delete(
      task:
          _seriesTask,
      scope:
          TaskSeriesScope.series,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
    );
  }

  Future<void> _deleteOccurrence() async {
    final occurrence =
        _currentOccurrence();

    if (occurrence == null ||
        !occurrence.isRecurring) {
      return;
    }

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
          _seriesTask,
      occurrence:
          occurrence,
      scope:
          TaskSeriesScope.occurrence,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
    );
  }

  Future<void> _handleEditAction() async {
    if (!_seriesTask.recurrence
        .isRecurring) {
      await _editSeries();
      return;
    }

    final occurrence =
        _currentOccurrence();

    if (occurrence == null) {
      await _editSeries();
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

    switch (scope) {
      case TaskSeriesScope.occurrence:
        await _editOccurrence();
        break;

      case TaskSeriesScope.series:
        await _editSeries();
        break;
    }
  }

  Future<void> _handleDeleteAction() async {
    if (!_seriesTask.recurrence
        .isRecurring) {
      await _deleteSeries();
      return;
    }

    final occurrence =
        _currentOccurrence();

    if (occurrence == null) {
      await _deleteSeries();
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

    switch (scope) {
      case TaskSeriesScope.occurrence:
        await _deleteOccurrence();
        break;

      case TaskSeriesScope.series:
        await _deleteSeries();
        break;
    }
  }


  @override
  Widget build(
    BuildContext context,
  ) {
    AppClockScope.watch(
      context,
    );

    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final priorityColor =
        _priorityColor(
      context,
      _task.priority,
    );

    final isPast =
        _isPastUnfinished();

    final effectiveDate =
        _occurrenceDate ??
            _task.scheduledDate;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Dettaglio',
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip:
                'Azioni attività',
            icon:
                const Icon(
              Icons.more_horiz,
            ),
            offset:
                const Offset(
              0,
              8,
            ),
            elevation:
                3,
            color:
                colorScheme.surface,
            surfaceTintColor:
                Colors.transparent,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              side:
                  BorderSide(
                color:
                    colorScheme
                        .outlineVariant
                        .withValues(
                          alpha:
                              0.55,
                        ),
              ),
            ),
            constraints:
                const BoxConstraints(
              minWidth:
                  168,
            ),
            onSelected:
                (value) {
              switch (value) {
                case 'edit':
                  _handleEditAction();
                  break;
                case 'delete':
                  _handleDeleteAction();
                  break;
              }
            },
            itemBuilder:
                (menuContext) {
              return [
                PopupMenuItem<String>(
                  value:
                      'edit',
                  height:
                      46,
                  child:
                      Row(
                    children: [
                      const Icon(
                        Icons
                            .edit_outlined,
                        size:
                            19,
                      ),
                      const SizedBox(
                        width:
                            10,
                      ),
                      Text(
                        'Modifica',
                        style:
                            Theme.of(
                          menuContext,
                        )
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value:
                      'delete',
                  height:
                      46,
                  child:
                      Row(
                    children: [
                      Icon(
                        Icons
                            .delete_outline,
                        size:
                            19,
                        color:
                            colorScheme.error,
                      ),
                      const SizedBox(
                        width:
                            10,
                      ),
                      Text(
                        'Elimina',
                        style:
                            Theme.of(
                          menuContext,
                        )
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      colorScheme.error,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: StreamBuilder<
          Map<String, TaskCategory>>(
        stream:
            widget.categoryRepository
                .watchCategoryMap(),
        initialData:
            const {},
        builder:
            (context,
                categorySnapshot) {
          final categoryMap =
              categorySnapshot.data ??
                  const <
                      String,
                      TaskCategory>{};

          final category =
              _task.categoryId ==
                      null
                  ? null
                  : categoryMap[
                      _task
                          .categoryId];

          final categoryColor =
              category == null
                  ? colorScheme
                      .onSurfaceVariant
                      .withValues(
                        alpha:
                            0.72,
                      )
                  : Color(
                      category
                          .colorValue,
                    );

          final hasTimedRange =
              !_task.allDay &&
                  _task.startTimeMinutes !=
                      null &&
                  _task.durationMinutes !=
                      null;

          return ListView(
            padding:
                const EdgeInsets
                    .fromLTRB(
              24,
              8,
              24,
              96,
            ),
            children: [
              Text(
                _task.title,
                style:
                    Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight
                                  .w700,
                          letterSpacing:
                              -0.7,
                          height:
                              1.12,
                          decoration:
                              _isCompleted
                                  ? TextDecoration
                                      .lineThrough
                                  : null,
                        ),
              ),

              const SizedBox(
                height: 14,
              ),

              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _TaskIdentityItem(
                    icon:
                        category == null
                            ? Icons
                                .remove_circle_outline
                            : taskCategoryIcon(
                                category
                                    .iconKey,
                              ),
                    label:
                        category?.name ??
                            'Nessuna categoria',
                    color:
                        categoryColor,
                  ),
                  _TaskIdentityItem(
                    icon:
                        Icons.flag_outlined,
                    label:
                        _priorityLabel(
                      _task.priority,
                    ),
                    color:
                        priorityColor,
                  ),
                  if (_task.recurrence
                      .isRecurring)
                    _TaskIdentityItem(
                      icon:
                          Icons.repeat,
                      label:
                          _recurrenceLabel(
                        _task.recurrence,
                      ),
                      color:
                          colorScheme
                              .onSurfaceVariant,
                    ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              _CompletionAction(
                completed:
                    _isCompleted,
                accentColor:
                    categoryColor,
                onTap:
                    () {
                  _setCompleted(
                    !_isCompleted,
                  );
                },
              ),

              if (isPast) ...[
                const SizedBox(
                  height: 14,
                ),
                _OverdueNotice(
                  onReschedule:
                      _rescheduleTask,
                ),
              ],

              const SizedBox(
                height: 30,
              ),

              const _SectionLabel(
                text:
                    'PIANIFICAZIONE',
              ),

              const SizedBox(
                height: 12,
              ),

              if (effectiveDate ==
                  null)
                const _InfoLine(
                  icon:
                      Icons
                          .inbox_outlined,
                  title:
                      'Inbox',
                  value:
                      'Nessuna data assegnata',
                )
              else
                _InfoLine(
                  icon:
                      Icons
                          .calendar_today_outlined,
                  title:
                      'Data',
                  value:
                      _dateLabel(
                    effectiveDate,
                  ),
                ),

              if (widget.occurrence
                      ?.hasOverride ==
                  true) ...[
                const SizedBox(
                  height: 12,
                ),
                const _InfoLine(
                  icon:
                      Icons
                          .tune_outlined,
                  title:
                      'Eccezione',
                  value:
                      'Modificata solo per questa occorrenza',
                ),
              ],

              if (_task.allDay) ...[
                const SizedBox(
                  height: 12,
                ),
                const _InfoLine(
                  icon:
                      Icons
                          .today_outlined,
                  title:
                      'Orario',
                  value:
                      'Tutto il giorno',
                ),
              ] else if (_task
                      .startTimeMinutes !=
                  null) ...[
                const SizedBox(
                  height: 16,
                ),
                if (_task
                        .durationMinutes !=
                    null)
                  _TimeRange(
                    start:
                        _formatClockMinutes(
                      _task
                          .startTimeMinutes!,
                    ),
                    end:
                        _formatEndTime(
                      _task,
                    ),
                  )
                else
                  _InfoLine(
                    icon:
                        Icons
                            .schedule_outlined,
                    title:
                        effectiveDate ==
                                null
                            ? 'Orario preferito'
                            : 'Ora inizio',
                    value:
                        _formatClockMinutes(
                      _task
                          .startTimeMinutes!,
                    ),
                  ),
              ] else if (effectiveDate !=
                  null) ...[
                const SizedBox(
                  height: 12,
                ),
                const _InfoLine(
                  icon:
                      Icons
                          .schedule_outlined,
                  title:
                      'Orario',
                  value:
                      'Non impostato',
                ),
              ],

              if (_task.durationMinutes !=
                  null) ...[
                const SizedBox(
                  height: 12,
                ),
                _InfoLine(
                  icon:
                      Icons
                          .timer_outlined,
                  title:
                      hasTimedRange
                          ? 'Durata'
                          : 'Durata prevista',
                  value:
                      _durationLabel(
                    _task
                        .durationMinutes!,
                  ),
                ),
              ],

              if (_subtasks.isNotEmpty) ...[
                const SizedBox(
                  height: 28,
                ),
                const _SoftDivider(),
                const SizedBox(
                  height: 24,
                ),

                Row(
                  children: [
                    const Expanded(
                      child:
                          _SectionLabel(
                        text:
                            'SOTTOATTIVITÀ',
                      ),
                    ),
                    Text(
                      '$_completedSubtaskCount/${_subtasks.length}',
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color:
                                    colorScheme
                                        .onSurfaceVariant,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                for (var index = 0;
                    index <
                        _subtasks.length;
                    index++) ...[
                  _SubtaskDetailRow(
                    subtask:
                        _subtasks[index],
                    accentColor:
                        categoryColor,
                    onTap: () {
                      _toggleSubtask(
                        _subtasks[index],
                      );
                    },
                  ),

                  if (index !=
                      _subtasks.length -
                          1)
                    Divider(
                      height: 1,
                      indent: 34,
                      color:
                          colorScheme
                              .outlineVariant
                              .withValues(
                                alpha:
                                    0.45,
                              ),
                    ),
                ],

                if (_completedSubtaskCount ==
                    _subtasks.length) ...[
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    'Tutte le sottoattività sono completate.',
                    style:
                        Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  categoryColor,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                  ),
                ],
              ],

              if (_task.description
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 28,
                ),
                const _SoftDivider(),
                const SizedBox(
                  height: 24,
                ),

                const _SectionLabel(
                  text:
                      'NOTE',
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  _task.description,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            height:
                                1.5,
                          ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}


class _TaskIdentityItem
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TaskIdentityItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(
          width: 5,
        ),
        Text(
          label,
          style:
              Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: color,
                    fontWeight:
                        FontWeight.w600,
                  ),
        ),
      ],
    );
  }
}

class _SubtaskDetailRow
    extends StatelessWidget {
  final TaskSubtask subtask;
  final Color accentColor;
  final VoidCallback onTap;

  const _SubtaskDetailRow({
    required this.subtask,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration:
                    BoxDecoration(
                  color:
                      subtask.isCompleted
                          ? accentColor
                          : Colors
                              .transparent,
                  shape:
                      BoxShape.circle,
                  border:
                      Border.all(
                    color:
                        subtask.isCompleted
                            ? accentColor
                            : colorScheme
                                .onSurfaceVariant,
                    width: 2,
                  ),
                ),
                child:
                    subtask.isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 12,
                            color:
                                Colors.white,
                          )
                        : null,
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  subtask.title,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .w500,
                            decoration:
                                subtask.isCompleted
                                    ? TextDecoration
                                        .lineThrough
                                    : null,
                            color:
                                subtask.isCompleted
                                    ? colorScheme
                                        .onSurfaceVariant
                                    : null,
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

class _CompletionAction
    extends StatelessWidget {
  final bool completed;
  final Color accentColor;
  final VoidCallback onTap;

  const _CompletionAction({
    required this.completed,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Align(
      alignment:
          Alignment.centerLeft,
      child: Material(
        color:
            Colors.transparent,
        child: InkWell(
          onTap:
              onTap,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          child: Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              vertical: 7,
              horizontal: 2,
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration:
                      BoxDecoration(
                    color:
                        completed
                            ? accentColor
                            : Colors
                                .transparent,
                    shape:
                        BoxShape.circle,
                    border:
                        Border.all(
                      color:
                          completed
                              ? accentColor
                              : colorScheme
                                  .onSurfaceVariant,
                      width: 2,
                    ),
                  ),
                  child:
                      completed
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color:
                                  colorScheme
                                      .onPrimary,
                            )
                          : null,
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  completed
                      ? 'Completata'
                      : 'Segna come completata',
                  style:
                      Theme.of(
                    context,
                  )
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            color:
                                completed
                                    ? accentColor
                                    : colorScheme
                                        .onSurface,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverdueNotice
    extends StatelessWidget {
  final VoidCallback onReschedule;

  const _OverdueNotice({
    required this.onReschedule,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Container(
      padding:
          const EdgeInsets.only(
        left: 12,
      ),
      decoration:
          BoxDecoration(
        border:
            Border(
          left:
              BorderSide(
            color:
                colorScheme.error
                    .withValues(
                      alpha: 0.72,
                    ),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons
                .event_repeat_outlined,
            size: 18,
            color:
                colorScheme.error,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Da riprogrammare',
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color:
                                colorScheme.error,
                            fontWeight:
                                FontWeight.w700,
                          ),
                ),
                const SizedBox(
                  height: 1,
                ),
                Text(
                  'Attività passata non completata',
                  style:
                      Theme.of(context)
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
          TextButton(
            onPressed:
                onReschedule,
            child:
                const Text(
              'Sposta',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel
    extends StatelessWidget {
  final String text;

  const _SectionLabel({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      text,
      style:
          Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(
                color:
                    Theme.of(
                  context,
                )
                        .colorScheme
                        .onSurfaceVariant,
                fontWeight:
                    FontWeight
                        .w800,
                letterSpacing:
                    1,
              ),
    );
  }
}

class _InfoLine
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets
                  .only(
            top: 2,
          ),
          child: Icon(
            icon,
            size: 19,
            color:
                colorScheme
                    .onSurfaceVariant,
          ),
        ),
        const SizedBox(
          width: 11,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                title,
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
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                value,
                style:
                    Theme.of(
                  context,
                )
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoftDivider
    extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Divider(
      height: 1,
      color:
          Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(
                alpha: 0.55,
              ),
    );
  }
}

class _TimeRange
    extends StatelessWidget {
  final String start;
  final String end;

  const _TimeRange({
    required this.start,
    required this.end,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Row(
      children: [
        Text(
          start,
          style:
              Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight
                            .w700,
                    letterSpacing:
                        -0.4,
                  ),
        ),
        const SizedBox(
          width: 14,
        ),
        Expanded(
          child: Container(
            height: 1,
            color:
                colorScheme
                    .outlineVariant,
          ),
        ),
        const SizedBox(
          width: 14,
        ),
        Flexible(
          child: Text(
            end,
            textAlign:
                TextAlign.right,
            style:
                Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight:
                          FontWeight
                              .w700,
                      letterSpacing:
                          -0.4,
                    ),
          ),
        ),
      ],
    );
  }
}
