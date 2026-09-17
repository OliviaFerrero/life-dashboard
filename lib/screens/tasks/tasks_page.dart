import 'package:flutter/material.dart';

import '../../models/life_task.dart';
import 'task_form_page.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() =>
      _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final List<LifeTask> _tasks = [];

  Future<void> _addTask() async {
    final task =
        await Navigator.push<LifeTask>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const TaskFormPage(),
      ),
    );

    if (task == null) {
      return;
    }

    setState(() {
      _tasks.add(task);

      _tasks.sort((a, b) {
        if (a.startAt == null &&
            b.startAt == null) {
          return 0;
        }

        if (a.startAt == null) {
          return 1;
        }

        if (b.startAt == null) {
          return -1;
        }

        return a.startAt!
            .compareTo(b.startAt!);
      });
    });
  }

  String _twoDigits(int number) {
    return number.toString().padLeft(2, '0');
  }

  String _formatDate(DateTime date) {
    return '${_twoDigits(date.day)}/'
        '${_twoDigits(date.month)}/'
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${_twoDigits(date.hour)}:'
        '${_twoDigits(date.minute)}';
  }

  String _taskSubtitle(LifeTask task) {
    if (task.startAt == null) {
      return 'Senza data';
    }

    final date = _formatDate(
      task.startAt!,
    );

    if (task.allDay) {
      return '$date · Tutto il giorno';
    }

    final start =
        _formatTime(task.startAt!);

    if (task.endAt == null) {
      return '$date · $start';
    }

    final end =
        _formatTime(task.endAt!);

    return '$date · $start–$end';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attività'),
      ),

      body: _tasks.isEmpty
          ? Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(32),

                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Text(
                      'Nessuna attività',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight.w700,
                          ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      'Aggiungi qualcosa da fare '
                      'con il pulsante +.',
                      textAlign:
                          TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            color:
                                Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding:
                  const EdgeInsets.all(16),

              itemCount: _tasks.length,

              separatorBuilder:
                  (_, __) =>
                      const SizedBox(
                height: 8,
              ),

              itemBuilder:
                  (context, index) {
                final task =
                    _tasks[index];

                return Card(
                  margin: EdgeInsets.zero,

                  child: CheckboxListTile(
                    value:
                        task.isCompleted,

                    onChanged: (value) {
                      setState(() {
                        task.isCompleted =
                            value ?? false;
                      });
                    },

                    secondary: Container(
                      width: 10,
                      height: 10,

                      decoration:
                          BoxDecoration(
                        color:
                            _priorityColor(
                          context,
                          task.priority,
                        ),

                        shape:
                            BoxShape.circle,
                      ),
                    ),

                    title: Text(
                      task.title,

                      style: TextStyle(
                        decoration:
                            task.isCompleted
                                ? TextDecoration
                                    .lineThrough
                                : null,
                      ),
                    ),

                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          _taskSubtitle(
                            task,
                          ),
                        ),

                        if (task
                            .description
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            task.description,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                        ],
                      ],
                    ),

                    controlAffinity:
                        ListTileControlAffinity
                            .leading,
                  ),
                );
              },
            ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}