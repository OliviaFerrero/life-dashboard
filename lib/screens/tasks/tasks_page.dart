import 'package:flutter/material.dart';

import '../../models/life_task.dart';
import '../../repositories/task_repository.dart';
import 'task_form_page.dart';

class TasksPage
    extends StatelessWidget {
  final TaskRepository taskRepository;

  const TasksPage({
    super.key,
    required this.taskRepository,
  });

  Future<void> _addTask(
    BuildContext context,
  ) async {
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

    await taskRepository.addTask(task);
  }

  String _twoDigits(int number) {
    return number
        .toString()
        .padLeft(2, '0');
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

  String _taskSubtitle(
    LifeTask task,
  ) {
    if (task.startAt == null) {
      return 'Senza data';
    }

    final date =
        _formatDate(task.startAt!);

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
        title:
            const Text('Attività'),
      ),

      body: StreamBuilder<
          List<LifeTask>>(
        stream:
            taskRepository.watchAllTasks(),

        builder:
            (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Errore nel caricamento delle attività:\n'
                '${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final tasks = snapshot.data!;

          if (tasks.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  32,
                ),

                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 64,
                      color:
                          Theme.of(context)
                              .colorScheme
                              .primary,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Text(
                      'Nessuna attività',
                      style:
                          Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      'Aggiungi qualcosa da fare con il pulsante +.',
                      textAlign:
                          TextAlign.center,
                      style:
                          Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                )
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding:
                const EdgeInsets.all(
              16,
            ),

            itemCount: tasks.length,

            separatorBuilder:
                (_, _) =>
                    const SizedBox(
              height: 8,
            ),

            itemBuilder:
                (context, index) {
              final task =
                  tasks[index];

              return Card(
                margin:
                    EdgeInsets.zero,

                child:
                    CheckboxListTile(
                  value:
                      task.isCompleted,

                  onChanged:
                      (value) async {
                    await taskRepository
                        .setCompleted(
                      task.id,
                      value ?? false,
                    );
                  },

                  secondary:
                      Container(
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
          );
        },
      ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: () =>
            _addTask(context),

        child:
            const Icon(Icons.add),
      ),
    );
  }
}