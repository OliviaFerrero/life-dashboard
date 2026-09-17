import 'package:flutter/material.dart';

import '../../models/life_task.dart';
import '../../repositories/task_repository.dart';

class CalendarPage extends StatefulWidget {
  final TaskRepository taskRepository;

  const CalendarPage({
    super.key,
    required this.taskRepository,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedDay = DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _formatTime(DateTime date) {
    return '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  String _selectedDateLabel(DateTime date) {
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
        '${months[date.month - 1]}';
  }

  String _taskTimeLabel(LifeTask task) {
    if (task.startAt == null) {
      return '';
    }

    if (task.allDay) {
      return 'Tutto il giorno';
    }

    final start = _formatTime(task.startAt!);

    if (task.endAt == null) {
      return start;
    }

    return '$start – ${_formatTime(task.endAt!)}';
  }

  Color _priorityColor(
    BuildContext context,
    TaskPriority priority,
  ) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;

      case TaskPriority.normal:
        return Theme.of(context).colorScheme.primary;

      case TaskPriority.high:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          32,
        ),
        children: [
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: CalendarDatePicker(
              initialDate: _selectedDay,
              firstDate: DateTime(
                now.year - 5,
                1,
                1,
              ),
              lastDate: DateTime(
                now.year + 10,
                12,
                31,
              ),
              onDateChanged: (date) {
                setState(() {
                  _selectedDay = DateTime(
                    date.year,
                    date.month,
                    date.day,
                  );
                });
              },
            ),
          ),

          const SizedBox(height: 24),

          Text(
            _selectedDateLabel(_selectedDay),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),

          const SizedBox(height: 12),

          StreamBuilder<List<LifeTask>>(
            stream: widget.taskRepository
                .watchTasksForDay(
              _selectedDay,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Errore nel caricamento:\n'
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final tasks = snapshot.data!;

              if (tasks.isEmpty) {
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Nessuna attività programmata '
                            'per questo giorno.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  for (int i = 0;
                      i < tasks.length;
                      i++) ...[
                    _CalendarTaskCard(
                      task: tasks[i],
                      priorityColor:
                          _priorityColor(
                        context,
                        tasks[i].priority,
                      ),
                      timeLabel:
                          _taskTimeLabel(
                        tasks[i],
                      ),
                      onCompletedChanged:
                          (completed) async {
                        await widget.taskRepository
                            .setCompleted(
                          tasks[i].id,
                          completed,
                        );
                      },
                    ),

                    if (i != tasks.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CalendarTaskCard extends StatelessWidget {
  final LifeTask task;
  final Color priorityColor;
  final String timeLabel;
  final ValueChanged<bool> onCompletedChanged;

  const _CalendarTaskCard({
    required this.task,
    required this.priorityColor,
    required this.timeLabel,
    required this.onCompletedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        child: Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                onCompletedChanged(
                  value ?? false,
                );
              },
            ),

            Container(
              width: 8,
              height: 36,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),

                  if (timeLabel.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      timeLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],

                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}