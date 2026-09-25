enum TaskEditorMode {
  create,
  edit,
  editOccurrence,
  duplicate,
  reschedule;

  bool get createsNewTask =>
      this == TaskEditorMode.create ||
      this == TaskEditorMode.duplicate;

  bool get requiresInitialTask =>
      this != TaskEditorMode.create;

  bool get editsExistingTask =>
      this == TaskEditorMode.edit ||
      this == TaskEditorMode.editOccurrence ||
      this == TaskEditorMode.reschedule;
}
