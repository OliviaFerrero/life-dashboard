import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/core/time/app_clock.dart';
import 'package:life_hub/models/life_task.dart';
import 'package:life_hub/models/task_occurrence.dart';
import 'package:life_hub/models/task_subtask.dart';
import 'package:life_hub/widgets/task_timeline.dart';

void main() {
  final day = DateTime(2026, 10, 31);
  final windowStart = DateTime(2026, 10, 31, 6);
  final windowEnd = DateTime(2026, 11, 1, 3);

  const subtasks = <TaskSubtask>[
    TaskSubtask(id: 'a', title: 'Passo A', sortOrder: 0),
    TaskSubtask(id: 'b', title: 'Passo B', sortOrder: 1),
    TaskSubtask(id: 'c', title: 'Passo C', sortOrder: 2),
    TaskSubtask(id: 'd', title: 'Passo D', sortOrder: 3),
    TaskSubtask(id: 'e', title: 'Passo E', sortOrder: 4),
  ];

  TaskOccurrence makeOccurrence({
    int durationMinutes = 180,
    List<TaskSubtask> steps = subtasks,
    bool completed = false,
  }) {
    final task = LifeTask(
      id: 'gioco',
      title: 'Gioco',
      scheduledDate: day,
      startTimeMinutes: 10 * 60 + 30,
      durationMinutes: durationMinutes,
      subtasks: steps,
      isCompleted: completed,
    );
    return TaskOccurrence(
      task: task,
      date: day,
      isCompleted: completed,
      subtasks: steps,
    );
  }

  Future<void> mountTimeline(
    WidgetTester tester, {
    required TaskOccurrence occurrence,
    required AppClock clock,
    required Future<void> Function(TaskOccurrence, TaskSubtask, bool)
    onSubtaskChanged,
    required Future<void> Function(TaskOccurrence, bool) onCompletedChanged,
    required void Function(TaskOccurrence) onTaskTap,
    required void Function(TaskOccurrence) onTaskLongPress,
  }) async {
    await tester.pumpWidget(
      AppClockScope(
        clock: clock,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TaskTimeline(
                  occurrences: [occurrence],
                  windowStart: windowStart,
                  windowEnd: windowEnd,
                  secondaryLabelBuilder: (_, _, _) => '3 ore',
                  subtaskProgressBuilder: (task) =>
                      '${task.completedSubtaskCount}/${task.subtaskCount}',
                  accentColorBuilder: (_) => Colors.teal,
                  priorityColorBuilder: (_) => Colors.amber,
                  categoryIconBuilder: (_) => Icons.sports_esports_outlined,
                  onCompletedChanged: onCompletedChanged,
                  onSubtaskCompletedChanged: onSubtaskChanged,
                  onTaskTap: onTaskTap,
                  onTaskLongPress: onTaskLongPress,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('subtask row and checkbox do not open detail or toggle parent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final clock = AppClock(
      nowProvider: () => DateTime(2026, 10, 31, 5),
      autoStart: false,
    );
    addTearDown(clock.dispose);

    final occurrence = makeOccurrence();
    final calls = <String>[];
    var detailOpens = 0;
    var quickActions = 0;
    var parentToggles = 0;

    Future<void> onStep(
      TaskOccurrence target,
      TaskSubtask step,
      bool completed,
    ) async {
      expect(target.occurrenceKey, occurrence.occurrenceKey);
      calls.add('${step.id}:$completed');
    }

    Future<void> onParent(TaskOccurrence target, bool completed) async {
      parentToggles++;
    }

    await mountTimeline(
      tester,
      occurrence: occurrence,
      clock: clock,
      onSubtaskChanged: onStep,
      onCompletedChanged: onParent,
      onTaskTap: (_) => detailOpens++,
      onTaskLongPress: (_) => quickActions++,
    );

    // A 3-hour event has room for 3 steps; the others stay behind "+N".
    expect(find.text('Passo A'), findsOneWidget);
    expect(find.text('Passo B'), findsOneWidget);
    expect(find.text('Passo C'), findsOneWidget);
    expect(find.text('Passo D'), findsNothing);
    expect(find.text('+2 altre'), findsOneWidget);

    await tester.tap(find.text('Passo A'));
    await tester.pump();
    expect(calls, ['a:true']);
    expect(detailOpens, 0);
    expect(parentToggles, 0);

    // Also verify the checkbox itself is an independent hit target.
    final secondStep = find
        .ancestor(of: find.text('Passo B'), matching: find.byType(InkWell))
        .first;
    final checkbox = find.descendant(
      of: secondStep,
      matching: find.byIcon(Icons.check_box_outline_blank_rounded),
    );
    expect(checkbox, findsOneWidget);
    await tester.tap(checkbox);
    await tester.pump();
    expect(calls, ['a:true', 'b:true']);
    expect(detailOpens, 0);
    expect(parentToggles, 0);

    // Rebuilding from an updated repository snapshot must let us undo a tick.
    final changedOccurrence = makeOccurrence(
      steps: [subtasks.first.copyWith(isCompleted: true), ...subtasks.skip(1)],
    );
    await mountTimeline(
      tester,
      occurrence: changedOccurrence,
      clock: clock,
      onSubtaskChanged: onStep,
      onCompletedChanged: onParent,
      onTaskTap: (_) => detailOpens++,
      onTaskLongPress: (_) => quickActions++,
    );
    expect(find.byIcon(Icons.check_box_rounded), findsOneWidget);
    await tester.tap(find.text('Passo A'));
    await tester.pump();
    expect(calls, ['a:true', 'b:true', 'a:false']);
    expect(parentToggles, 0);

    await tester.tap(find.text('Gioco'));
    await tester.pump();
    expect(detailOpens, 1);
    expect(calls, hasLength(3));

    await tester.longPress(find.text('Gioco'));
    await tester.pump();
    expect(quickActions, 1);
    expect(detailOpens, 1);
    expect(parentToggles, 0);
  });

  testWidgets(
    'short timed task hides inline steps but keeps header interactive',
    (tester) async {
      tester.view.physicalSize = const Size(500, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final clock = AppClock(
        nowProvider: () => DateTime(2026, 10, 31, 5),
        autoStart: false,
      );
      addTearDown(clock.dispose);
      var opened = 0;
      var stepToggles = 0;
      final occurrence = makeOccurrence(durationMinutes: 30);

      await mountTimeline(
        tester,
        occurrence: occurrence,
        clock: clock,
        onSubtaskChanged: (_, _, _) async {
          stepToggles++;
        },
        onCompletedChanged: (_, _) async {},
        onTaskTap: (_) => opened++,
        onTaskLongPress: (_) {},
      );

      expect(find.text('Gioco'), findsOneWidget);
      expect(find.text('Passo A'), findsNothing);
      await tester.tap(find.text('Gioco'));
      await tester.pump();
      expect(opened, 1);
      expect(stepToggles, 0);
    },
  );

  testWidgets('capsule completion stays separate from card and subtask taps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final clock = AppClock(
      nowProvider: () => DateTime(2026, 10, 31, 5),
      autoStart: false,
    );
    addTearDown(clock.dispose);
    final occurrence = makeOccurrence();
    final toggles = <bool>[];
    var detailOpens = 0;
    var subtaskToggles = 0;

    await mountTimeline(
      tester,
      occurrence: occurrence,
      clock: clock,
      onSubtaskChanged: (_, _, _) async {
        subtaskToggles++;
      },
      onCompletedChanged: (_, done) async {
        toggles.add(done);
      },
      onTaskTap: (_) => detailOpens++,
      onTaskLongPress: (_) {},
    );

    await tester.tap(find.byKey(ValueKey(occurrence.occurrenceKey)).first);
    await tester.pump();
    expect(toggles, [true]);
    expect(detailOpens, 0);
    expect(subtaskToggles, 0);
  });

  testWidgets(
    'long free gap is labeled while the timeline remains scrollable',
    (tester) async {
      tester.view.physicalSize = const Size(500, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final clock = AppClock(
        nowProvider: () => DateTime(2026, 10, 31, 5),
        autoStart: false,
      );
      addTearDown(clock.dispose);

      await mountTimeline(
        tester,
        occurrence: makeOccurrence(),
        clock: clock,
        onSubtaskChanged: (_, _, _) async {},
        onCompletedChanged: (_, _) async {},
        onTaskTap: (_) {},
        onTaskLongPress: (_) {},
      );

      // 06:00 -> 10:30, without 270 minutes of empty pixel-for-pixel space.
      expect(find.text('4 h 30 min liberi'), findsOneWidget);
      expect(find.text('Inizio giornata'), findsOneWidget);
      expect(find.text('Fine giornata'), findsOneWidget);
      expect(find.byType(Scrollable), findsOneWidget);
    },
  );
}
