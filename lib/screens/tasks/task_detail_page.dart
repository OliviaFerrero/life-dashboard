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

class _TaskDetailPageState
    extends State<TaskDetailPage> {
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

  String _formatDate(DateTime date) {
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
        return Colors.green;

      case TaskPriority.normal:
        return Theme.of(context)
            .colorScheme
            .primary;

      case TaskPriority.high:
        return Colors.red;
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
          'Dettaglio attività',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          120,
        ),
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 7,
                height: 54,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  _task.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                        decoration:
                            _task.isCompleted
                                ? TextDecoration
                                    .lineThrough
                                : null,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () {
                _setCompleted(
                  !_task.isCompleted,
                );
              },

              leading: Icon(
                _task.isCompleted
                    ? Icons.check_circle
                    : Icons
                        .radio_button_unchecked,
                size: 30,
                color: _task.isCompleted
                    ? colorScheme.primary
                    : colorScheme
                        .onSurfaceVariant,
              ),

              title: Text(
                _task.isCompleted
                    ? 'Completata'
                    : 'Completa',
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons
                      .calendar_today_outlined,
                  title: 'Data',
                  value:
                      _task.startAt == null
                          ? 'Senza data'
                          : _formatDate(
                              _task.startAt!,
                            ),
                ),

                if (_task.startAt != null) ...[
                  const Divider(height: 1),

                  _DetailRow(
                    icon: Icons
                        .schedule_outlined,
                    title: 'Orario',
                    value: _task.allDay
                        ? 'Tutto il giorno'
                        : _task.endAt == null
                            ? _formatTime(
                                _task.startAt!,
                              )
                            : '${_formatTime(_task.startAt!)}'
                                ' – '
                                '${_formatTime(_task.endAt!)}',
                  ),
                ],

                const Divider(height: 1),

                _DetailRow(
                  icon: Icons
                      .flag_outlined,
                  title: 'Priorità',
                  value:
                      _priorityLabel(
                    _task.priority,
                  ),
                  valueColor:
                      priorityColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Descrizione',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
          ),

          const SizedBox(height: 8),

          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              child: Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  _task.description.isEmpty
                      ? 'Nessuna descrizione.'
                      : _task.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color:
                            _task.description
                                    .isEmpty
                                ? colorScheme
                                    .onSurfaceVariant
                                : null,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        minimum:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: _deleteTask,
                icon: const Icon(
                  Icons.delete_outline,
                ),
                label: const Text(
                  'Elimina',
                  maxLines: 1,
                ),
                style:
                    OutlinedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(
                    52,
                  ),
                  foregroundColor:
                      colorScheme.error,
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              flex: 3,
              child: FilledButton.icon(
                onPressed: _editTask,
                icon: const Icon(
                  Icons.edit_outlined,
                ),
                label: const Text(
                  'Modifica',
                ),
                style:
                    FilledButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(
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

class _DetailRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.primary,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge,
            ),
          ),

          const SizedBox(width: 12),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: valueColor ??
                        colorScheme
                            .onSurfaceVariant,
                    fontWeight:
                        valueColor != null
                            ? FontWeight.w600
                            : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}