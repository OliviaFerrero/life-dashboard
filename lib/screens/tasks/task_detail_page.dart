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
import 'task_detail_notes.dart';
import 'task_detail_subtasks.dart';
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
        Theme.of(context).colorScheme;

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
        automaticallyImplyLeading:
            false,
        toolbarHeight:
            72,
        leadingWidth:
            72,
        leading:
            Padding(
          padding:
              const EdgeInsets.only(
            left: 16,
          ),
          child:
              _RoundAppBarButton(
            icon:
                Icons.arrow_back_ios_new_rounded,
            tooltip:
                'Indietro',
            onTap:
                () {
              Navigator.of(context)
                  .maybePop();
            },
          ),
        ),
        titleSpacing:
            10,
        title:
            Text(
          'Dettaglio',
          style:
              Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing:
                        -0.35,
                  ),
        ),
        actions: [
          Container(
            width:
                48,
            height:
                48,
            margin:
                const EdgeInsets.only(
              right: 16,
            ),
            decoration:
                BoxDecoration(
              color:
                  colorScheme
                      .surfaceContainerHighest
                      .withValues(
                        alpha: 0.58,
                      ),
              shape:
                  BoxShape.circle,
            ),
            child:
                PopupMenuButton<String>(
              tooltip:
                  'Azioni attività',
              padding:
                  EdgeInsets.zero,
              icon:
                  const Icon(
                Icons.more_horiz_rounded,
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
                  16,
                ),
                side:
                    BorderSide(
                  color:
                      colorScheme
                          .outlineVariant
                          .withValues(
                            alpha: 0.5,
                          ),
                ),
              ),
              constraints:
                  const BoxConstraints(
                minWidth:
                    170,
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
                          Icons.edit_outlined,
                          size: 19,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Modifica',
                          style:
                              Theme.of(menuContext)
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
                          Icons.delete_outline,
                          size: 19,
                          color:
                              colorScheme.error,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Elimina',
                          style:
                              Theme.of(menuContext)
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
          ),
        ],
      ),
      body:
          StreamBuilder<
              Map<String, TaskCategory>>(
        stream:
            widget.categoryRepository
                .watchCategoryMap(),
        initialData:
            const {},
        builder:
            (context, categorySnapshot) {
          final categoryMap =
              categorySnapshot.data ??
                  const <String, TaskCategory>{};

          final category =
              _task.categoryId == null
                  ? null
                  : categoryMap[
                      _task.categoryId];

          final categoryColor =
              category == null
                  ? colorScheme
                      .onSurfaceVariant
                  : Color(
                      category.colorValue,
                    );

          final categoryIcon =
              category == null
                  ? Icons.label_outline_rounded
                  : taskCategoryIcon(
                      category.iconKey,
                    );

          final recurrenceLabel =
              _task.recurrence.isRecurring
                  ? _recurrenceLabel(
                      _task.recurrence,
                    )
                  : null;

          final startValue =
              _task.allDay
                  ? 'Tutto il giorno'
                  : _task.startTimeMinutes == null
                      ? '—'
                      : _formatClockMinutes(
                          _task.startTimeMinutes!,
                        );

          final endValue =
              !_task.allDay &&
                      _task.startTimeMinutes != null &&
                      _task.durationMinutes != null
                  ? _formatEndTime(
                      _task,
                    )
                  : '—';

          final durationValue =
              _task.durationMinutes == null
                  ? '—'
                  : _durationLabel(
                      _task.durationMinutes!,
                    );

          return ListView(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              28,
            ),
            children: [
              _TaskHeroCard(
                title:
                    _task.title,
                categoryIcon:
                    categoryIcon,
                categoryColor:
                    categoryColor,
                priorityLabel:
                    _priorityLabel(
                  _task.priority,
                ),
                priorityColor:
                    priorityColor,
                recurrenceLabel:
                    recurrenceLabel,
                completed:
                    _isCompleted,
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
                height: 16,
              ),
              _ScheduleCard(
                dateLabel:
                    effectiveDate == null
                        ? 'Nessuna data assegnata'
                        : _dateLabel(
                            effectiveDate,
                          ),
                isInbox:
                    effectiveDate == null,
                allDay:
                    _task.allDay,
                startValue:
                    startValue,
                endValue:
                    endValue,
                durationValue:
                    durationValue,
                accentColor:
                    categoryColor,
                hasOverride:
                    widget.occurrence
                            ?.hasOverride ==
                        true,
              ),
              if (_subtasks.isNotEmpty) ...[
                const SizedBox(
                  height: 16,
                ),
                TaskDetailSubtasksSection(
                  subtasks:
                      _subtasks,
                  accentColor:
                      categoryColor,
                  onToggle:
                      _toggleSubtask,
                ),
              ],
              if (_task.description
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 16,
                ),
                TaskDetailNotesSection(
                  text:
                      _task.description,
                  accentColor:
                      categoryColor,
                ),
              ],
              const SizedBox(
                height: 18,
              ),
              _BottomCompletionButton(
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
            ],
          );
        },
      ),
    );
  }
}

class _RoundAppBarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundAppBarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Center(
      child: Material(
        color:
            colorScheme
                .surfaceContainerHighest
                .withValues(
                  alpha: 0.58,
                ),
        shape:
            const CircleBorder(),
        child: InkWell(
          onTap:
              onTap,
          customBorder:
              const CircleBorder(),
          child: Tooltip(
            message:
                tooltip,
            child:
                SizedBox(
              width:
                  48,
              height:
                  48,
              child:
                  Icon(
                icon,
                size:
                    20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskHeroCard extends StatelessWidget {
  final String title;
  final IconData categoryIcon;
  final Color categoryColor;
  final String priorityLabel;
  final Color priorityColor;
  final String? recurrenceLabel;
  final bool completed;

  const _TaskHeroCard({
    required this.title,
    required this.categoryIcon,
    required this.categoryColor,
    required this.priorityLabel,
    required this.priorityColor,
    required this.recurrenceLabel,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final brightness =
        Theme.of(context).brightness;

    final surface =
        Color.alphaBlend(
      categoryColor.withValues(
        alpha:
            brightness == Brightness.dark
                ? 0.17
                : 0.10,
      ),
      colorScheme.surface,
    );

    return Container(
      decoration:
          BoxDecoration(
        color:
            surface,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
        border:
            Border.all(
          color:
              categoryColor.withValues(
            alpha:
                brightness == Brightness.dark
                    ? 0.22
                    : 0.10,
          ),
        ),
      ),
      clipBehavior:
          Clip.antiAlias,
      child:
          Stack(
        children: [
          Positioned(
            right:
                -56,
            top:
                -54,
            child:
                _DecorativeBlob(
              size:
                  154,
              color:
                  categoryColor.withValues(
                alpha:
                    brightness == Brightness.dark
                        ? 0.12
                        : 0.09,
              ),
            ),
          ),
          Positioned(
            right:
                -16,
            bottom:
                -62,
            child:
                _DecorativeBlob(
              size:
                  128,
              color:
                  categoryColor.withValues(
                alpha:
                    brightness == Brightness.dark
                        ? 0.16
                        : 0.12,
              ),
            ),
          ),
          Positioned(
            right:
                62,
            bottom:
                -36,
            child:
                _DecorativeBlob(
              size:
                  82,
              color:
                  categoryColor.withValues(
                alpha:
                    brightness == Brightness.dark
                        ? 0.11
                        : 0.075,
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              18,
            ),
            child:
                Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                Container(
                  width:
                      74,
                  height:
                      74,
                  decoration:
                      BoxDecoration(
                    color:
                        colorScheme.surface.withValues(
                      alpha:
                          brightness == Brightness.dark
                              ? 0.76
                              : 0.64,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      22,
                    ),
                    border:
                        Border.all(
                      color:
                          colorScheme.onSurface.withValues(
                        alpha:
                            brightness == Brightness.dark
                                ? 0.10
                                : 0.06,
                      ),
                    ),
                  ),
                  child:
                      Icon(
                    categoryIcon,
                    size:
                        36,
                    color:
                        categoryColor,
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child:
                                Text(
                              title,
                              style:
                                  Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight:
                                            FontWeight.w800,
                                        letterSpacing:
                                            -0.65,
                                        height:
                                            1.08,
                                        decoration:
                                            completed
                                                ? TextDecoration.lineThrough
                                                : null,
                                      ),
                            ),
                          ),
                          const SizedBox(
                            width: 9,
                          ),
                          Tooltip(
                            message:
                                'Priorità $priorityLabel',
                            child:
                                Icon(
                              Icons.flag_outlined,
                              size:
                                  20,
                              color:
                                  priorityColor,
                            ),
                          ),
                        ],
                      ),
                      if (recurrenceLabel != null) ...[
                        const SizedBox(
                          height: 8,
                        ),
                        Align(
                          alignment:
                              Alignment.centerLeft,
                          child:
                              _IdentityPill(
                            icon:
                                Icons.repeat_rounded,
                            label:
                                recurrenceLabel!,
                            color:
                                colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
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

class _DecorativeBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeBlob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:
          size,
      height:
          size,
      decoration:
          BoxDecoration(
        color:
            color,
        shape:
            BoxShape.circle,
      ),
    );
  }
}

class _IdentityPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _IdentityPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final brightness =
        Theme.of(context).brightness;

    final background =
        Color.alphaBlend(
      color.withValues(
        alpha:
            brightness == Brightness.dark
                ? 0.18
                : 0.12,
      ),
      colorScheme.surface,
    );

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            background,
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
          Icon(
            icon,
            size:
                15,
            color:
                color,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            label,
            style:
                Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color:
                          color,
                      fontWeight:
                          FontWeight.w700,
                    ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String dateLabel;
  final bool isInbox;
  final bool allDay;
  final String startValue;
  final String endValue;
  final String durationValue;
  final Color accentColor;
  final bool hasOverride;

  const _ScheduleCard({
    required this.dateLabel,
    required this.isInbox,
    required this.allDay,
    required this.startValue,
    required this.endValue,
    required this.durationValue,
    required this.accentColor,
    required this.hasOverride,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final brightness =
        Theme.of(context).brightness;

    final panelTint =
        Color.alphaBlend(
      colorScheme.primary.withValues(
        alpha:
            brightness == Brightness.dark
                ? 0.065
                : 0.025,
      ),
      colorScheme.surfaceContainerLow,
    );

    return Container(
      decoration:
          BoxDecoration(
        color:
            colorScheme.surface,
        borderRadius:
            BorderRadius.circular(
          28,
        ),
        border:
            Border.all(
          color:
              colorScheme.outlineVariant.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      padding:
          const EdgeInsets.fromLTRB(
        17,
        16,
        17,
        16,
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Container(
                width:
                    46,
                height:
                    46,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color:
                      Color.alphaBlend(
                    accentColor.withValues(
                      alpha:
                          brightness == Brightness.dark
                              ? 0.18
                              : 0.13,
                    ),
                    colorScheme.surface,
                  ),
                ),
                child:
                    Icon(
                  isInbox
                      ? Icons.inbox_outlined
                      : Icons.calendar_month_outlined,
                  size:
                      24,
                  color:
                      accentColor,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quando',
                      style:
                          Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontSize:
                                    20,
                                fontWeight:
                                    FontWeight.w700,
                                letterSpacing:
                                    -0.2,
                              ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      dateLabel,
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color:
                                    colorScheme.onSurfaceVariant,
                                height:
                                    1.25,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasOverride) ...[
            const SizedBox(
              height: 10,
            ),
            Align(
              alignment:
                  Alignment.centerLeft,
              child:
                  Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      colorScheme.primary.withValues(
                    alpha:
                        brightness == Brightness.dark
                            ? 0.16
                            : 0.08,
                  ),
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
                    Icon(
                      Icons.tune_rounded,
                      size:
                          15,
                      color:
                          colorScheme.primary,
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Text(
                      'Occorrenza modificata',
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    colorScheme.primary,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(
            height: 16,
          ),
          Container(
            decoration:
                BoxDecoration(
              color:
                  panelTint,
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            child:
                Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child:
                      _ScheduleMetric(
                    icon:
                        allDay
                            ? Icons.wb_sunny_outlined
                            : Icons.schedule_rounded,
                    label:
                        allDay
                            ? 'Orario'
                            : 'Inizio',
                    value:
                        startValue,
                    accentColor:
                        accentColor,
                  ),
                ),
                _MetricDivider(
                  color:
                      colorScheme.outlineVariant,
                ),
                Expanded(
                  child:
                      _ScheduleMetric(
                    icon:
                        Icons.schedule_rounded,
                    label:
                        'Fine',
                    value:
                        endValue,
                    accentColor:
                        accentColor,
                  ),
                ),
                _MetricDivider(
                  color:
                      colorScheme.outlineVariant,
                ),
                Expanded(
                  child:
                      _ScheduleMetric(
                    icon:
                        Icons.hourglass_bottom_rounded,
                    label:
                        'Durata',
                    value:
                        durationValue,
                    accentColor:
                        accentColor,
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

class _ScheduleMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _ScheduleMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final brightness =
        Theme.of(context).brightness;

    final iconBubble = Container(
      width:
          34,
      height:
          34,
      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,
        color:
            Color.alphaBlend(
          accentColor.withValues(
            alpha:
                brightness == Brightness.dark
                    ? 0.17
                    : 0.12,
          ),
          colorScheme.surface,
        ),
      ),
      child:
          Icon(
        icon,
        size:
            19,
        color:
            accentColor,
      ),
    );

    final textBlock = Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color:
                        colorScheme.onSurfaceVariant,
                    fontWeight:
                        FontWeight.w500,
                    height:
                        1.05,
                  ),
        ),
        const SizedBox(
          height: 2,
        ),
        Text(
          value,
          maxLines:
              2,
          overflow:
              TextOverflow.ellipsis,
          style:
              Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontSize:
                        16,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing:
                        -0.2,
                    height:
                        1.08,
                  ),
        ),
      ],
    );

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 5,
      ),
      child:
          LayoutBuilder(
        builder:
            (context, constraints) {
          if (constraints.maxWidth < 108) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                iconBubble,
                const SizedBox(
                  height: 8,
                ),
                textBlock,
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              iconBubble,
              const SizedBox(
                width: 9,
              ),
              Expanded(
                child:
                    textBlock,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  final Color color;

  const _MetricDivider({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:
          1,
      height:
          64,
      margin:
          const EdgeInsets.symmetric(
        vertical: 2,
        horizontal: 5,
      ),
      color:
          color.withValues(
        alpha: 0.76,
      ),
    );
  }
}

class _BottomCompletionButton extends StatelessWidget {
  final bool completed;
  final Color accentColor;
  final VoidCallback onTap;

  const _BottomCompletionButton({
    required this.completed,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        _foregroundFor(accentColor);

    return Material(
      color:
          accentColor,
      borderRadius:
          BorderRadius.circular(
        24,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        child:
            Container(
          constraints:
              const BoxConstraints(
            minHeight:
                60,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          child:
              Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width:
                    32,
                height:
                    32,
                decoration:
                    BoxDecoration(
                  color:
                      foreground.withValues(
                    alpha: 0.96,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    Icon(
                  completed
                      ? Icons.replay_rounded
                      : Icons.check_rounded,
                  size:
                      20,
                  color:
                      accentColor,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Flexible(
                child:
                    Text(
                  completed
                      ? 'Riapri attività'
                      : 'Segna come completata',
                  textAlign:
                      TextAlign.center,
                  style:
                      Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontSize:
                                16,
                            color:
                                foreground,
                            fontWeight:
                                FontWeight.w800,
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

class _OverdueNotice extends StatelessWidget {
  final VoidCallback onReschedule;

  const _OverdueNotice({
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;
    final brightness =
        Theme.of(context).brightness;

    final background =
        Color.alphaBlend(
      colorScheme.error.withValues(
        alpha:
            brightness == Brightness.dark
                ? 0.12
                : 0.055,
      ),
      colorScheme.surface,
    );

    return Container(
      decoration:
          BoxDecoration(
        color:
            background,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              colorScheme.error.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      padding:
          const EdgeInsets.fromLTRB(
        14,
        12,
        10,
        12,
      ),
      child:
          Row(
        children: [
          Container(
            width:
                38,
            height:
                38,
            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              color:
                  colorScheme.error.withValues(
                alpha:
                    brightness == Brightness.dark
                        ? 0.16
                        : 0.10,
              ),
            ),
            child:
                Icon(
              Icons.event_repeat_outlined,
              size:
                  20,
              color:
                  colorScheme.error,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child:
                Column(
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
                                colorScheme.onSurfaceVariant,
                          ),
                ),
              ],
            ),
          ),
          Material(
            color:
                Colors.transparent,
            child:
                InkWell(
              onTap:
                  onReschedule,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              child:
                  Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child:
                    Text(
                  'Sposta',
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _foregroundFor(
  Color color,
) {
  return ThemeData.estimateBrightnessForColor(
            color,
          ) ==
          Brightness.dark
      ? Colors.white
      : const Color(
          0xFF17171C,
        );
}
