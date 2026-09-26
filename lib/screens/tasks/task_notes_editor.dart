import 'package:flutter/material.dart';

class TaskNotesEditor extends StatelessWidget {
  final TextEditingController controller;

  const TaskNotesEditor({
    super.key,
    required this.controller,
  });

  Future<void> _openExpandedEditor(
    BuildContext context,
  ) async {
    FocusScope.of(context).unfocus();

    final result =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return _ExpandedNotesEditor(
          initialText:
              controller.text,
        );
      },
    );

    if (result == null) {
      return;
    }

    controller.value =
        TextEditingValue(
      text: result,
      selection:
          TextSelection.collapsed(
        offset:
            result.length,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      decoration:
          BoxDecoration(
        border: Border(
          left: BorderSide(
            color: colorScheme.primary
                .withValues(
              alpha:
                  0.52,
            ),
            width:
                2,
          ),
        ),
      ),
      padding:
          const EdgeInsets.only(
        left:
            14,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notes_outlined,
                size:
                    18,
                color: colorScheme
                    .onSurfaceVariant,
              ),
              const SizedBox(
                width:
                    8,
              ),
              Expanded(
                child: Text(
                  'Dettagli, promemoria e link',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: colorScheme
                            .onSurfaceVariant,
                        fontWeight:
                            FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                tooltip:
                    'Espandi note',
                visualDensity:
                    VisualDensity.compact,
                onPressed: () {
                  _openExpandedEditor(
                    context,
                  );
                },
                icon:
                    const Icon(
                  Icons.open_in_full,
                  size:
                      18,
                ),
              ),
            ],
          ),
          TextField(
            key:
                const Key(
              'task_notes_inline_field',
            ),
            controller:
                controller,
            minLines:
                4,
            maxLines:
                10,
            keyboardType:
                TextInputType.multiline,
            textCapitalization:
                TextCapitalization.sentences,
            textInputAction:
                TextInputAction.newline,
            onTapOutside:
                (_) {
              FocusScope.of(context)
                  .unfocus();
            },
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
                  height:
                      1.45,
                ),
            decoration:
                InputDecoration(
              hintText:
                  'Scrivi qui quello che vuoi ricordare…',
              hintStyle:
                  TextStyle(
                color: colorScheme
                    .onSurfaceVariant
                    .withValues(
                  alpha:
                      0.72,
                ),
              ),
              border:
                  InputBorder.none,
              enabledBorder:
                  InputBorder.none,
              focusedBorder:
                  InputBorder.none,
              contentPadding:
                  const EdgeInsets.only(
                top:
                    6,
                bottom:
                    10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedNotesEditor
    extends StatefulWidget {
  final String initialText;

  const _ExpandedNotesEditor({
    required this.initialText,
  });

  @override
  State<_ExpandedNotesEditor>
      createState() =>
          _ExpandedNotesEditorState();
}

class _ExpandedNotesEditorState
    extends State<_ExpandedNotesEditor> {
  late final TextEditingController
      _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController(
      text:
          widget.initialText,
    );

    _controller.selection =
        TextSelection.collapsed(
      offset:
          _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Dialog.fullscreen(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                8,
                6,
                8,
                6,
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pop();
                    },
                    child:
                        const Text(
                      'Annulla',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'NOTE',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(
                          color: colorScheme
                              .onSurfaceVariant,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing:
                              1,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pop(
                        _controller.text,
                      );
                    },
                    child:
                        const Text(
                      'Fine',
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height:
                  1,
              color: colorScheme
                  .outlineVariant
                  .withValues(
                alpha:
                    0.5,
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  24,
                  22,
                  24,
                  16,
                ),
                child: TextField(
                  key:
                      const Key(
                    'task_notes_expanded_field',
                  ),
                  controller:
                      _controller,
                  expands:
                      true,
                  minLines:
                      null,
                  maxLines:
                      null,
                  autofocus:
                      true,
                  keyboardType:
                      TextInputType.multiline,
                  textCapitalization:
                      TextCapitalization.sentences,
                  textInputAction:
                      TextInputAction.newline,
                  textAlignVertical:
                      TextAlignVertical.top,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        height:
                            1.55,
                      ),
                  decoration:
                      InputDecoration(
                    hintText:
                        'Scrivi liberamente…',
                    hintStyle:
                        TextStyle(
                      color: colorScheme
                          .onSurfaceVariant
                          .withValues(
                        alpha:
                            0.68,
                      ),
                    ),
                    border:
                        InputBorder.none,
                    enabledBorder:
                        InputBorder.none,
                    focusedBorder:
                        InputBorder.none,
                    contentPadding:
                        EdgeInsets.zero,
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
