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

  String _formatClockMinutes(int minutes) {
    final normalized = minutes % (24 * 60);

    return '${_twoDigits(normalized ~/ 60)}:'
        '${_twoDigits(normalized % 60)}';
  }

  String _formatEndTime(LifeTask task) {
    final start = task.startTimeMinutes;
    final duration = task.durationMinutes;

    if (start == null || duration == null) {
      return '';
    }

    final total = start + duration;
    final extraDays = total ~/ (24 * 60);

    final suffix = extraDays == 0
        ? ''
        : extraDays == 1
            ? ' (+1 giorno)'
            : ' (+$extraDays giorni)';

    return '${_formatClockMinutes(total)}$suffix';
  }

  String _durationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

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

  String _priorityLabel(TaskPriority priority) {
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
        return const Color(0xFF5F8F73);
      case TaskPriority.normal:
        return Theme.of(context)
            .colorScheme
            .primary;
      case TaskPriority.high:
        return const Color(0xFFC65B61);
    }
  }

  bool _isPastUnfinished(LifeTask task) {
    if (task.isCompleted ||
        task.scheduledDate == null) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final date = DateTime(
      task.scheduledDate!.year,
      task.scheduledDate!.month,
      task.scheduledDate!.day,
    );

    if (date.isBefore(today)) {
      return true;
    }

    if (date.isAfter(today)) {
      return false;
    }

    if (task.allDay ||
        task.startTimeMinutes == null) {
      return false;
    }

    final cutoffMinutes =
        task.startTimeMinutes! +
        (task.durationMinutes ?? 0);

    final cutoff = date.add(
      Duration(minutes: cutoffMinutes),
    );

    return now.isAfter(cutoff);
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

  Future<void> _rescheduleTask() async {
    final result =
        await Navigator.push<TaskFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormPage(
          initialTask: _task,
          rescheduleOnly: true,
        ),
      ),
    );

    final updatedTask = result?.task;

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
    final confirmed = await showDialog<bool>(
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
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('Elimina'),
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

    final priorityColor = _priorityColor(
      context,
      _task.priority,
    );

    final isPast = _isPastUnfinished(_task);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attività'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
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
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                  decoration: _task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
          ),
          const SizedBox(height: 18),
          InkWell(
            borderRadius:
                BorderRadius.circular(12),
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
                    decoration: BoxDecoration(
                      color: _task.isCompleted
                          ? colorScheme.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _task.isCompleted
                            ? colorScheme.primary
                            : colorScheme
                                .onSurfaceVariant,
                        width: 2,
                      ),
                    ),
                    child: _task.isCompleted
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color:
                                colorScheme.onPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _task.isCompleted
                        ? 'Completata'
                        : 'Completa',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.w600,
                          color: _task.isCompleted
                              ? colorScheme.primary
                              : null,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (isPast) ...[
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: _rescheduleTask,
              icon: const Icon(
                Icons.event_repeat_outlined,
              ),
              label: const Text('Sposta a…'),
              style: FilledButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(48),
              ),
            ),
          ],
          const SizedBox(height: 30),
          Text(
            'Quando',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 18),
          if (_task.scheduledDate == null)
            const _SimpleInfoRow(
              icon: Icons.inbox_outlined,
              text: 'Nessuna data · Inbox',
            )
          else
            Text(
              _dateLabel(_task.scheduledDate!),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          if (_task.allDay) ...[
            const SizedBox(height: 16),
            const _SimpleInfoRow(
              icon: Icons.today_outlined,
              text: 'Tutto il giorno',
            ),
          ] else if (_task.startTimeMinutes !=
              null) ...[
            const SizedBox(height: 16),
            Text(
              _task.scheduledDate == null
                  ? 'Orario preferito'
                  : 'Orario',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: colorScheme
                        .onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (_task.durationMinutes != null)
              _TimeRange(
                start: _formatClockMinutes(
                  _task.startTimeMinutes!,
                ),
                end: _formatEndTime(_task),
              )
            else
              _SimpleInfoRow(
                icon: Icons.schedule_outlined,
                text: 'Inizio alle '
                    '${_formatClockMinutes(_task.startTimeMinutes!)}',
              ),
          ] else if (_task.scheduledDate !=
              null) ...[
            const SizedBox(height: 16),
            const _SimpleInfoRow(
              icon: Icons.schedule_outlined,
              text: 'Nessun orario',
            ),
          ],
          if (_task.durationMinutes != null) ...[
            const SizedBox(height: 16),
            _SimpleInfoRow(
              icon: Icons.timer_outlined,
              text: 'Durata stimata: '
                  '${_durationLabel(_task.durationMinutes!)}',
            ),
          ],
          const SizedBox(height: 34),
          Divider(
            color: colorScheme.outlineVariant
                .withValues(alpha: 0.6),
          ),
          const SizedBox(height: 24),
          Text(
            'Priorità',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                size: 20,
                color: priorityColor,
              ),
              const SizedBox(width: 10),
              Text(
                _priorityLabel(_task.priority),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      color: priorityColor,
                      fontWeight:
                          FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Divider(
            color: colorScheme.outlineVariant
                .withValues(alpha: 0.6),
          ),
          const SizedBox(height: 24),
          Text(
            'Descrizione',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _task.description.trim().isEmpty
                ? 'Nessuna descrizione.'
                : _task.description,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
                  height: 1.5,
                  color: _task.description
                          .trim()
                          .isEmpty
                      ? colorScheme
                          .onSurfaceVariant
                      : null,
                ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          16,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: _deleteTask,
                icon: const Icon(
                  Icons.delete_outline,
                ),
                label: const Text('Elimina'),
                style: OutlinedButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(52),
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
                label: const Text('Modifica'),
                style: FilledButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SimpleInfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _TimeRange extends StatelessWidget {
  final String start;
  final String end;

  const _TimeRange({
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          start,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant,
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            end,
            textAlign: TextAlign.right,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}
