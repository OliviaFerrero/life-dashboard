import 'package:flutter/material.dart';

import '../../models/life_task.dart';
import '../../repositories/task_repository.dart';
import 'task_form_page.dart';

class TaskDetailPage extends StatefulWidget {
  final LifeTask task;
  final TaskRepository taskRepository;

  const TaskDetailPage({
    super.key,
    required this.task,
    required this.taskRepository,
  });

  @override
  State<TaskDetailPage> createState() =>
      _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late LifeTask _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _formatTime(DateTime date) {
    return '${_twoDigits(date.hour)}:'
        '${_twoDigits(date.minute)}';
  }

  String _dateLabel(DateTime date) {
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

  Future<void> _setCompleted(
    bool completed,
  ) async {
    await widget.taskRepository.setCompleted(
      _task.id,
      completed,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _task.isCompleted = completed;
    });
  }

  Future<void> _editTask() async {
    final result =
        await Navigator.push<TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormPage(
          initialTask: _task,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    if (result.shouldDelete) {
      await widget.taskRepository.deleteTask(
        _task.id,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
      return;
    }

    final updatedTask = result.task;

    if (updatedTask == null) {
      return;
    }

    await widget.taskRepository.updateTask(
      updatedTask,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _task = updatedTask;
    });
  }

  Future<void> _deleteTask() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminare attività?',
          ),
          content: Text(
            'Vuoi eliminare '
            '"${_task.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Annulla',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Elimina',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await widget.taskRepository.deleteTask(
      _task.id,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final priorityColor =
        _priorityColor(
      context,
      _task.priority,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attività',
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          24,
          12,
          24,
          130,
        ),
        children: [
          Text(
            _task.title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                  letterSpacing: -0.7,
                  decoration:
                      _task.isCompleted
                          ? TextDecoration
                              .lineThrough
                          : null,
                ),
          ),

          const SizedBox(
            height: 18,
          ),

          InkWell(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            onTap: () {
              _setCompleted(
                !_task.isCompleted,
              );
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration:
                        BoxDecoration(
                      color:
                          _task.isCompleted
                              ? colorScheme
                                  .primary
                              : Colors
                                  .transparent,
                      shape:
                          BoxShape.circle,
                      border:
                          Border.all(
                        color:
                            _task.isCompleted
                                ? colorScheme
                                    .primary
                                : colorScheme
                                    .onSurfaceVariant,
                        width: 2,
                      ),
                    ),
                    child:
                        _task.isCompleted
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color:
                                    colorScheme
                                        .onPrimary,
                              )
                            : null,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Text(
                    _task.isCompleted
                        ? 'Completata'
                        : 'Completa',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight
                                  .w600,
                          color:
                              _task.isCompleted
                                  ? colorScheme
                                      .primary
                                  : null,
                        ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 30,
          ),

          Text(
            'Quando',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
          ),

          const SizedBox(
            height: 18,
          ),

          if (_task.startAt == null)
            const _SimpleInfoRow(
              icon:
                  Icons.calendar_today_outlined,
              text: 'Nessuna data',
            )
          else ...[
            Text(
              _dateLabel(
                _task.startAt!,
              ),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w600,
                  ),
            ),

            const SizedBox(
              height: 18,
            ),

            if (_task.allDay)
              const _SimpleInfoRow(
                icon:
                    Icons.schedule_outlined,
                text:
                    'Tutto il giorno',
              )
            else
              _TimeRange(
                start: _formatTime(
                  _task.startAt!,
                ),
                end:
                    _task.endAt == null
                        ? null
                        : _formatTime(
                            _task.endAt!,
                          ),
              ),
          ],

          const SizedBox(
            height: 34,
          ),

          Divider(
            color: colorScheme
                .outlineVariant
                .withValues(
              alpha: 0.6,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          Text(
            'Priorità',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 20,
                color: priorityColor,
              ),

              const SizedBox(
                width: 10,
              ),

              Text(
                _priorityLabel(
                  _task.priority,
                ),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      color:
                          priorityColor,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
              ),
            ],
          ),

          const SizedBox(
            height: 34,
          ),

          Divider(
            color: colorScheme
                .outlineVariant
                .withValues(
              alpha: 0.6,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          Text(
            'Descrizione',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            _task.description
                    .trim()
                    .isEmpty
                ? 'Nessuna descrizione.'
                : _task.description,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
                  height: 1.5,
                  color:
                      _task.description
                              .trim()
                              .isEmpty
                          ? colorScheme
                              .onSurfaceVariant
                          : null,
                ),
          ),
        ],
      ),

      bottomNavigationBar:
          SafeArea(
        minimum:
            const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          16,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child:
                  OutlinedButton.icon(
                onPressed:
                    _deleteTask,
                icon:
                    const Icon(
                  Icons
                      .delete_outline,
                ),
                label:
                    const Text(
                  'Elimina',
                ),
                style:
                    OutlinedButton
                        .styleFrom(
                  minimumSize:
                      const Size
                          .fromHeight(
                    52,
                  ),
                  foregroundColor:
                      colorScheme
                          .error,
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              flex: 3,
              child:
                  FilledButton.icon(
                onPressed:
                    _editTask,
                icon:
                    const Icon(
                  Icons
                      .edit_outlined,
                ),
                label:
                    const Text(
                  'Modifica',
                ),
                style:
                    FilledButton
                        .styleFrom(
                  minimumSize:
                      const Size
                          .fromHeight(
                    52,
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

class _SimpleInfoRow
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SimpleInfoRow({
    required this.icon,
    required this.text,
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
        Icon(
          icon,
          size: 20,
          color: colorScheme
              .onSurfaceVariant,
        ),

        const SizedBox(
          width: 10,
        ),

        Text(
          text,
          style: Theme.of(context)
              .textTheme
              .bodyLarge,
        ),
      ],
    );
  }
}

class _TimeRange
    extends StatelessWidget {
  final String start;
  final String? end;

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
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight:
                    FontWeight.w700,
              ),
        ),

        const SizedBox(
          width: 14,
        ),

        Expanded(
          child: Container(
            height: 1,
            color: colorScheme
                .outlineVariant,
          ),
        ),

        if (end != null) ...[
          const SizedBox(
            width: 14,
          ),

          Text(
            end!,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
          ),
        ],
      ],
    );
  }
}