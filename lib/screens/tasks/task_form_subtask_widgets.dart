import 'package:flutter/material.dart';

import '../../models/task_subtask.dart';

class TaskSubtaskEditor extends StatefulWidget {
  final List<TaskSubtask> subtasks;
  final ValueChanged<String> onAdd;
  final void Function(
    String subtaskId,
    String title,
  ) onRename;
  final ValueChanged<String> onDelete;
  final void Function(
    int oldIndex,
    int newIndex,
  ) onReorder;

  const TaskSubtaskEditor({
    super.key,
    required this.subtasks,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
    required this.onReorder,
  });

  @override
  State<TaskSubtaskEditor> createState() =>
      _TaskSubtaskEditorState();
}

class _TaskSubtaskEditorState
    extends State<TaskSubtaskEditor> {
  final TextEditingController
      _newSubtaskController =
      TextEditingController();

  final FocusNode _newSubtaskFocusNode =
      FocusNode();

  TextEditingController?
      _editController;

  FocusNode? _editFocusNode;

  String? _editingSubtaskId;

  bool get _canAdd =>
      _newSubtaskController.text
          .trim()
          .isNotEmpty;

  @override
  void initState() {
    super.initState();

    _newSubtaskController.addListener(
      _onNewSubtaskChanged,
    );
  }

  @override
  void didUpdateWidget(
    TaskSubtaskEditor oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    final editingId =
        _editingSubtaskId;

    if (editingId == null) {
      return;
    }

    final stillExists =
        widget.subtasks.any(
      (subtask) =>
          subtask.id == editingId,
    );

    if (!stillExists) {
      _stopEditing(
        notify: false,
      );
    }
  }

  @override
  void dispose() {
    _newSubtaskController
        .removeListener(
      _onNewSubtaskChanged,
    );

    _newSubtaskController.dispose();
    _newSubtaskFocusNode.dispose();

    _disposeEditResources();

    super.dispose();
  }

  void _onNewSubtaskChanged() {
    setState(() {});
  }

  void _submitNewSubtask() {
    final title =
        _newSubtaskController.text
            .trim();

    if (title.isEmpty) {
      return;
    }

    widget.onAdd(
      title,
    );

    _newSubtaskController.clear();

    _newSubtaskFocusNode
        .requestFocus();
  }

  void _startEditing(
    TaskSubtask subtask,
  ) {
    _disposeEditResources();

    final controller =
        TextEditingController(
      text: subtask.title,
    );

    controller.selection =
        TextSelection.collapsed(
      offset:
          controller.text.length,
    );

    final focusNode =
        FocusNode();

    setState(() {
      _editingSubtaskId =
          subtask.id;
      _editController =
          controller;
      _editFocusNode =
          focusNode;
    });

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!mounted ||
            _editingSubtaskId !=
                subtask.id) {
          return;
        }

        focusNode.requestFocus();
      },
    );
  }

  void _saveEditing() {
    final id =
        _editingSubtaskId;

    final controller =
        _editController;

    if (id == null ||
        controller == null) {
      return;
    }

    final title =
        controller.text.trim();

    if (title.isEmpty) {
      return;
    }

    widget.onRename(
      id,
      title,
    );

    _stopEditing();
  }

  void _cancelEditing() {
    _stopEditing();
  }

  void _stopEditing({
    bool notify = true,
  }) {
    _disposeEditResources();

    if (notify && mounted) {
      setState(() {
        _editingSubtaskId =
            null;
      });
    } else {
      _editingSubtaskId =
          null;
    }
  }

  void _disposeEditResources() {
    _editController?.dispose();
    _editFocusNode?.dispose();

    _editController = null;
    _editFocusNode = null;
  }

  void _deleteSubtask(
    TaskSubtask subtask,
  ) {
    if (_editingSubtaskId ==
        subtask.id) {
      _stopEditing();
    }

    widget.onDelete(
      subtask.id,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        if (widget.subtasks.isEmpty)
          Padding(
            padding:
                const EdgeInsets.only(
              top: 2,
              bottom: 10,
            ),
            child: Text(
              'Aggiungi piccoli passi per rendere '
              'l’attività più semplice da seguire.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color:
                        colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles:
                false,
            itemCount:
                widget.subtasks.length,
            onReorderItem:
                widget.onReorder,
            itemBuilder:
                (context, index) {
              final subtask =
                  widget.subtasks[index];

              final editing =
                  _editingSubtaskId ==
                      subtask.id;

              return TaskSubtaskFormRow(
                key: ValueKey(
                  subtask.id,
                ),
                subtask:
                    subtask,
                index:
                    index,
                editing:
                    editing,
                editController:
                    editing
                        ? _editController
                        : null,
                editFocusNode:
                    editing
                        ? _editFocusNode
                        : null,
                onEdit: () {
                  _startEditing(
                    subtask,
                  );
                },
                onSaveEdit:
                    _saveEditing,
                onCancelEdit:
                    _cancelEditing,
                onDelete: () {
                  _deleteSubtask(
                    subtask,
                  );
                },
              );
            },
          ),
        if (widget.subtasks.isNotEmpty)
          const SizedBox(
            height: 6,
          ),
        _InlineAddSubtaskRow(
          controller:
              _newSubtaskController,
          focusNode:
              _newSubtaskFocusNode,
          canSubmit:
              _canAdd,
          onSubmit:
              _submitNewSubtask,
        ),
      ],
    );
  }
}

class TaskSubtaskFormRow
    extends StatelessWidget {
  final TaskSubtask subtask;
  final int index;
  final bool editing;
  final TextEditingController?
      editController;
  final FocusNode?
      editFocusNode;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;
  final VoidCallback? onSaveEdit;
  final VoidCallback? onCancelEdit;
  final VoidCallback onDelete;

  const TaskSubtaskFormRow({
    super.key,
    required this.subtask,
    required this.index,
    this.editing = false,
    this.editController,
    this.editFocusNode,
    this.onEdit,
    this.onTap,
    this.onSaveEdit,
    this.onCancelEdit,
    required this.onDelete,
  }) : assert(
         !editing ||
             (editController != null &&
                 onSaveEdit != null &&
                 onCancelEdit != null),
       );

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Material(
      color:
          Colors.transparent,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 3,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            ReorderableDragStartListener(
              index:
                  index,
              child: Padding(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  2,
                  10,
                  10,
                  10,
                ),
                child: Icon(
                  Icons.drag_indicator,
                  size: 20,
                  color: colorScheme
                      .onSurfaceVariant
                      .withValues(
                    alpha: 0.72,
                  ),
                ),
              ),
            ),
            Expanded(
              child: editing
                  ? TextField(
                      controller:
                          editController,
                      focusNode:
                          editFocusNode,
                      textCapitalization:
                          TextCapitalization
                              .sentences,
                      textInputAction:
                          TextInputAction.done,
                      onSubmitted:
                          (_) {
                        onSaveEdit?.call();
                      },
                      decoration:
                          InputDecoration(
                        isDense: true,
                        hintText:
                            'Titolo sottoattività',
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 0,
                          vertical: 10,
                        ),
                        border:
                            const UnderlineInputBorder(),
                      ),
                    )
                  : InkWell(
                      onTap:
                          onEdit ?? onTap,
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 10,
                        ),
                        child: Text(
                          subtask.title,
                          style:
                              Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight:
                                        FontWeight
                                            .w500,
                                  ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(
              width: 4,
            ),
            if (editing) ...[
              IconButton(
                tooltip:
                    'Annulla modifica',
                visualDensity:
                    VisualDensity.compact,
                onPressed:
                    onCancelEdit,
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color:
                      colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                tooltip:
                    'Salva sottoattività',
                visualDensity:
                    VisualDensity.compact,
                onPressed:
                    onSaveEdit,
                icon: Icon(
                  Icons.check,
                  size: 19,
                  color:
                      colorScheme.primary,
                ),
              ),
            ] else ...[
              IconButton(
                tooltip:
                    'Modifica sottoattività',
                visualDensity:
                    VisualDensity.compact,
                onPressed:
                    onEdit,
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: colorScheme
                      .onSurfaceVariant
                      .withValues(
                    alpha: 0.78,
                  ),
                ),
              ),
              IconButton(
                tooltip:
                    'Rimuovi sottoattività',
                visualDensity:
                    VisualDensity.compact,
                onPressed:
                    onDelete,
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color:
                      colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineAddSubtaskRow
    extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSubmit;
  final VoidCallback onSubmit;

  const _InlineAddSubtaskRow({
    required this.controller,
    required this.focusNode,
    required this.canSubmit,
    required this.onSubmit,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      children: [
        Padding(
          padding:
              const EdgeInsets.only(
            left: 2,
            right: 10,
          ),
          child: Icon(
            Icons.add,
            size: 20,
            color:
                colorScheme.primary,
          ),
        ),
        Expanded(
          child: TextField(
            controller:
                controller,
            focusNode:
                focusNode,
            textCapitalization:
                TextCapitalization
                    .sentences,
            textInputAction:
                TextInputAction.done,
            onSubmitted:
                (_) {
              onSubmit();
            },
            decoration:
                const InputDecoration(
              hintText:
                  'Aggiungi un passo…',
              isDense: true,
              border:
                  UnderlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(
                vertical: 10,
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        IconButton(
          tooltip:
              'Aggiungi sottoattività',
          visualDensity:
              VisualDensity.compact,
          onPressed:
              canSubmit
                  ? onSubmit
                  : null,
          icon:
              const Icon(
            Icons.arrow_upward,
            size: 19,
          ),
        ),
      ],
    );
  }
}
