import 'package:flutter_test/flutter_test.dart';
import 'package:life_hub/screens/tasks/task_editor_mode.dart';

void main() {
  test(
    'create and duplicate are the only modes that create a new task',
    () {
      expect(
        TaskEditorMode.create.createsNewTask,
        isTrue,
      );
      expect(
        TaskEditorMode.duplicate.createsNewTask,
        isTrue,
      );
      expect(
        TaskEditorMode.edit.createsNewTask,
        isFalse,
      );
      expect(
        TaskEditorMode.editOccurrence.createsNewTask,
        isFalse,
      );
      expect(
        TaskEditorMode.reschedule.createsNewTask,
        isFalse,
      );
    },
  );

  test(
    'only create can start without an existing task',
    () {
      expect(
        TaskEditorMode.create.requiresInitialTask,
        isFalse,
      );

      for (final mode in [
        TaskEditorMode.edit,
        TaskEditorMode.editOccurrence,
        TaskEditorMode.duplicate,
        TaskEditorMode.reschedule,
      ]) {
        expect(
          mode.requiresInitialTask,
          isTrue,
        );
      }
    },
  );

  test(
    'editing modes are distinct from create and duplicate',
    () {
      expect(
        TaskEditorMode.edit.editsExistingTask,
        isTrue,
      );
      expect(
        TaskEditorMode.editOccurrence.editsExistingTask,
        isTrue,
      );
      expect(
        TaskEditorMode.reschedule.editsExistingTask,
        isTrue,
      );
      expect(
        TaskEditorMode.create.editsExistingTask,
        isFalse,
      );
      expect(
        TaskEditorMode.duplicate.editsExistingTask,
        isFalse,
      );
    },
  );
}
